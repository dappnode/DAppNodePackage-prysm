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
    EXTRA_OPTS="--enable-builder ${EXTRA_OPTS}"
fi

# Chek the env FEE_RECIPIENT_MAINNET has a valid ethereum address if not set to the null address
if [ -n "$FEE_RECIPIENT_MAINNET" ] && [[ "$FEE_RECIPIENT_MAINNET" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    FEE_RECIPIENT_ADDRESS="$FEE_RECIPIENT_MAINNET"
else
    echo "FEE_RECIPIENT_MAINNET is not set or is not a valid ethereum address, setting it to the null address"
    FEE_RECIPIENT_ADDRESS="0x0000000000000000000000000000000000000000"
fi

#Implement graffiti limit to account for non unicode characters to prevent a restart loop
oLang=$LANG oLcAll=$LC_ALL
LANG=C LC_ALL=C 
graffitiString=${GRAFFITI:0:32}
LANG=$oLang LC_ALL=$oLcAll

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
    --graffiti="${graffitiString}" \
    --suggested-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
    --web \
    --accept-terms-of-use \
    --enable-doppelganger \
    ${EXTRA_OPTS}
