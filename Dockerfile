FROM ruby:3.1.2
WORKDIR /work
ADD Gemfile .
ADD Gemfile.lock .
RUN bundle install
