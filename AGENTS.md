# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

Infrastructure for a WhatsApp real estate lead qualification agent (Portuguese-Brazilian market). The stack is fully containerized; **agent logic lives in n8n workflows** (not yet implemented). The README documents: "A lógica do agente ainda não existe" — the infrastructure is ready, the workflows are pending.

## Common Commands

All operations go through the Makefile:

```bash
make up          # Start stack, run migrations, wait for health checks
make down        # Stop containers (preserves volumes)
make migrate     # Run pending SQL migrations
make seed        # Insert 15 demo São Paulo properties (idempotent)
make reset       # DESTRUCTIVE: delete volumes and rebuild from scratch
make ps          # Show container health status
make logs        # Tail all logs
make logs s=n8n  # Tail logs for a specific service
make psql        # Open psql shell in the app database
```

Prerequisites: Docker Engine 24+ and Compose v2. Run `cp .env.example .env` and fill secrets before `make up`.

Local URLs (via Caddy with internal CA): `https://n8n.localhost` and `https://chat.localhost`.

## Architecture

```
WhatsApp (360dialog or Meta Cloud API)
    ↓ webhook
n8n (workflow orchestrator — logic goes here)
    ↓ SQL / pgvector similarity search
PostgreSQL 16 + pgvector
    ↓ handoff trigger
Chatwoot (human inbox for real estate agents)
    ↓ reverse proxy + TLS
Caddy
```

**Services in docker-compose.yml:** postgres, redis, n8n, chatwoot (app + sidekiq workers), caddy.

`docker-compose.override.yml` adds a `dev` profile that exposes service ports directly (5432, 6379, 5678, 3000) and disables secure cookies for localhost testing.

## Database Layout

Two databases in one Postgres cluster:

- **`app` database** — application data across two schemas:
  - `core` schema — leads, conversas, mensagens, qualificacoes, imoveis (with pgvector embeddings)
  - `n8n` schema — n8n internal data (auto-managed by n8n)
- **`chatwoot` database** — Chatwoot Rails app (requires `public` schema)

Three roles: `app_role`, `n8n_role`, `chatwoot_role` — each scoped to its own schema.

### Key Tables (core schema)

| Table | Purpose |
|---|---|
| `leads` | E.164 phone, name, status enum, origem enum, JSONB metadata |
| `conversas` | Session per lead; links to `chatwoot_conversation_id`; has `handoff_status` |
| `mensagens` | Chat history with `papel` (user/assistant/system), token counts, WAMID dedup |
| `qualificacoes` | Scoring history: finalidade, price range, region, urgency, financing, score 0–100 |
| `imoveis` | Property catalog with `embedding vector(1536)` for semantic search |

Extensions: `vector` (pgvector), `pgcrypto`, `pg_trgm`.

`imoveis.embedding` is NULL after seed — requires an n8n backfill job hitting OpenAI `text-embedding-3-small`.

## Migrations

Files in `db/migrations/` are numbered `NNN_name.sql` and run in order by `scripts/migrate.sh`, which tracks applied migrations in a `schema_migrations` table. Migrations are idempotent by convention.

To add a migration: create `db/migrations/007_name.sql` and run `make migrate`.

## Environment Variables

Copy `.env.example` to `.env`. Key groups:

- **Database**: `POSTGRES_PASSWORD`, `APP_DB_PASS`, `N8N_DB_PASS`, `CHATWOOT_DB_PASS`
- **Redis**: `REDIS_PASSWORD`
- **n8n**: `N8N_ENCRYPTION_KEY`
- **Chatwoot**: `CHATWOOT_SECRET_KEY_BASE`, `ACME_EMAIL`
- **LLM**: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`
- **WhatsApp**: `WHATSAPP_PROVIDER` (`360dialog` or `meta`), plus provider-specific tokens
- **Chatwoot handoff**: `CHATWOOT_ACCESS_TOKEN`, `CHATWOOT_ACCOUNT_ID`, `CHATWOOT_INBOX_ID`

## Language

All user-facing content, SQL comments, and documentation are in Portuguese (Brazil). Use `pt-BR` in any new content targeting end users or agents.
