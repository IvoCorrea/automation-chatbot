-- Lead: uma pessoa unica, identificada pelo telefone do WhatsApp.

CREATE TABLE IF NOT EXISTS leads (
	id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	-- E.164 sem o "+", como chega no webhook do WhatsApp (ex: 5511987654321).
	telefone      text        NOT NULL,
	nome          text,
	criado_em     timestamptz NOT NULL DEFAULT now(),
	atualizado_em timestamptz NOT NULL DEFAULT now(),
	status        lead_status NOT NULL DEFAULT 'novo',
	origem        lead_origem NOT NULL DEFAULT 'whatsapp',
	-- Payload cru do provedor (profile name, wa_id, referral de anuncio).
	metadados     jsonb       NOT NULL DEFAULT '{}'::jsonb,
	CONSTRAINT leads_telefone_formato CHECK (telefone ~ '^[0-9]{10,15}$')
);

-- Chave natural: o webhook faz upsert por telefone a cada mensagem recebida.
CREATE UNIQUE INDEX IF NOT EXISTS leads_telefone_key ON leads (telefone);

-- Filtro do painel do corretor ("quem esta em handoff agora").
CREATE INDEX IF NOT EXISTS leads_status_criado_em_idx ON leads (status, criado_em DESC);

DROP TRIGGER IF EXISTS leads_set_atualizado_em ON leads;
CREATE TRIGGER leads_set_atualizado_em
	BEFORE UPDATE ON leads
	FOR EACH ROW EXECUTE FUNCTION set_atualizado_em();
