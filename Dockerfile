FROM ubuntu:24.04 AS base

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source
COPY lib/ lib/
COPY src/ src/
COPY scripts/ scripts/
COPY Makefile .

# Build
RUN chmod +x scripts/build.sh && scripts/build.sh

# Runtime stage
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Non-root user
RUN groupadd -g 1000 app && \
    useradd -u 1000 -g app -s /bin/bash app

COPY --from=base /app/bin/bash-template /usr/local/bin/bash-template

USER app

ENTRYPOINT ["bash-template"]
