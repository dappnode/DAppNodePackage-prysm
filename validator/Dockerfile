FROM debian:buster-slim as binary

ARG TARGETARCH
ARG UPSTREAM_VERSION
ENV DOWNLOAD_URL https://github.com/prysmaticlabs/prysm/releases/download

RUN DEBIAN_FRONTEND=noninteractive \
      apt update && apt install --assume-yes --no-install-recommends wget ca-certificates  && \
      wget -q $DOWNLOAD_URL/$UPSTREAM_VERSION/validator-$UPSTREAM_VERSION-linux-${TARGETARCH:-amd64} -O /usr/local/bin/validator && \
      chmod +x /usr/local/bin/validator

FROM debian:buster-slim

RUN apt update && \
    apt install -y ca-certificates file git && \
    rm -rf /var/lib/apt/lists/*

#Copy binaries from build stage
COPY --from=binary /usr/local/bin/validator /usr/local/bin

# Verify binary is in correct arch
RUN /usr/local/bin/validator --version

# Must used escaped \"$VAR\" to accept spaces: --graffiti=\"$GRAFFITI\"
ENTRYPOINT [ "sh", "-c", "exec validator \
  --mainnet \
  --datadir=/root/.eth2 \
  --rpc-host 0.0.0.0 \
  --grpc-gateway-host 0.0.0.0 \
  --monitoring-host 0.0.0.0 \
  --beacon-rpc-provider=\"$BEACON_RPC_PROVIDER\" \
  --beacon-rpc-gateway-provider=\"$BEACON_RPC_GATEWAY_PROVIDER\" \
  --wallet-dir=/root/.eth2validators \
  --wallet-password-file=/root/.eth2wallets/wallet-password.txt \
  --write-wallet-password-on-web-onboarding \
  --graffiti=\"$GRAFFITI\" \
  --web \
  --grpc-gateway-host=0.0.0.0 \
  --grpc-gateway-port=80 \
  --accept-terms-of-use \
  $EXTRA_OPTS" ]
