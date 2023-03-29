#!/bin/bash

if [[ -n $CHECKPOINT_SYNC_URL ]]; then
  EXTRA_OPTS="--checkpoint-sync-url=${CHECKPOINT_SYNC_URL} --genesis-beacon-api-url=${CHECKPOINT_SYNC_URL} ${EXTRA_OPTS}"
else
  EXTRA_OPTS="--genesis-state=/genesis.ssz ${EXTRA_OPTS}"
fi

case $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_MAINNET in
"geth.dnp.dappnode.eth")
  HTTP_ENGINE="http://geth.dappnode:8551"
  ;;
"nethermind.public.dappnode.eth")
  HTTP_ENGINE="http://nethermind.public.dappnode:8551"
  ;;
"erigon.dnp.dappnode.eth")
  HTTP_ENGINE="http://erigon.dappnode:8551"
  ;;
"besu.public.dappnode.eth")
  HTTP_ENGINE="http://besu.public.dappnode:8551"
  ;;
*)
  echo "Unknown value for _DAPPNODE_GLOBAL_EXECUTION_CLIENT_MAINNET: $_DAPPNODE_GLOBAL_EXECUTION_CLIENT_MAINNET"
  HTTP_ENGINE=$_DAPPNODE_GLOBAL_EXECUTION_CLIENT_MAINNET
  ;;
esac

apt update
apt install -y curl

# MEVBOOST: https://hackmd.io/@prysmaticlabs/BJeinxFsq
if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" == "true" ]; then
  echo "MEVBOOST is enabled"
  MEVBOOST_URL="http://mev-boost.mev-boost.dappnode:18550"
  EXTRA_OPTS="--http-mev-relay=${MEVBOOST_URL} ${EXTRA_OPTS}"
fi

# Chek the env FEE_RECIPIENT_ADDRESS has a valid ethereum address if not set to the null address
if [ -n "$FEE_RECIPIENT_ADDRESS" ] && [[ "$FEE_RECIPIENT_ADDRESS" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "FEE_RECIPIENT is valid"
else
    echo "FEE_RECIPIENT is not a valid ethereum address, setting it to the null address"
    FEE_RECIPIENT_ADDRESS="0x0000000000000000000000000000000000000000"
fi

exec -c beacon-chain \
  --datadir=/data \
  --rpc-host=0.0.0.0 \
  --accept-terms-of-use \
  --mainnet \
  --grpc-gateway-host=0.0.0.0 \
  --monitoring-host=0.0.0.0 \
  --p2p-tcp-port=$P2P_TCP_PORT \
  --p2p-udp-port=$P2P_UDP_PORT \
  --execution-endpoint=$HTTP_ENGINE \
  --grpc-gateway-port=3500 \
  --grpc-gateway-corsdomain=$CORSDOMAIN \
  --jwt-secret=/jwtsecret \
  --suggested-fee-recipient="${FEE_RECIPIENT_ADDRESS}" \
  $EXTRA_OPTS
