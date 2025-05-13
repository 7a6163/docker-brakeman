FROM ruby:3-alpine

# Define build arguments for version control
ARG BRAKEMAN_VERSION=7.0.2
ARG REVIEWDOG_VERSION=v0.20.3

RUN apk add --no-cache git=2.47.2-r0 tini=0.19.0-r3
RUN gem install brakeman -v ${BRAKEMAN_VERSION}

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s ${REVIEWDOG_VERSION}

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["brakeman"]
