ARG UPSTREAM_VERSION
FROM debian:bullseye-slim AS builder

# Use ldd to copy dependencies of grep
RUN mkdir /deps
RUN ldd /bin/grep | tr -s '[:space:]' '\n' | grep '^/' | xargs -I {} cp -v {} /deps || true

ARG UPSTREAM_VERSION
FROM gcr.io/prysmaticlabs/prysm/beacon-chain:${UPSTREAM_VERSION}

COPY jwtsecret.hex /jwtsecret
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

COPY --from=builder /bin/sh /bin/sh
COPY --from=builder /bin/grep /bin/grep
COPY --from=builder /deps/* /lib/

ENV JWT_PATH=/jwtsecret \
    VALIDATOR_PORT=3500

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]