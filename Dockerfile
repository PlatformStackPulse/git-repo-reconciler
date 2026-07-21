FROM ubuntu:26.04 AS base

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
FROM ubuntu:26.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Non-root user
RUN groupadd -g 2000 app && \
    useradd -u 2000 -g app -s /bin/bash app

COPY --from=base /app/bin/grr /usr/local/bin/grr

USER app

ENTRYPOINT ["grr"]
