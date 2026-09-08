# Agente de WhatsApp para imobiliárias — infraestrutura

Stack local para a demo: Spring Boot concentra a API e as regras de dados, n8n orquestra o agente, Postgres+pgvector guarda leads
e catálogo, Chatwoot é a inbox humana do corretor, Caddy publica tudo com TLS.

**O fluxo de IA e as integrações externas ainda precisam ser configurados no n8n**. A API inicial já expõe operações para leads, conversas, mensagens, qualificações e busca de imóveis.

## Requisitos

Docker Engine 24+ com Compose v2. No Windows, rode o `make` pelo Git Bash ou WSL.

## Subir

```bash
make up
```

O `make up` cria o `.env` a partir do `.env.example` na primeira execução, sobe os
containers, espera todos ficarem *healthy* e aplica as migrations. O primeiro boot
demora alguns minutos (o Chatwoot roda as migrations dele).

Para popular os 15 imóveis de demonstração:

```bash
make seed
```

> Troque as senhas do `.env` antes de expor a stack em qualquer rede pública.
> O `.env.example` traz placeholders óbvios de propósito.

## Comandos

| Comando | O que faz |
| --- | --- |
| `make up` | sobe a stack + migrations |
| `make down` | para tudo, preserva os volumes |
| `make logs` | segue os logs (`make logs s=n8n` filtra um serviço) |
| `make migrate` | aplica migrations pendentes de `db/migrations` |
| `make seed` | popula `db/seed` (idempotente) |
| `make reset` | **apaga os volumes** e reconstrói do zero |
| `make ps` | estado e healthcheck de cada serviço |
| `make psql` | shell psql no database da aplicação |

## Portas

Via Caddy (TLS):

| URL | Serviço |
| --- | --- |
| `https://n8n.localhost` | editor do n8n |
| `https://chat.localhost` | Chatwoot |
| `https://api.localhost` | API Spring Boot |

Com `BASE_DOMAIN=localhost` o certificado vem da CA interna do Caddy, então o
browser mostra aviso de certificado — é esperado. Trocando `BASE_DOMAIN` por um
domínio real com DNS apontado e portas 80/443 abertas, o Let's Encrypt entra
sozinho, sem mudar mais nada.

Acesso direto (só no perfil de dev, `docker-compose.override.yml`):

| Porta | Serviço |
| --- | --- |
| 5678 | n8n |
| 3000 | Chatwoot |
| 5432 | Postgres |
| 6379 | Redis |
| 80 / 443 | Caddy |

Para subir sem expor essas portas: `docker compose -f docker-compose.yml up -d`.

## Banco

Um cluster Postgres 16 (imagem `pgvector/pgvector:pg16`), dois databases:

- **`app`** — `core` (tabelas da aplicação) e `n8n` (dados do n8n), roles separadas
  com `search_path` próprio.
- **`chatwoot`** — database dedicado. O Rails do Chatwoot assume o schema `public`
  e roda as migrations dele por conta própria; forçá-lo para um schema custom
  quebra em upgrade de versão.

A criação de roles, databases, schemas e extensões está em `db/init/`, executado
apenas no primeiro boot do volume. Mudou algo lá? `make reset`.

### Tabelas

`leads` → `conversas` → `mensagens`, mais `qualificacoes` (histórico por lead) e
`imoveis` (catálogo com embedding).

O seed grava `embedding` como `NULL` — gerar 1536 dimensões exigiria a
`OPENAI_API_KEY` já preenchida, o que quebraria o "sobe numa máquina limpa". O
índice HNSW (`vector_cosine_ops`) já existe e se mantém sozinho conforme o
backfill de embeddings rodar pelo n8n.

`imoveis.finalidade` (compra/aluguel) foi adicionada além do escopo original:
sem ela não dá para cruzar o imóvel com `qualificacoes.finalidade` — R$ 4.500 é
aluguel, não venda.

## Configuração pós-boot

1. **n8n** (`https://n8n.localhost`): crie a conta owner no primeiro acesso.
2. **Chatwoot** (`https://chat.localhost`): crie a conta admin, depois a inbox de
   API para o handoff. Copie o access token, o account ID e o inbox ID para as
   variáveis `CHATWOOT_*` do `.env` e rode `make down && make up`.
3. **WhatsApp**: preencha as credenciais da 360dialog ou da Meta Cloud API no
   `.env`. Elas são injetadas no container do n8n como variáveis de ambiente e
   ficam acessíveis nos nodes via `$env` — sem segredo salvo em workflow.

## API do MVP

A API fica em `https://api.localhost` (ou `http://localhost:8080` no perfil de desenvolvimento). O contrato de entrada do n8n para mensagens recebidas é:

```http
POST /api/webhooks/whatsapp
Content-Type: application/json

{"telefone":"5511999999999","nome":"Maria","conteudo":"Procuro apartamento em Moema","providerMessageId":"wamid..."}
```

Principais rotas: `POST /api/leads`, `POST /api/leads/{id}/conversas`, `POST /api/conversas/{id}/mensagens`, `POST /api/leads/{id}/qualificacoes`, `GET /api/imoveis` e `POST /api/conversas/{id}/handoff`. A API não recebe o payload cru de Meta/360dialog: o workflow n8n deve validá-lo e normalizá-lo antes de chamar essa rota.

Em ambiente publicado, defina `API_INTERNAL_TOKEN` e envie o mesmo valor no cabeçalho `X-Internal-Token` dos nós HTTP do n8n. Deixar esse valor vazio é permitido apenas para testes locais.

## Estrutura

```
docker-compose.yml           stack principal
docker-compose.override.yml  perfil de dev (portas diretas)
caddy/Caddyfile              reverse proxy + TLS
db/init/                     roles, databases, schemas, extensões (1º boot)
db/migrations/               schema da aplicação, versionado
db/seed/                     dados de demonstração
scripts/                     migrate.sh e seed.sh (rodam dentro do container)
```
