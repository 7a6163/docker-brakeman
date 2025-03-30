FROM ruby:3-alpine

RUN apk add --no-cache tini=0.19.0-r3
RUN gem install brakeman -v 7.0.0

WORKDIR /app

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["brakeman"]
