-- Extensoes e tipos base do schema da aplicacao.
-- As extensoes ja sao criadas pelo init (exigem superusuario); os IF NOT EXISTS
-- deixam esta migration idempotente caso o database seja restaurado de dump.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Status do lead no funil.
DO $$ BEGIN
	CREATE TYPE lead_status AS ENUM (
		'novo',          -- entrou pelo WhatsApp, ainda sem interacao util
		'em_atendimento',-- agente conduzindo a conversa
		'qualificado',   -- passou pelo questionario e tem score
		'handoff',       -- transferido para corretor humano
		'descartado',    -- fora do perfil ou sem resposta
		'convertido'     -- visita agendada / negocio fechado
	);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Origem do lead (canal de captacao).
DO $$ BEGIN
	CREATE TYPE lead_origem AS ENUM ('whatsapp', 'site', 'portal', 'indicacao', 'anuncio', 'outro');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Estagio do handoff para o corretor humano.
DO $$ BEGIN
	CREATE TYPE handoff_status AS ENUM (
		'bot',        -- agente respondendo sozinho
		'solicitado', -- gatilho de transferencia disparado
		'humano',     -- corretor assumiu a conversa
		'devolvido'   -- corretor devolveu para o agente
	);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Papel da mensagem no historico do LLM.
DO $$ BEGIN
	CREATE TYPE mensagem_papel AS ENUM ('user', 'assistant', 'system');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
	CREATE TYPE finalidade_tipo AS ENUM ('compra', 'aluguel');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
	CREATE TYPE urgencia_tipo AS ENUM ('imediata', 'ate_3_meses', 'ate_6_meses', 'sem_pressa');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
	CREATE TYPE imovel_tipo AS ENUM ('apartamento', 'casa', 'studio', 'cobertura', 'sobrado', 'terreno', 'comercial');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Mantem atualizado_em coerente sem depender da aplicacao.
CREATE OR REPLACE FUNCTION set_atualizado_em() RETURNS trigger AS $$
BEGIN
	NEW.atualizado_em := now();
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
