-- 15 imoveis ficticios em Sao Paulo para a demo.
-- Variam tipo, finalidade, faixa de preco e regiao, cobrindo desde studio de
-- aluguel ate cobertura de alto padrao.
-- embedding fica NULL: o backfill e feito pelo workflow de embeddings do n8n.
-- Idempotente: rodar de novo nao duplica nada.

INSERT INTO imoveis (codigo, titulo, descricao, tipo, finalidade, preco, quartos, vagas, bairro, cidade) VALUES
	('AP-1001',
	 'Apartamento 2 dormitorios em Pinheiros',
	 'Apartamento de 68 m2 com 2 dormitorios, sendo 1 suite, sala com varanda integrada e cozinha americana. Predio de 2019 com academia, coworking e portaria 24h. A 400 m da estacao Fradique Coutinho do metro.',
	 'apartamento', 'compra', 890000.00, 2, 1, 'Pinheiros', 'São Paulo'),

	('ST-1002',
	 'Studio mobiliado na Vila Madalena',
	 'Studio de 32 m2 totalmente mobiliado, com cozinha equipada, ar-condicionado e internet inclusa. Condominio com lavanderia compartilhada e rooftop. Ideal para solteiros que trabalham em casa. Aceita pet de pequeno porte.',
	 'studio', 'aluguel', 3200.00, 1, 0, 'Vila Madalena', 'São Paulo'),

	('CA-1003',
	 'Casa terrea com piscina no Alto de Pinheiros',
	 'Casa terrea de 420 m2 em terreno de 700 m2, com 4 suites, escritorio, sala de cinema e piscina aquecida. Jardim projetado, churrasqueira e edicula com dependencia completa. Rua arborizada e tranquila.',
	 'casa', 'compra', 3400000.00, 4, 4, 'Alto de Pinheiros', 'São Paulo'),

	('AP-1004',
	 'Apartamento 3 dormitorios em Moema',
	 'Apartamento de 110 m2 com 3 dormitorios, 1 suite, living em dois ambientes e varanda gourmet com churrasqueira. Andar alto, face norte, vista livre para o Parque Ibirapuera. Condominio com piscina e quadra.',
	 'apartamento', 'compra', 1450000.00, 3, 2, 'Moema', 'São Paulo'),

	('CO-1005',
	 'Cobertura duplex no Itaim Bibi',
	 'Cobertura duplex de 280 m2 com 4 suites, terraco privativo com piscina e vista panoramica da cidade. Acabamento em marmore, automacao completa e adega climatizada. Condominio boutique com apenas 12 unidades.',
	 'cobertura', 'compra', 4900000.00, 4, 4, 'Itaim Bibi', 'São Paulo'),

	('AP-1006',
	 'Apartamento 2 dormitorios no Tatuape',
	 'Apartamento de 58 m2 com 2 dormitorios, sala ampla e cozinha planejada. Predio com playground, salao de festas e piscina. A 900 m da estacao Carrao do metro e proximo ao Shopping Analia Franco.',
	 'apartamento', 'compra', 620000.00, 2, 1, 'Tatuapé', 'São Paulo'),

	('AP-1007',
	 'Apartamento para alugar na Vila Mariana',
	 'Apartamento de 72 m2 com 2 dormitorios, armarios embutidos e piso laminado novo. Predio com portaria 24h, bicicletario e area de lazer. Duas quadras da estacao Ana Rosa, com acesso as linhas verde e azul.',
	 'apartamento', 'aluguel', 4800.00, 2, 1, 'Vila Mariana', 'São Paulo'),

	('SO-1008',
	 'Sobrado 3 dormitorios em Santana',
	 'Sobrado de 160 m2 com 3 dormitorios, 1 suite, quintal com churrasqueira e garagem coberta para 2 carros. Rua residencial calma, proxima ao Parque da Juventude e a estacao Carandiru.',
	 'sobrado', 'compra', 780000.00, 3, 2, 'Santana', 'São Paulo'),

	('AP-1009',
	 'Apartamento 3 dormitorios em Perdizes',
	 'Apartamento de 96 m2 com 3 dormitorios, 1 suite, dependencia de empregada e varanda. Predio tradicional bem conservado, com portaria 24h. Proximo a PUC-SP, ao Allianz Parque e a diversas escolas.',
	 'apartamento', 'compra', 1150000.00, 3, 2, 'Perdizes', 'São Paulo'),

	('ST-1010',
	 'Studio compacto na Bela Vista',
	 'Studio de 26 m2 sem vaga, com cozinha compacta e janela ampla. Condominio com portaria remota e baixo custo mensal. Localizacao central, a 5 minutos a pe da Avenida Paulista e do metro Brigadeiro.',
	 'studio', 'aluguel', 2400.00, 1, 0, 'Bela Vista', 'São Paulo'),

	('AP-1011',
	 'Apartamento alto padrao para alugar no Brooklin',
	 'Apartamento de 140 m2 com 3 suites, home office e varanda gourmet fechada com vidro. Condominio com piscina coberta, academia e espaco pet. Proximo ao polo empresarial da Berrini e a ponte Estaiada.',
	 'apartamento', 'aluguel', 7500.00, 3, 2, 'Brooklin', 'São Paulo'),

	('CA-1012',
	 'Casa em condominio fechado no Butanta',
	 'Casa de 180 m2 em condominio fechado com 3 dormitorios, sendo 1 suite, quintal gramado e area gourmet. Condominio com seguranca 24h, quadra e area verde. Acesso rapido a Marginal Pinheiros e a USP.',
	 'casa', 'compra', 950000.00, 3, 2, 'Butantã', 'São Paulo'),

	('AP-1013',
	 'Apartamento amplo em Higienopolis',
	 'Apartamento de 190 m2 com 4 dormitorios, 2 suites, living em tres ambientes e lavabo. Predio classico da regiao, com apenas dois apartamentos por andar. Ao lado do Parque Buenos Aires e de otimas escolas.',
	 'apartamento', 'compra', 2100000.00, 4, 3, 'Higienópolis', 'São Paulo'),

	('CM-1014',
	 'Sala comercial na Cidade Moncoes',
	 'Sala comercial de 85 m2 em laje corporativa, com piso elevado, ar-condicionado central e copa. Predio com certificacao ambiental, seguranca 24h e estacionamento rotativo para visitantes. Regiao da Berrini.',
	 'comercial', 'aluguel', 6200.00, 0, 2, 'Cidade Monções', 'São Paulo'),

	('AP-1015',
	 'Apartamento 2 dormitorios na Mooca',
	 'Apartamento de 54 m2 com 2 dormitorios e sala com varanda. Predio novo com piscina, churrasqueira e salao de jogos. Bom custo-beneficio na regiao, a 1,2 km da estacao Bresser-Mooca do metro.',
	 'apartamento', 'compra', 540000.00, 2, 1, 'Mooca', 'São Paulo')
ON CONFLICT (codigo) DO NOTHING;
