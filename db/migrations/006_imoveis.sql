-- Catalogo de imoveis. O embedding cobre titulo + descricao e alimenta a busca
-- semantica do agente ("apartamento perto do metro com varanda gourmet").

CREATE TABLE IF NOT EXISTS imoveis (
	id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	-- Codigo interno da imobiliaria, o que o corretor usa no dia a dia.
	codigo        text            NOT NULL,
	titulo        text            NOT NULL,
	descricao     text,
	tipo          imovel_tipo     NOT NULL,
	-- Adicionado alem do escopo pedido: sem isso nao da para cruzar o imovel
	-- com qualificacoes.finalidade (um preco de 4.500 e aluguel, nao venda).
	finalidade    finalidade_tipo NOT NULL DEFAULT 'compra',
	preco         numeric(12,2)   NOT NULL,
	quartos       smallint,
	vagas         smallint,
	bairro        text            NOT NULL,
	cidade        text            NOT NULL DEFAULT 'São Paulo',
	ativo         boolean         NOT NULL DEFAULT true,
	-- text-embedding-3-small (1536 dims). NULL ate o job de embedding rodar.
	embedding     vector(1536),
	criado_em     timestamptz     NOT NULL DEFAULT now(),
	atualizado_em timestamptz     NOT NULL DEFAULT now(),
	CONSTRAINT imoveis_preco_positivo CHECK (preco > 0),
	CONSTRAINT imoveis_quartos_valido CHECK (quartos IS NULL OR quartos BETWEEN 0 AND 20),
	CONSTRAINT imoveis_vagas_valido   CHECK (vagas   IS NULL OR vagas   BETWEEN 0 AND 20)
);

CREATE UNIQUE INDEX IF NOT EXISTS imoveis_codigo_key ON imoveis (codigo);

-- Filtro estruturado aplicado antes da busca semantica.
CREATE INDEX IF NOT EXISTS imoveis_busca_idx
	ON imoveis (cidade, bairro, finalidade, tipo, preco)
	WHERE ativo;

CREATE INDEX IF NOT EXISTS imoveis_preco_idx ON imoveis (preco) WHERE ativo;

-- Busca por bairro digitado errado ("moema", "vl madalena").
CREATE INDEX IF NOT EXISTS imoveis_bairro_trgm_idx ON imoveis USING gin (bairro gin_trgm_ops);

-- Indice vetorial: HNSW com distancia por cosseno (operador <=>).
-- Construir HNSW com a tabela vazia e barato e o indice se mantem sozinho
-- conforme os embeddings sao preenchidos.
CREATE INDEX IF NOT EXISTS imoveis_embedding_hnsw_idx
	ON imoveis USING hnsw (embedding vector_cosine_ops)
	WITH (m = 16, ef_construction = 64);

DROP TRIGGER IF EXISTS imoveis_set_atualizado_em ON imoveis;
CREATE TRIGGER imoveis_set_atualizado_em
	BEFORE UPDATE ON imoveis
	FOR EACH ROW EXECUTE FUNCTION set_atualizado_em();
