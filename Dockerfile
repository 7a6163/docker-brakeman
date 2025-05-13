FROM ruby:3-alpine

RUN apk add --no-cache tini=0.19.0-r3
RUN gem install brakeman -v 7.0.2

RUN wget -O - -q https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s v0.20.3

WORKDIR /app


ENTRYPOINT ["/sbin/tini", "--"]
CMD ["brakeman"]
