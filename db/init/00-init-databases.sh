#!/bin/bash
# Roda uma unica vez, no primeiro boot do volume do Postgres.
# Cria as roles, os dois databases e os schemas:
#   app      -> schema core (aplicacao) + schema n8n (dados do n8n)
#   chatwoot -> schema public (o Rails do Chatwoot assume public)
# Se o volume ja existir, este script e ignorado pelo entrypoint da imagem.
set -euo pipefail

APP_DB_NAME="${APP_DB_NAME:-app}"
APP_DB_USER="${APP_DB_USER:-app}"
APP_DB_SCHEMA="${APP_DB_SCHEMA:-core}"
N8N_DB_USER="${N8N_DB_USER:-n8n}"
N8N_DB_SCHEMA="${N8N_DB_SCHEMA:-n8n}"
CHATWOOT_DB_NAME="${CHATWOOT_DB_NAME:-chatwoot}"
CHATWOOT_DB_USER="${CHATWOOT_DB_USER:-chatwoot}"

psql_super() {
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" "$@"
}

echo "[init] criando roles..."
psql_super --dbname postgres <<-EOSQL
	CREATE ROLE "${APP_DB_USER}" LOGIN PASSWORD '${APP_DB_PASSWORD}';
	CREATE ROLE "${N8N_DB_USER}" LOGIN PASSWORD '${N8N_DB_PASSWORD}';
	CREATE ROLE "${CHATWOOT_DB_USER}" LOGIN PASSWORD '${CHATWOOT_DB_PASSWORD}';
EOSQL

echo "[init] criando databases..."
psql_super --dbname postgres <<-EOSQL
	CREATE DATABASE "${APP_DB_NAME}" OWNER "${APP_DB_USER}";
	CREATE DATABASE "${CHATWOOT_DB_NAME}" OWNER "${CHATWOOT_DB_USER}";
EOSQL

echo "[init] preparando database ${APP_DB_NAME}..."
psql_super --dbname "${APP_DB_NAME}" <<-EOSQL
	CREATE EXTENSION IF NOT EXISTS vector;
	CREATE EXTENSION IF NOT EXISTS pgcrypto;
	CREATE EXTENSION IF NOT EXISTS pg_trgm;

	-- Schema da aplicacao: dono e o usuario da app.
	CREATE SCHEMA IF NOT EXISTS "${APP_DB_SCHEMA}" AUTHORIZATION "${APP_DB_USER}";
	-- Schema do n8n: isolado, o n8n cria as tabelas dele sozinho.
	CREATE SCHEMA IF NOT EXISTS "${N8N_DB_SCHEMA}" AUTHORIZATION "${N8N_DB_USER}";

	-- Ninguem cria objeto solto no public.
	REVOKE CREATE ON SCHEMA public FROM PUBLIC;

	-- Cada role enxerga apenas o proprio schema por padrao.
	ALTER ROLE "${APP_DB_USER}" IN DATABASE "${APP_DB_NAME}" SET search_path TO "${APP_DB_SCHEMA}", public;
	ALTER ROLE "${N8N_DB_USER}" IN DATABASE "${APP_DB_NAME}" SET search_path TO "${N8N_DB_SCHEMA}", public;

	GRANT CONNECT ON DATABASE "${APP_DB_NAME}" TO "${APP_DB_USER}", "${N8N_DB_USER}";
	GRANT USAGE ON SCHEMA public TO "${APP_DB_USER}", "${N8N_DB_USER}";
EOSQL

echo "[init] preparando database ${CHATWOOT_DB_NAME}..."
# O Chatwoot 4.x usa pgvector na feature Captain; a extensao precisa existir antes
# das migrations dele rodarem, e so o superusuario pode cria-la.
psql_super --dbname "${CHATWOOT_DB_NAME}" <<-EOSQL
	CREATE EXTENSION IF NOT EXISTS vector;
	CREATE EXTENSION IF NOT EXISTS pgcrypto;
EOSQL

echo "[init] concluido."
