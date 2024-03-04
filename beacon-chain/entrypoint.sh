#!/bin/sh

if [ -n "$CHECKPOINT_SYNC_URL" ]; then
  EXTRA_OPTS="--checkpoint-sync-url=${CHECKPOINT_SYNC_URL} --genesis-beacon-api-url=${CHECKPOINT_SYNC_URL} ${EXTRA_OPTS}"
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

if [ -n "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" ] && [ "$_DAPPNODE_GLOBAL_MEVBOOST_MAINNET" = "true" ]; then
  echo "MEVBOOST is enabled"
  MEVBOOST_URL="http://mev-boost.mev-boost.dappnode:18550"
  EXTRA_OPTS="--http-mev-relay=${MEVBOOST_URL} ${EXTRA_OPTS}"
fi

if [ -n "$FEE_RECIPIENT_ADDRESS" ] && echo "$FEE_RECIPIENT_ADDRESS" | grep -Eq '^0x[a-fA-F0-9]{40}$'; then
  echo "FEE_RECIPIENT is valid"
else
  echo "FEE_RECIPIENT is not a valid ethereum address, setting it to the null address"
  FEE_RECIPIENT_ADDRESS="0x0000000000000000000000000000000000000000"
fi

if ! echo "$EXTRA_OPTS" | grep -q -- "--suggested-fee-recipient"; then
  echo "Adding --suggested-fee-recipient=${FEE_RECIPIENT_ADDRESS} to EXTRA_OPTS"
  EXTRA_OPTS="--suggested-fee-recipient=${FEE_RECIPIENT_ADDRESS} ${EXTRA_OPTS}"
fi

exec -c /beacon-chain \
  --datadir=/data \
  --rpc-host=0.0.0.0 \
  --accept-terms-of-use \
  --mainnet \
  --grpc-gateway-host=0.0.0.0 \
  --monitoring-host=0.0.0.0 \
  --p2p-tcp-port=$P2P_TCP_PORT \
  --p2p-udp-port=$P2P_UDP_PORT \
  --execution-endpoint=$HTTP_ENGINE \
  --grpc-gateway-port=$VALIDATOR_PORT \
  --grpc-gateway-corsdomain=$CORSDOMAIN \
  --jwt-secret=$JWT_PATH \
  $EXTRA_OPTS
