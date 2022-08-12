FROM debian:buster-slim as binary

ARG TARGETARCH
ARG UPSTREAM_VERSION
ENV DOWNLOAD_URL https://github.com/prysmaticlabs/prysm/releases/download

RUN DEBIAN_FRONTEND=noninteractive \
    apt update && apt install --assume-yes --no-install-recommends wget ca-certificates && \
    wget -q $DOWNLOAD_URL/$UPSTREAM_VERSION/beacon-chain-$UPSTREAM_VERSION-linux-${TARGETARCH:-amd64} -O /usr/local/bin/beacon-chain && \
    chmod +x  /usr/local/bin/beacon-chain

FROM debian:buster-slim

#Copy binaries from build stage
COPY --from=binary /usr/local/bin/beacon-chain /usr/local/bin/beacon-chain

RUN apt update && \
    apt install -y ca-certificates file && \
    rm -rf /var/lib/apt/lists/*

ADD ssl /ssl/

COPY jwtsecret.hex /jwtsecret

ENTRYPOINT [ "sh", "-c", "exec beacon-chain \
    --mainnet \
    --datadir=/data \
    --rpc-host=0.0.0.0 \
    --grpc-gateway-host=0.0.0.0 \
    --monitoring-host=0.0.0.0 \
    --p2p-tcp-port=$P2P_TCP_PORT \
    --p2p-udp-port=$P2P_UDP_PORT \
    --http-web3provider=\"$HTTP_ENGINE\" \
    --grpc-gateway-port=3500 \
    --grpc-gateway-corsdomain=\"$CORSDOMAIN\" \
    --accept-terms-of-use \
    --jwt-secret=/jwtsecret \
    $EXTRA_OPTS" ]
