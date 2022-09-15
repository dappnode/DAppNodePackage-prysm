#!/bin/bash

if [[ -n $CHECKPOINT_SYNC_URL ]]; then
  EXTRA_OPTS="--checkpoint-sync-url=${CHECKPOINT_SYNC_URL} --genesis-beacon-api-url=${CHECKPOINT_SYNC_URL} ${EXTRA_OPTS}"
fi

exec -c beacon-chain \
  --datadir=/data \
  --rpc-host=0.0.0.0 \
  --accept-terms-of-use \
  --mainnet \
  --grpc-gateway-host=0.0.0.0 \
  --monitoring-host=0.0.0.0 \
  --execution-endpoint=$HTTP_ENGINE \
  --jwt-secret=/jwtsecret \
  --grpc-gateway-port=3500 \
  --grpc-gateway-corsdomain=$CORSDOMAIN \
  --p2p-tcp-port=$P2P_TCP_PORT \
  --p2p-udp-port=$P2P_UDP_PORT \
  $EXTRA_OPTS
