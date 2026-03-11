FROM ruby:3-alpine

# Define build arguments for version control
ARG BRAKEMAN_VERSION=8.0.4
ARG REVIEWDOG_VERSION=v0.20.3

# OCI standard labels
LABEL org.opencontainers.image.source="https://github.com/7a6163/docker-brakeman"
LABEL org.opencontainers.image.description="Brakeman static analysis security scanner for Ruby on Rails with reviewdog integration"
LABEL org.opencontainers.image.licenses="MIT"

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN apk add --no-cache git tini bash curl && \
    gem install brakeman -v ${BRAKEMAN_VERSION} --no-document && \
    wget -O /tmp/install-reviewdog.sh -q \
      https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh && \
    # Script SHA must match reviewdog commit fd59714. Update checksum when changing the commit.
    echo "d10d3eced659912551a78ea4b801faa0976809a5a3ff0da5d2dc921d759180f1  /tmp/install-reviewdog.sh" | sha256sum -c && \
    sh /tmp/install-reviewdog.sh ${REVIEWDOG_VERSION} && \
    rm /tmp/install-reviewdog.sh

# Copy scripts
COPY scripts/run-reviewdog.sh /usr/local/bin/run-reviewdog
RUN chmod +x /usr/local/bin/run-reviewdog

# Run as non-root user
RUN addgroup -S brakeman && adduser -S brakeman -G brakeman
USER brakeman

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["brakeman"]
