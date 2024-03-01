##############
# Base image #
##############
FROM debian:bullseye-slim as binary

ARG TARGETARCH
ARG UPSTREAM_VERSION
ENV DOWNLOAD_URL https://github.com/prysmaticlabs/prysm/releases/download

RUN DEBIAN_FRONTEND=noninteractive \
  apt update && apt install --assume-yes --no-install-recommends wget ca-certificates && \
  wget -q $DOWNLOAD_URL/$UPSTREAM_VERSION/validator-$UPSTREAM_VERSION-linux-${TARGETARCH:-amd64} -O /usr/local/bin/validator && \
  chmod +x  /usr/local/bin/validator

################
# Runner image #
################
FROM debian:bullseye-slim

#Copy binaries from build stage
COPY --from=binary /usr/local/bin/validator /usr/local/bin
COPY auth-token /auth-token
COPY entrypoint.sh /usr/local/bin

ENV NETWORK=mainnet \ 
  WEB3SIGNER_API=http://web3signer.web3signer.dappnode:9000 \
  WALLET_DIR=/root/.eth2validators/prysm-wallet-v2 \
  VALIDATOR_PORT=3500

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
