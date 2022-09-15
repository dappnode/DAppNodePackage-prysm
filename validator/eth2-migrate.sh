#!/bin/bash

# Exit on error
set -eo pipefail

#############
# VARIABLES #
#############

ERROR="[ ERROR-migration ]"
WARN="[ WARN-migration ]"
INFO="[ INFO-migration ]"

WALLETPASSWORD_FILE="${WALLET_DIR}/walletpassword.txt"
MANUAL_MIGRATION_BACKUP_FILE="/root/manual_migration/backup.zip"
BACKUP_DIR="${WALLET_DIR}/backup"
BACKUP_ZIP_FILE="${BACKUP_DIR}/backup.zip"
BACKUP_KEYSTORES_DIR="${BACKUP_DIR}/keystores" # Directory where the keystores are stored in format: keystore_0.json keystore_1.json ...
BACKUP_SLASHING_FILE="${BACKUP_DIR}/slashing_protection.json"
BACKUP_SLASHING_FILE_PRUNE="${BACKUP_DIR}/slashing_protection_prune.json"
BACKUP_WALLETPASSWORD_FILE="${BACKUP_DIR}/walletpassword.txt"
REQUEST_BODY_FILE="${BACKUP_DIR}/request_body"

#############
# FUNCTIONS #
#############

# Ensure files needed for migration exists
function ensure_files_exist() {
  # Check if wallet directory exists
  if [ ! -d "${WALLET_DIR}" ]; then
    {
      echo "${ERROR} wallet directory not found, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
      empty_validator_volume
      exit 1
    }
  fi

  # Check if wallet password file exists
  if [ ! -f "${WALLETPASSWORD_FILE}" ]; then
    {
      echo "${ERROR} wallet password file not found, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
      empty_validator_volume
      exit 1
    }
  fi
}

# Ensure requirements
function ensure_requirements() {
  # Try for 3 minutes
  # Check if beacon is available
  if [ "$(curl -s -X GET \
    -H "Content-Type: application/json" \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    --retry 30 \
    --retry-delay 3 \
    --retry-all-errors \
    http://beacon-chain.prysm.dappnode:3500/eth/v1/beacon/genesis)" == 200 ]; then
    echo "${INFO} web3signer available"
  else
    {
      echo "${ERROR} beacon-chain not available after 3 minutes, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
      empty_validator_volume
      exit 1
    }
  fi

  # Try for 3 minutes
  # Check if web3signer is available: https://consensys.github.io/web3signer/web3signer-eth2.html#tag/Server-Status
  if [ "$(curl -s -X GET \
    -H "Content-Type: application/json" \
    -H "Host: prysm.migration.dappnode" \
    --write-out '%{http_code}' \
    --silent \
    --output /dev/null \
    --retry 30 \
    --retry-delay 3 \
    --retry-all-errors \
    "${WEB3SIGNER_API}/upcheck")" == 200 ]; then
    echo "${INFO} web3signer available"
  else
    {
      echo "${ERROR} web3signer not available after 3 minutes, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
      empty_validator_volume
      exit 1
    }
  fi
}

# Get VALIDATORS_PUBKEYS as array of strings and as string comma separated
function get_public_keys() {
  # Output from validator accounts list
  # ```
  # Account 0 | conversely-game-leech
  # [validating public key] 0xb28d911308c25b9168878abb672c1338e2720ad68fee29bbc27a7c2be4c4efda2696666795e1f8c83ee891e39433b7e5

  # Account 1 | mutually-talented-piranha
  # [validating public key] 0xa17fb850bed4c509ade62a28025a1ba2cfb2ddfcc7f57f2314671b72452f7b46d7cc5385dde861aa9b109ab1bc2c62f7

  # Account 2 | publicly-renewing-tiger
  # [validating public key] 0xa7d24732e326207a732fa2f7e2dbc82a476accae977ab31698c31a5f47f5a3f1ab16a2f2a91ea1d5d6eaebe7f01a34a1
  # ```

  # Get validator pubkeys or exit
  if VALIDATORS_PUBKEYS="$(validator accounts list \
    --wallet-dir="${WALLET_DIR}" \
    --wallet-password-file="${WALLETPASSWORD_FILE}" \
    --"${NETWORK}" \
    --accept-terms-of-use)"; then
    VALIDATORS_PUBKEYS_ARRAY=($(echo "${VALIDATORS_PUBKEYS}" | grep -o -E '0x[a-zA-Z0-9]{96}'))
    PUBLIC_KEYS_COMMA_SEPARATED=$(echo "${VALIDATORS_PUBKEYS_ARRAY[*]}" | tr ' ' ',')
    if [ -n "$VALIDATORS_PUBKEYS" ]; then
      echo "${INFO} Validator pubkeys found: ${VALIDATORS_PUBKEYS}"
    else
      {
        echo "${WARN} no validators found, no migration needed"
        empty_validator_volume
        exit 0
      }
    fi
  else
    {
      echo "${ERROR} validator accounts list failed, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
      empty_validator_volume
      exit 1
    }
  fi
}

