# GigSaathi — Gig Worker Companion

GigSaathi is a small Rails application for gig workers and daily-wage workers. It brings together three tools: a multilingual AI assistant, a daily earnings tracker, and an AI-assisted complaint draft that workers can edit and copy.

## Requirements

- Ruby 3.4.10 (see `.ruby-version`)
- Bundler 2.5 or newer
- PostgreSQL 14 or newer, running locally or reachable from the app
- A compatible chat-completions API key to enable AI features (optional)

Rails 8.1.4 is specified in the Gemfile. The application can start without an AI key; the two AI features display a clear setup message until one is configured.

## Setup

1. Install PostgreSQL and start its service.
2. From the project directory, install the Ruby dependencies:

   ```powershell
   bundle install
   ```

3. Configure the PostgreSQL connection. Copy `.env.example` to `.env` and enter the username and password for your local PostgreSQL user. The local `.env` is ignored by Git and loaded in development and test. By default Rails connects to `localhost:5432` as user `postgres` and uses `gig_saathi_development` and `gig_saathi_test`. Override connection settings with `PGHOST`, `PGPORT`, `PGUSER`, and `PGPASSWORD`. Rails also accepts `DATABASE_URL`.
4. Create and migrate the databases:

   ```powershell
   bin/rails db:create db:migrate
   ```

5. (Optional) Configure an LLM API key and model:

   ```powershell
   $env:LLM_API_KEY = "your-api-key"
   $env:LLM_MODEL = "gpt-4o-mini"
   ```

   `LLM_API_KEY` is preferred; `OPENAI_API_KEY` is also accepted. The default endpoint is OpenAI's chat-completions API. For another compatible provider, set `LLM_API_URL` to its chat-completions endpoint and set `LLM_MODEL` to a supported model. Keep credentials in your shell/environment configuration, never in source control.

6. Start the web server:

   ```powershell
   bin/rails server
   ```

   Open [http://localhost:3000](http://localhost:3000).

## Features

- **AI Assistant** — Ask about safety, worker rights, or welfare schemes in English, Hindi, or Hinglish. The assistant is instructed not to invent legal or government-scheme facts and to direct workers to official sources for details that vary by location or date.
- **My Earnings** — Save a work date, total earnings, fuel, food, and other expenses. The app calculates take-home earnings and lists previous entries. Amounts cannot be negative.
- **Complaint Help** — Generate a draft in English or Hindi for delayed payments, unfair deductions, account deactivation, or another work issue. The draft uses only the worker's description, can be edited in the page, and can be copied to the clipboard. Review it before sending.

The MVP does not include user accounts: earnings entries are shared by anyone who can access the same deployment. Do not deploy it with real personal or financial data until authentication and per-user data access have been added.

## Tests

The automated tests cover earnings calculations and validation, feature pages, request validation, and AI configuration/error states. AI generation is stubbed in integration tests; no paid API request is made.

```powershell
bin/rails test
```

The test suite uses the `gig_saathi_test` PostgreSQL database, so PostgreSQL must be running and configured before tests are run.
# GigSaathi
# GigSaathi
