# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Russvisa — a Ruby on Rails 7.0.3.1 application (Ruby 3.1.3) for Russian tourist visa invitations. It handles order submission, PDF generation (WickedPDF), email notifications, and admin management (ActiveAdmin).

## Common Commands

```bash
# Development (Docker-based)
docker compose -f compose.development.yml up

# Or run directly with Overmind/Foreman
overmind start -f Procfile_dev

# Rails server
bundle exec rails s -p 3000 -b 0.0.0.0

# Database
bundle exec rails db:migrate
bundle exec rails db:seed

# Tests (minitest)
bundle exec rails test                    # all tests
bundle exec rails test test/models/       # model tests only
bundle exec rails test test/models/invitation_test.rb  # single file

# Assets
bundle exec rails assets:precompile

# Console
bundle exec rails console

# Deploy (Capistrano + Docker)
bundle exec cap production deploy
```

## Architecture

- **Core model:** `Invitation` — visa application with multi-currency (EUR/USD) pricing across multiple tariff tiers. Pricing constants are defined as hashes in the model. Price, accommodation, and meals are set via `before_create` callback.
- **PDF generation:** `InvitationsController#show` renders PDF via WickedPDF with Base64-embedded images (seals, logos). Supports both HTML and PDF format responses.
- **Email flow:** Dual notification on order creation — one to the applicant, one to admin (`SMTP_TO_EMAIL`). Silent rescue on email failures.
- **Bot protection:** Cloudflare Turnstile verification on form submission in `InvitationsController#create`.
- **Admin panel:** ActiveAdmin at dynamic path (`ENV['ADMIN_URL']`, default `/admin`). Devise authentication for admin users.
- **Pricing helper:** `ApplicationHelper#all_price_items` generates pricing tiers used in the landing page views.
- **Country data:** `lib/country.rb` provides country lookup used for citizenship fields.

## Key Configuration

- **Database:** PostgreSQL, configured in `config/database.yml` (Docker host `pg:2345` in dev, `DATABASE_URL` in prod)
- **Timezone:** UTC+3 (Moscow)
- **Environment variables:** `.env` file — contains admin URL, Turnstile keys, SMTP credentials
- **Deployment:** Capistrano orchestrates Docker build/push, migration, and container restart on production (`/home/visa`)
- **Secrets:** `config/credentials.yml.enc` with `master.key`