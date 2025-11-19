-- ===================================
-- SCRIPT: Inserir 40 Famílias de Restaurante
-- 20 Famílias de Comidas + 20 Famílias de Bebidas
-- Todas associadas aos setores RESTAURANTE e ARMAZÉM
-- ===================================

-- ===================================
-- 1. FAMÍLIAS DE COMIDAS (20)
-- ===================================

-- Limpar dados de teste anteriores (opcional - comente se não quiser limpar)
-- DELETE FROM familia_setores;
-- DELETE FROM familias WHERE id > 3;

INSERT INTO familias (nome, descricao, ativo) VALUES
-- Comidas
('ENTRADAS', 'Entradas e aperitivos', true),
('SALADAS', 'Saladas variadas', true),
('SOPAS', 'Sopas quentes e frias', true),
('MASSAS', 'Massas e pastas italianas', true),
('PIZZAS', 'Pizzas tradicionais e especiais', true),
('HAMBÚRGUERES', 'Hambúrgueres e sanduíches', true),
('CARNES GRELHADAS', 'Carnes bovinas, suínas e de aves grelhadas', true),
('PEIXES E MARISCOS', 'Pratos de peixe e frutos do mar', true),
('PRATOS TRADICIONAIS', 'Pratos típicos moçambicanos', true),
('PRATOS VEGETARIANOS', 'Opções vegetarianas e veganas', true),
('ARROZ E ACOMPANHAMENTOS', 'Arroz, batatas e guarnições', true),
('WRAPS E TACOS', 'Wraps, tacos e tortilhas', true),
('PETISCOS', 'Petiscos para compartilhar', true),
('SOBREMESAS', 'Doces e sobremesas', true),
('CREPES E PANQUECAS', 'Crepes doces e salgados', true),
('COMIDA ASIÁTICA', 'Pratos orientais variados', true),
('GRELHADOS NO CARVÃO', 'Especialidades grelhadas no carvão', true),
('INFANTIL', 'Menu infantil', true),
('PEQUENO-ALMOÇO', 'Opções de café da manhã', true),
('PRATOS EXECUTIVOS', 'Pratos do dia e executivos', true);

-- ===================================
-- 2. FAMÍLIAS DE BEBIDAS (20)
-- ===================================

INSERT INTO familias (nome, descricao, ativo) VALUES
-- Bebidas
('REFRIGERANTES', 'Refrigerantes e sodas', true),
('ÁGUAS', 'Água mineral com e sem gás', true),
('SUMOS NATURAIS', 'Sucos naturais de frutas', true),
('SUMOS INDUSTRIALIZADOS', 'Sucos de caixa e embalados', true),
('CERVEJAS NACIONAIS', 'Cervejas produzidas em Moçambique', true),
('CERVEJAS IMPORTADAS', 'Cervejas internacionais', true),
('VINHOS TINTOS', 'Vinhos tintos nacionais e importados', true),
('VINHOS BRANCOS', 'Vinhos brancos e rosés', true),
('BEBIDAS ENERGÉTICAS', 'Energéticos e isotônicos', true),
('CHÁ E INFUSÕES', 'Chás quentes e gelados', true),
('CAFÉ', 'Café expresso, cappuccino e variações', true),
('BATIDOS E SMOOTHIES', 'Batidos de frutas e smoothies', true),
('COCKTAILS COM ÁLCOOL', 'Cocktails e drinks alcoólicos', true),
('COCKTAILS SEM ÁLCOOL', 'Mocktails e bebidas virgens', true),
('LICORES E DIGESTIVOS', 'Licores e bebidas digestivas', true),
('DESTILADOS', 'Whisky, vodka, gin, rum', true),
('CHAMPANHES E ESPUMANTES', 'Champanhes e vinhos espumantes', true),
('BEBIDAS QUENTES', 'Chocolate quente e bebidas de inverno', true),
('ÁGUAS SABORIZADAS', 'Águas com sabor', true),
('BEBIDAS TRADICIONAIS', 'Bebidas típicas moçambicanas', true);

-- ===================================
-- 3. ASSOCIAR TODAS AS FAMÍLIAS AOS SETORES
-- Associa aos setores RESTAURANTE (id=1) e ARMAZÉM (id=2)
-- ===================================

-- Buscar os IDs das famílias recém-criadas e associar aos setores
-- Assumindo que RESTAURANTE tem id=1 e ARMAZÉM tem id=2

-- Associar ao setor RESTAURANTE (id=1)
INSERT INTO familia_setores (familia_id, setor_id)
SELECT id, 1
FROM familias
WHERE nome IN (
    -- Comidas
    'ENTRADAS', 'SALADAS', 'SOPAS', 'MASSAS', 'PIZZAS',
    'HAMBÚRGUERES', 'CARNES GRELHADAS', 'PEIXES E MARISCOS',
    'PRATOS TRADICIONAIS', 'PRATOS VEGETARIANOS',
    'ARROZ E ACOMPANHAMENTOS', 'WRAPS E TACOS', 'PETISCOS',
    'SOBREMESAS', 'CREPES E PANQUECAS', 'COMIDA ASIÁTICA',
    'GRELHADOS NO CARVÃO', 'INFANTIL', 'PEQUENO-ALMOÇO',
    'PRATOS EXECUTIVOS',
    -- Bebidas
    'REFRIGERANTES', 'ÁGUAS', 'SUMOS NATURAIS',
    'SUMOS INDUSTRIALIZADOS', 'CERVEJAS NACIONAIS',
    'CERVEJAS IMPORTADAS', 'VINHOS TINTOS', 'VINHOS BRANCOS',
    'BEBIDAS ENERGÉTICAS', 'CHÁ E INFUSÕES', 'CAFÉ',
    'BATIDOS E SMOOTHIES', 'COCKTAILS COM ÁLCOOL',
    'COCKTAILS SEM ÁLCOOL', 'LICORES E DIGESTIVOS',
    'DESTILADOS', 'CHAMPANHES E ESPUMANTES', 'BEBIDAS QUENTES',
    'ÁGUAS SABORIZADAS', 'BEBIDAS TRADICIONAIS'
)
ON CONFLICT (familia_id, setor_id) DO NOTHING;

