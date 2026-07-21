# Atalhos da stack local. Requer Docker + Docker Compose v2.
# No Windows, rode em Git Bash / WSL (o make usa sintaxe POSIX).

SHELL := /bin/bash
COMPOSE := docker compose

.DEFAULT_GOAL := help
.PHONY: help up down logs migrate seed reset ps psql

## help: lista os alvos disponiveis
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /'

# Cria o .env a partir do exemplo na primeira execucao, para que `make up`
# funcione numa maquina limpa sem passo manual esquecido.
.env:
	@cp .env.example .env
	@echo ">> .env criado a partir de .env.example."
	@echo ">> TROQUE AS SENHAS antes de expor esta stack em rede publica."

## up: sobe a stack, espera ficar saudavel e aplica as migrations
up: .env
	$(COMPOSE) up -d --wait
	@$(MAKE) --no-print-directory migrate
	@echo ""
	@echo "  n8n      -> https://n8n.$${BASE_DOMAIN:-localhost}   (direto: http://localhost:5678)"
	@echo "  chatwoot -> https://chat.$${BASE_DOMAIN:-localhost}  (direto: http://localhost:3000)"
	@echo "  postgres -> localhost:5432"
	@echo ""
	@echo "  proximo passo: make seed"

## down: para a stack (mantem os volumes e os dados)
down:
	$(COMPOSE) down

## logs: acompanha os logs de todos os servicos (make logs s=n8n para um so)
logs:
	$(COMPOSE) logs -f --tail=100 $(s)

## migrate: aplica as migrations pendentes em db/migrations
migrate:
	$(COMPOSE) exec -T postgres bash /scripts/migrate.sh

## seed: popula os dados de demonstracao (15 imoveis)
seed:
	$(COMPOSE) exec -T postgres bash /scripts/seed.sh

## reset: APAGA todos os volumes e reconstroi do zero (migrations + seed)
reset:
	@read -p "Isso apaga TODOS os dados locais (postgres, n8n, chatwoot). Continuar? [y/N] " ok; \
	 [ "$$ok" = "y" ] || { echo "cancelado."; exit 1; }
	$(COMPOSE) down -v --remove-orphans
	@$(MAKE) --no-print-directory up
	@$(MAKE) --no-print-directory seed

## ps: estado e healthcheck de cada servico
ps:
	$(COMPOSE) ps

## psql: abre um shell psql no database da aplicacao
psql:
	$(COMPOSE) exec postgres bash -c 'PGPASSWORD=$$APP_DB_PASSWORD psql -h 127.0.0.1 -U $$APP_DB_USER -d $$APP_DB_NAME'
