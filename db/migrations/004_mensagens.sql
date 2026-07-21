-- Historico da conversa no formato que vai direto para o contexto do LLM.

CREATE TABLE IF NOT EXISTS mensagens (
	id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	conversa_id uuid           NOT NULL REFERENCES conversas (id) ON DELETE CASCADE,
	papel       mensagem_papel NOT NULL,
	conteudo    text           NOT NULL,
	"timestamp" timestamptz    NOT NULL DEFAULT now(),
	-- Tokens consumidos na chamada que gerou a mensagem (NULL para 'user').
	tokens      integer,
	-- ID da mensagem no provedor (wamid), para deduplicar reentrega de webhook.
	provider_message_id text,
	CONSTRAINT mensagens_tokens_nao_negativo CHECK (tokens IS NULL OR tokens >= 0)
);

-- Acesso dominante: montar o contexto em ordem cronologica.
CREATE INDEX IF NOT EXISTS mensagens_conversa_id_timestamp_idx ON mensagens (conversa_id, "timestamp");

-- O WhatsApp reenvia webhooks; o wamid e a chave de idempotencia.
CREATE UNIQUE INDEX IF NOT EXISTS mensagens_provider_message_id_key
	ON mensagens (provider_message_id) WHERE provider_message_id IS NOT NULL;
