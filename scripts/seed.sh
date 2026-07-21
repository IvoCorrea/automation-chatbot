#!/bin/bash
# Popula os dados de demonstracao (db/seed/*.sql). Os scripts sao idempotentes,
# entao rodar varias vezes nao duplica registros.
set -euo pipefail

SEED_DIR="${SEED_DIR:-/db/seed}"
DB_NAME="${APP_DB_NAME:-app}"
DB_USER="${APP_DB_USER:-app}"

export PGPASSWORD="${APP_DB_PASSWORD}"

for file in "${SEED_DIR}"/*.sql; do
	[ -e "$file" ] || { echo "nenhum seed encontrado em ${SEED_DIR}"; exit 0; }
	echo "  + $(basename "$file")"
	psql -v ON_ERROR_STOP=1 --quiet --single-transaction \
		--host 127.0.0.1 --username "$DB_USER" --dbname "$DB_NAME" --file "$file"
done

total="$(psql --tuples-only --no-align --host 127.0.0.1 --username "$DB_USER" \
	--dbname "$DB_NAME" --command 'SELECT count(*) FROM imoveis;')"
echo "seed concluido. imoveis na base: ${total}"
