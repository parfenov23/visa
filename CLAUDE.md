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
- **Extra services:** `ServiceRequest` model (kinds: insurance / train / vip) with kind-specific fields in jsonb `details` (store_accessor), VIP manager checklist in jsonb `checklist`, passport/visa copies via ActiveStorage. Public pages `/insurance`, `/train-tickets`, `/airport-transfer` (`ServiceRequestsController`, views in `app/views/service_requests`), one POST `/service_requests` with `kind`. `?ref=<invitation verify_token>` prefills name/citizenship/dates and links the invitation. Insurance: USD 1.35/day for IN/NP, 2 for others, 1–180 days; VIP: USD 220; train: price set by manager. Emails: `ServiceRequestMailer` (client confirmation + admin notification with attachments). Admin: "Доп. услуги".
- **Daily report:** `InvitationsReport` (app/services) — invitations by citizenship from the 1st of the month, compared with the same days of the previous month; void statuses (duplicate/cancelled) excluded. Shown in ActiveAdmin page "Сводка по заявкам" and emailed daily by `ReportMailer` (`REPORT_TO_EMAIL`, fallback `SMTP_TO_EMAIL`).
- **Scheduler:** `bin/scheduler` runs `Scheduler` (app/services/scheduler.rb) as the `scheduler` service in `compose.production.yml`; daily jobs are deduplicated via Redis keys. Manual run: `bundle exec rails reports:daily`.
- **Geo pricing:** `GeoCountry` (app/services) looks up visitor country from `storage/geo/country_ranges.csv` (India/Nepal ranges extracted from the free DB-IP country lite DB; refreshed monthly by the scheduler or `rails geo:update`). `HomeController#index` switches visitors from India to tariff `custom_20` when no `tariff`/`currency` is in the URL; disable with `INDIA_GEO_PRICES=off`. The site is not behind the Cloudflare proxy, so `CF-IPCountry` is not available.
- **Country data:** `lib/country.rb` provides country lookup used for citizenship fields.

## Key Configuration

- **Database:** PostgreSQL, configured in `config/database.yml` (Docker host `pg:2345` in dev, `DATABASE_URL` in prod)
- **Timezone:** UTC+3 (Moscow)
- **Environment variables:** `.env` file — contains admin URL, Turnstile keys, SMTP credentials
- **Deployment:** Capistrano orchestrates Docker build/push, migration, and container restart on production (`/home/visa`)
- **Secrets:** `config/credentials.yml.enc` with `master.key`