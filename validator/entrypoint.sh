#!/bin/bash

CLIENT="prysm"
export NETWORK="mainnet"
VALIDATOR_PORT=3500
export WEB3SIGNER_API="http://web3signer.web3signer.dappnode:9000"
export WALLET_DIR="/root/.eth2validators"

# Copy auth-token in runtime to the prysm token dir
mkdir -p ${WALLET_DIR}
cp /auth-token ${WALLET_DIR}/auth-token

# Migrate if required
if [[ $(validator accounts list \
    --wallet-dir="$WALLET_DIR" \
    --wallet-password-file="${WALLET_DIR}/walletpassword.txt" \
    --mainnet \
    --accept-terms-of-use) ]]; then
    {
        echo "found validators, starging migration"
        eth2-migrate.sh &
        wait $!
    }
else
    { echo "validators not found, no migration needed"; }
fi

# Remove manual migration if older than 20 days
find /root -type d -name manual_migration -mtime +20 -exec rm -rf {} +

WEB3SIGNER_RESPONSE=$(curl -s -w "%{http_code}" -X GET -H "Content-Type: application/json" -H "Host: validator.${CLIENT}.dappnode" "${WEB3SIGNER_API}/eth/v1/keystores")
HTTP_CODE=${WEB3SIGNER_RESPONSE: -3}
CONTENT=$(echo "${WEB3SIGNER_RESPONSE}" | head -c-4)

if [ "${HTTP_CODE}" == "403" ] && [ "${CONTENT}" == "*Host not authorized*" ]; then
    echo "${CLIENT} is not authorized to access the Web3Signer API. Start without pubkeys"
elif [ "$HTTP_CODE" != "200" ]; then
    echo "Failed to get keystores from web3signer, HTTP code: ${HTTP_CODE}, content: ${CONTENT}"
else
    PUBLIC_KEYS_WEB3SIGNER=($(echo "${CONTENT}" | jq -r 'try .data[].validating_pubkey'))
    if [ ${#PUBLIC_KEYS_WEB3SIGNER[@]} -gt 0 ]; then
        PUBLIC_KEYS_COMMA_SEPARATED=$(echo "${PUBLIC_KEYS_WEB3SIGNER[*]}" | tr ' ' ',')
        echo "found validators in web3signer, starting vc with pubkeys: ${PUBLIC_KEYS_COMMA_SEPARATED}"
        EXTRA_OPTS="--validators-external-signer-public-keys=${PUBLIC_KEYS_COMMA_SEPARATED} ${EXTRA_OPTS}"
    fi
fi

exec -c validator --mainnet \
    --datadir="$WALLET_DIR" \
    --wallet-dir="$WALLET_DIR" \
    --monitoring-host 0.0.0.0 \
    --beacon-rpc-provider="$BEACON_RPC_PROVIDER" \
    --beacon-rpc-gateway-provider="$BEACON_RPC_GATEWAY_PROVIDER" \
    --validators-external-signer-url="$WEB3SIGNER_API" \
    --grpc-gateway-host=0.0.0.0 \
    --grpc-gateway-port="$VALIDATOR_PORT" \
    --grpc-gateway-corsdomain=http://0.0.0.0:"$VALIDATOR_PORT" \
    --graffiti="$GRAFFITI" \
    --p2p-tcp-port=$P2P_TCP_PORT \
    --p2p-udp-port=$P2P_UDP_PORT \
    --suggested-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
    --web \
    --accept-terms-of-use \
    ${EXTRA_OPTS}
