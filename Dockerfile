FROM ruby:3.1.3

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
RUN bundle exec rails assets:precompile

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]