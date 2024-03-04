ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/validator:${UPSTREAM_VERSION}

COPY auth-token /auth-token
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

COPY --from=builder /bin/sh /bin/sh

ENV NETWORK=mainnet \
  VALIDATOR_PORT=3500

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]