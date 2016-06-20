FROM ruby:latest

RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

ENV app /app
RUN mkdir $app
WORKDIR $app
ADD . $app

CMD bundle exec clockwork clock.rb
