-- Resultado do questionario de qualificacao. Historico: um lead pode ser
-- requalificado (mudou de aluguel para compra, ampliou o orcamento), entao
-- guardamos varias linhas e lemos sempre a mais recente.

CREATE TABLE IF NOT EXISTS qualificacoes (
	id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	lead_id               uuid            NOT NULL REFERENCES leads (id) ON DELETE CASCADE,
	finalidade            finalidade_tipo NOT NULL,
	faixa_preco_min       numeric(12,2),
	faixa_preco_max       numeric(12,2),
	regiao                text,
	urgencia              urgencia_tipo,
	precisa_financiamento boolean,
	-- 0-100, calculado pelo agente a partir de orcamento, urgencia e aderencia.
	score                 smallint,
	qualificado_em        timestamptz     NOT NULL DEFAULT now(),
	CONSTRAINT qualificacoes_faixa_coerente CHECK (
		faixa_preco_min IS NULL OR faixa_preco_max IS NULL OR faixa_preco_min <= faixa_preco_max
	),
	CONSTRAINT qualificacoes_precos_positivos CHECK (
		(faixa_preco_min IS NULL OR faixa_preco_min >= 0) AND
		(faixa_preco_max IS NULL OR faixa_preco_max >= 0)
	),
	CONSTRAINT qualificacoes_score_faixa CHECK (score IS NULL OR score BETWEEN 0 AND 100)
);

-- "Ultima qualificacao deste lead".
CREATE INDEX IF NOT EXISTS qualificacoes_lead_id_qualificado_em_idx
	ON qualificacoes (lead_id, qualificado_em DESC);

-- Ranking de leads quentes para o corretor.
CREATE INDEX IF NOT EXISTS qualificacoes_score_idx
	ON qualificacoes (score DESC NULLS LAST, qualificado_em DESC);
