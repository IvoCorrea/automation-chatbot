-- Conversa: uma sessao de atendimento do lead. Um lead pode voltar semanas
-- depois e abrir uma nova conversa; o historico antigo fica encerrado.

CREATE TABLE IF NOT EXISTS conversas (
	id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	lead_id         uuid           NOT NULL REFERENCES leads (id) ON DELETE CASCADE,
	iniciada_em     timestamptz    NOT NULL DEFAULT now(),
	encerrada_em    timestamptz,
	status_handoff  handoff_status NOT NULL DEFAULT 'bot',
	-- ID da conversa correspondente no Chatwoot, preenchido no handoff.
	chatwoot_conversation_id integer,
	CONSTRAINT conversas_periodo_valido CHECK (encerrada_em IS NULL OR encerrada_em >= iniciada_em)
);

-- Busca padrao: "ultima conversa deste lead".
CREATE INDEX IF NOT EXISTS conversas_lead_id_iniciada_em_idx ON conversas (lead_id, iniciada_em DESC);

-- Garante no maximo uma conversa aberta por lead.
CREATE UNIQUE INDEX IF NOT EXISTS conversas_lead_aberta_key
	ON conversas (lead_id) WHERE encerrada_em IS NULL;

-- Fila do corretor: conversas aguardando ou em atendimento humano.
CREATE INDEX IF NOT EXISTS conversas_handoff_abertas_idx
	ON conversas (status_handoff, iniciada_em DESC)
	WHERE encerrada_em IS NULL;

-- Resolve o webhook do Chatwoot de volta para a conversa local.
CREATE UNIQUE INDEX IF NOT EXISTS conversas_chatwoot_conversation_id_key
	ON conversas (chatwoot_conversation_id) WHERE chatwoot_conversation_id IS NOT NULL;
