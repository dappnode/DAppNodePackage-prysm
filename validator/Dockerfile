###############
# Prune image #
###############
# golang alpine 1.17
FROM golang:1.17-alpine as prune
WORKDIR /usr/src/app
RUN apk update && apk add git && git clone https://github.com/dappnode/prune-slashing-protection.git && \
  go build -o slashing-prune ./prune-slashing-protection/slashing-prune.go

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

RUN apt-get update && apt-get install -y ca-certificates file curl jq unzip zip && \
  rm -rf /var/lib/apt/lists/*

# Copy slashing prune
COPY --from=prune /usr/src/app/slashing-prune /usr/local/bin

#Copy binaries from build stage
COPY --from=binary /usr/local/bin/validator /usr/local/bin
COPY auth-token /auth-token
COPY eth2-migrate.sh /usr/local/bin
COPY entrypoint.sh /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
