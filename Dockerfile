FROM ruby:3.1.3

RUN mkdir -p tmp/pids tmp/cache tmp/sockets log \
 && chmod -R 777 tmp log
# зависимости
RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev nodejs yarn

WORKDIR /app

# gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# app
COPY . .

# assets (если используешь sprockets/webpacker/jsbundling)
ENV RAILS_ENV=production

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]