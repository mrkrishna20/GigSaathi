# GigSaathi — Gig Worker Companion

GigSaathi is a small Rails application for gig workers and daily-wage workers. It brings together three tools: a multilingual AI assistant, a daily earnings tracker, and an AI-assisted complaint draft that workers can edit and copy.

## Requirements

- Ruby 3.4.10 (see `.ruby-version`)
- Bundler 2.5 or newer
- PostgreSQL 14 or newer, running locally or reachable from the app
- A PostgreSQL database and optional compatible chat-completions API key

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

5. Register a worker account in the app before recording earnings. Earnings entries are private to the signed-in account; sign-in and account creation are rate-limited.
6. (Optional) Enable the AI features by adding your provider-issued key to `.env`:

   ```powershell
   GROQ_API_KEY=your-groq-api-key
   ```

   Replace `your-groq-api-key` with the key from GroqCloud. `GROQ_API_KEY` or the generic `LLM_API_KEY` uses Groq's OpenAI-compatible chat-completions endpoint and the `openai/gpt-oss-120b` model by default. `OPENAI_API_KEY` alone retains OpenAI's endpoint and `gpt-4o-mini` model. Override `LLM_API_URL` and `LLM_MODEL` when using a different compatible provider/model. The server needs outbound HTTPS and DNS access to `api.groq.com`; if the assistant reports a connection failure, check the server's internet, DNS, firewall, or proxy settings. Requests are capped at 20 per IP address every three minutes across both AI features. `.env` is ignored by Git; never commit your API key. Restart the Rails server after changing `.env`.

7. Start the web server:

   ```powershell
   bin/rails server
   ```

   Open [http://localhost:3000](http://localhost:3000).

## Features

- **AI Assistant** — Ask about safety, worker rights, or welfare schemes in English, Hindi, or Hinglish. The assistant is instructed not to invent legal or government-scheme facts and to direct workers to official sources for details that vary by location or date.
- **My Earnings** — Save a work date, total earnings, fuel, food, and other expenses. The app calculates take-home earnings and lists previous entries. Amounts cannot be negative.
- **Complaint Help** — Generate a draft in English or Hindi for delayed payments, unfair deductions, account deactivation, or another work issue. The draft uses only the worker's description, can be edited in the page, and can be copied to the clipboard. Review it before sending.

Passwords are stored as bcrypt hashes, and each earnings query and delete is scoped to the signed-in account. Account recovery is not implemented, so workers should use a password manager and avoid reusing an existing password. The original MVP stored earnings without an owner; an upgrade preserves those old rows in the database but they will not appear in any account until an administrator assigns them to their owner.

Production is configured to enforce HTTPS. Terminate TLS at the hosting platform or reverse proxy and enable proxy SSL forwarding before deployment.

## Tests

The automated tests cover earnings calculations and validation, feature pages, request validation, and AI configuration/error states. AI generation is stubbed in integration tests; no paid API request is made.

```powershell
bin/rails test
```

The test suite uses the `gig_saathi_test` PostgreSQL database, so PostgreSQL must be running and configured before tests are run.
# GigSaathi
# GigSaathi
