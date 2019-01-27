###### before this do some of that 'multistage-builds' to get the elm compiled

FROM ruby:2.5.3-alpine3.8
RUN apk add --update alpine-sdk

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile /app/
RUN bundle install --quiet

COPY requester.rb /app
COPY config.ru /app
EXPOSE 5000

ENTRYPOINT ["rackup"]
CMD ["--host", "0.0.0.0", "-p", "5000"]
