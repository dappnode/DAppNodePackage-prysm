#!/bin/bash

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

# MEVBOOST: https://hackmd.io/@prysmaticlabs/BJeinxFsq
if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" == "true" ]; then
    echo "MEVBOOST is enabled"
    MEVBOOST_URL="http://mev-boost.mev-boost.dappnode:18550"
    if curl --retry 5 --retry-delay 5 --retry-all-errors "${MEVBOOST_URL}"; then
        EXTRA_OPTS="--enable-builder ${EXTRA_OPTS}"
    else
        echo "MEVBOOST is enabled but ${MEVBOOST_URL} is not reachable"
        curl -X POST -G 'http://my.dappnode/notification-send' --data-urlencode 'type=danger' --data-urlencode title="${MEVBOOST_URL} is not available" --data-urlencode 'body=Make sure the mevboost is available and running'
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
    --graffiti="${GRAFFITI:0:32}" \
    --suggested-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
    --web \
    --accept-terms-of-use \
    --enable-doppelganger \
    ${EXTRA_OPTS}
