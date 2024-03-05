#!/bin/sh

WEB3SIGNER_API=http://web3signer.web3signer.dappnode:9000
DATA_DIR=/root/.eth2validators
WALLET_DIR=${DATA_DIR}/prysm-wallet-v2

# Copy auth-token in runtime to the prysm token dir
mkdir -p ${WALLET_DIR}
cp /auth-token ${WALLET_DIR}/auth-token

if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" = "true" ]; then
    echo "MEVBOOST is enabled"
    EXTRA_OPTS="--enable-builder ${EXTRA_OPTS}"
fi

#Implement graffiti limit to account for non unicode characters to prevent a restart loop
oLang=$LANG oLcAll=$LC_ALL
LANG=C LC_ALL=C
graffitiString=$(echo ${GRAFFITI} | cut -c 1-32)
LANG=$oLang LC_ALL=$oLcAll

exec /validator --mainnet \
    --datadir="$DATA_DIR" \
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