-- Associar ao setor ARMAZÉM (id=2)
INSERT INTO familia_setores (familia_id, setor_id)
SELECT id, 2
FROM familias
WHERE nome IN (
    -- Comidas
    'ENTRADAS', 'SALADAS', 'SOPAS', 'MASSAS', 'PIZZAS',
    'HAMBÚRGUERES', 'CARNES GRELHADAS', 'PEIXES E MARISCOS',
    'PRATOS TRADICIONAIS', 'PRATOS VEGETARIANOS',
    'ARROZ E ACOMPANHAMENTOS', 'WRAPS E TACOS', 'PETISCOS',
    'SOBREMESAS', 'CREPES E PANQUECAS', 'COMIDA ASIÁTICA',
    'GRELHADOS NO CARVÃO', 'INFANTIL', 'PEQUENO-ALMOÇO',
    'PRATOS EXECUTIVOS',
    -- Bebidas
    'REFRIGERANTES', 'ÁGUAS', 'SUMOS NATURAIS',
    'SUMOS INDUSTRIALIZADOS', 'CERVEJAS NACIONAIS',
    'CERVEJAS IMPORTADAS', 'VINHOS TINTOS', 'VINHOS BRANCOS',
    'BEBIDAS ENERGÉTICAS', 'CHÁ E INFUSÕES', 'CAFÉ',
    'BATIDOS E SMOOTHIES', 'COCKTAILS COM ÁLCOOL',
    'COCKTAILS SEM ÁLCOOL', 'LICORES E DIGESTIVOS',
    'DESTILADOS', 'CHAMPANHES E ESPUMANTES', 'BEBIDAS QUENTES',
    'ÁGUAS SABORIZADAS', 'BEBIDAS TRADICIONAIS'
)
ON CONFLICT (familia_id, setor_id) DO NOTHING;

-- ===================================
-- 4. VERIFICAÇÃO
-- ===================================

-- Contar famílias criadas
SELECT COUNT(*) as total_familias FROM familias WHERE ativo = true;

-- Ver todas as famílias com seus setores
SELECT * FROM v_familias_com_setores
ORDER BY nome;

-- Contar associações
SELECT COUNT(*) as total_associacoes FROM familia_setores;

-- Ver resumo por setor
SELECT
    s.nome as setor,
    COUNT(fs.familia_id) as total_familias
FROM setores s
LEFT JOIN familia_setores fs ON s.id = fs.setor_id
GROUP BY s.id, s.nome
ORDER BY s.nome;

-- Ver famílias de comidas (primeiras 20)
SELECT id, nome, descricao
FROM familias
WHERE nome IN (
    'ENTRADAS', 'SALADAS', 'SOPAS', 'MASSAS', 'PIZZAS',
    'HAMBÚRGUERES', 'CARNES GRELHADAS', 'PEIXES E MARISCOS',
    'PRATOS TRADICIONAIS', 'PRATOS VEGETARIANOS',
    'ARROZ E ACOMPANHAMENTOS', 'WRAPS E TACOS', 'PETISCOS',
    'SOBREMESAS', 'CREPES E PANQUECAS', 'COMIDA ASIÁTICA',
    'GRELHADOS NO CARVÃO', 'INFANTIL', 'PEQUENO-ALMOÇO',
    'PRATOS EXECUTIVOS'
)
ORDER BY nome;

-- Ver famílias de bebidas (últimas 20)
SELECT id, nome, descricao
FROM familias
WHERE nome IN (
    'REFRIGERANTES', 'ÁGUAS', 'SUMOS NATURAIS',
    'SUMOS INDUSTRIALIZADOS', 'CERVEJAS NACIONAIS',
    'CERVEJAS IMPORTADAS', 'VINHOS TINTOS', 'VINHOS BRANCOS',
    'BEBIDAS ENERGÉTICAS', 'CHÁ E INFUSÕES', 'CAFÉ',
    'BATIDOS E SMOOTHIES', 'COCKTAILS COM ÁLCOOL',
    'COCKTAILS SEM ÁLCOOL', 'LICORES E DIGESTIVOS',
    'DESTILADOS', 'CHAMPANHES E ESPUMANTES', 'BEBIDAS QUENTES',
    'ÁGUAS SABORIZADAS', 'BEBIDAS TRADICIONAIS'
)
ORDER BY nome;

-- ===================================
-- NOTAS IMPORTANTES
-- ===================================
-- 1. Este script cria 40 famílias:
--    - 20 famílias de COMIDAS
--    - 20 famílias de BEBIDAS
--
-- 2. Todas as famílias são associadas a 2 setores:
--    - RESTAURANTE (id=1)
--    - ARMAZÉM (id=2)
--
-- 3. Total de associações criadas: 40 famílias × 2 setores = 80 associações
--
-- 4. Execute APÓS ter executado:
--    - database/familia_setores_migration.sql
--    - E ter os setores RESTAURANTE e ARMAZÉM cadastrados
--
-- 5. Se os IDs dos setores forem diferentes de 1 e 2:
--    - Ajuste os números nos INSERTs da seção 3
--    - Consulte: SELECT id, nome FROM setores;
-- ===================================
