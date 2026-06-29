FROM ruby:3.1.3

# зависимости
RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev nodejs yarn \
  chromium fonts-dejavu fonts-liberation \
  && rm -rf /var/lib/apt/lists/*

# Путь к headless-браузеру для Ferrum (генерация PDF)
ENV FERRUM_BROWSER_PATH=/usr/bin/chromium

WORKDIR /app
# app
COPY . .

# gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 2
RUN bundle exec rake assets:precompile



# assets (если используешь sprockets/webpacker/jsbundling)
ENV RAILS_ENV=production

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]