# Export validators and walletpassword.txt
function export_keystores_walletpassowrd() {
  # Export validator keystores
  validator accounts backup \
    --wallet-dir="${WALLET_DIR}" \
    --wallet-password-file="${WALLETPASSWORD_FILE}" \
    --backup-dir="${BACKUP_DIR}" \
    --backup-password-file="${WALLETPASSWORD_FILE}" \
    --backup-public-keys="${PUBLIC_KEYS_COMMA_SEPARATED}" \
    --"${NETWORK}" \
    --accept-terms-of-use || {
    echo "${ERROR} failed to export keystores, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
    empty_validator_volume
    exit 1
  }

  # Create manual_migration file
  mkdir -p /root/manual_migration
  cp "$BACKUP_ZIP_FILE" "$MANUAL_MIGRATION_BACKUP_FILE"
  zip -j "$MANUAL_MIGRATION_BACKUP_FILE" "${WALLETPASSWORD_FILE}"

  # Copy walletpassword to backup folder
  cp "${WALLETPASSWORD_FILE}" "${BACKUP_WALLETPASSWORD_FILE}" || {
    echo "${ERROR} failed to export walletpassword.txt, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
    empty_validator_volume
    exit 1
  }

  # Unzip keystores
  unzip -d "${BACKUP_KEYSTORES_DIR}" "${BACKUP_ZIP_FILE}" || {
    echo "${ERROR} failed to unzip keystores, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
    empty_validator_volume
    exit 1
  }
}

# Export slashing protection data
function export_slashing_protection() {
  validator slashing-protection-history export \
    --datadir="${WALLET_DIR}" \
    --slashing-protection-export-dir="${BACKUP_DIR}" \
    --accept-terms-of-use || {
    echo "${ERROR} failed to export slashing protection, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
    empty_validator_volume
    exit 1
  }

  # Prune the slashing data to prevent the web3signer from crashing due to timeout
  slashing-prune --source-path "$BACKUP_SLASHING_FILE" --target-path "$BACKUP_SLASHING_FILE_PRUNE" || {
    echo "${ERROR} failed to export slashing protection, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
    empty_validator_volume
    exit 1
  }
}

# Create request body file
# - It cannot be used as environment variable because the slashing data might be too big resulting in the error: Error list too many arguments
# - Exit if request body file cannot be created
function create_request_body_file() {
  echo '{}' | jq '{ keystores: [], passwords: [], slashing_protection: "" }' >"$REQUEST_BODY_FILE"
  KEYSTORE_FILES=($(ls "${BACKUP_KEYSTORES_DIR}"/*.json))
  for KEYSTORE_FILE in "${KEYSTORE_FILES[@]}"; do
    echo $(jq --slurpfile keystore ${KEYSTORE_FILE} '.keystores += [$keystore[0]|tojson]' ${REQUEST_BODY_FILE}) >${REQUEST_BODY_FILE}
    echo $(jq --arg walletpassword "$(cat ${BACKUP_WALLETPASSWORD_FILE})" '.passwords += [$walletpassword]' ${REQUEST_BODY_FILE}) >${REQUEST_BODY_FILE}
  done
  echo $(jq --slurpfile slashing $BACKUP_SLASHING_FILE_PRUNE '.slashing_protection |= [$slashing[0]|tojson][0]' $REQUEST_BODY_FILE) >${REQUEST_BODY_FILE}
}

# Import validators with request body file
# - Docs: https://consensys.github.io/web3signer/web3signer-eth2.html#operation/KEYMANAGER_IMPORT
function import_validators() {
  curl -X POST \
    -d @"${REQUEST_BODY_FILE}" \
    --retry 30 \
    --retry-delay 3 \
    --retry-connrefused \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "Host: prysm.migration.dappnode" \
    "${WEB3SIGNER_API}"/eth/v1/keystores

  echo "${INFO} validators imported"
}

# Remove all content except validator.db amd tosaccepted file
function empty_validator_volume() {
  # Moves tosaccepted file to walletdir
  mv "/root/.eth2/tosaccepted" "${WALLET_DIR}"/tosaccepted || echo "${WARN} failed to move tosaccepted file, manual migration required. Please check https://mainnet-manual-migration.dappnode.io to get more info"
  # Removes old --datadir. Not needed anymore
  rm -rf "/root/.eth2" || echo "${WARN} failed to remove /root/.eth2"
  # Removes old validator files: keystores and walletpassword.txt
  rm -rf "${WALLET_DIR}/direct" || echo "${WARN} failed to remove ${WALLET_DIR}/direct"
  rm -rf "${WALLET_DIR}/walletpassword.txt" || echo "${WARN} failed to remove ${WALLET_DIR}/walletpassword.txt"
  # Removes backup files
  rm -rf "${BACKUP_DIR}" || echo "${WARN} failed to remove ${BACKUP_DIR}"
}

########
# MAIN #
########

error_handling() {
  echo 'Error raised. Cleaning validator volume and exiting'
  empty_validator_volume
}

trap 'error_handling' ERR

echo "${INFO} ensure files exist"
ensure_files_exist
echo "${INFO} getting validator pubkeys"
get_public_keys
echo "${INFO} exporting keystores and walletpassword"
export_keystores_walletpassowrd
echo "${INFO} exporting slashing protection"
export_slashing_protection
echo "${INFO} creating request body"
create_request_body_file
echo "${INFO} ensuring requirements"
ensure_requirements
echo "${INFO} importing validators"
import_validators
echo "${INFO} removing wallet dir recursively"
empty_validator_volume

exit 0
