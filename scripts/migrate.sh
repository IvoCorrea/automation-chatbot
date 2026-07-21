#!/bin/bash
# Aplica db/migrations/*.sql em ordem, uma vez cada, registrando em
# schema_migrations. Roda DENTRO do container do postgres (via make migrate),
# entao nao exige psql instalado na maquina.
set -euo pipefail

MIGRATIONS_DIR="${MIGRATIONS_DIR:-/db/migrations}"
DB_NAME="${APP_DB_NAME:-app}"
DB_USER="${APP_DB_USER:-app}"
DB_SCHEMA="${APP_DB_SCHEMA:-core}"

export PGPASSWORD="${APP_DB_PASSWORD}"
psql_app() {
	psql -v ON_ERROR_STOP=1 --quiet --host 127.0.0.1 --username "$DB_USER" --dbname "$DB_NAME" "$@"
}

# Controle de versao das migrations. search_path da role ja aponta para o schema.
psql_app --command "
	CREATE TABLE IF NOT EXISTS ${DB_SCHEMA}.schema_migrations (
		version    text PRIMARY KEY,
		aplicada_em timestamptz NOT NULL DEFAULT now()
	);"

applied=0
for file in "${MIGRATIONS_DIR}"/*.sql; do
	[ -e "$file" ] || { echo "nenhuma migration encontrada em ${MIGRATIONS_DIR}"; exit 0; }
	version="$(basename "$file")"

	exists="$(psql_app --tuples-only --no-align \
		--command "SELECT 1 FROM ${DB_SCHEMA}.schema_migrations WHERE version = '${version}';")"
	if [ "$exists" = "1" ]; then
		echo "  = ${version} (ja aplicada)"
		continue
	fi

	echo "  + ${version}"
	# Uma transacao por migration: se falhar no meio, nada e registrado.
	psql_app --single-transaction \
		--file "$file" \
		--command "INSERT INTO ${DB_SCHEMA}.schema_migrations (version) VALUES ('${version}');"
	applied=$((applied + 1))
done

echo "migrations concluidas (${applied} nova(s))."
