-- ===================================
-- SCRIPT: Gerar 600 Produtos
-- 300 produtos de COZINHA (não-contáveis)
-- 300 produtos de BAR (contáveis)
-- ===================================

-- ===================================
-- PREPARAÇÃO: Buscar IDs de Setores e Áreas
-- ===================================

-- Assumindo:
-- RESTAURANTE = setor id 1
-- BAR = area id 1
-- COZINHA = area id 2

DO $$
DECLARE
    v_setor_restaurante INTEGER;
    v_area_bar INTEGER;
    v_area_cozinha INTEGER;
    v_familia_id INTEGER;
    v_contador INTEGER;
    v_nome_produto TEXT;
    v_preco_compra DECIMAL(10,2);
    v_preco_venda DECIMAL(10,2);
    v_estoque INTEGER;

    -- Arrays de famílias
    v_familias_comida INTEGER[];
    v_familias_bebida INTEGER[];
BEGIN
    -- Buscar IDs
    SELECT id INTO v_setor_restaurante FROM setores WHERE nome = 'RESTAURANTE' LIMIT 1;
    SELECT id INTO v_area_bar FROM areas WHERE nome = 'BAR' LIMIT 1;
    SELECT id INTO v_area_cozinha FROM areas WHERE nome = 'COZINHA' LIMIT 1;

    -- Buscar famílias de COMIDAS
    SELECT ARRAY_AGG(id) INTO v_familias_comida
    FROM familias
    WHERE nome IN (
        'ENTRADAS', 'SALADAS', 'SOPAS', 'MASSAS', 'PIZZAS',
        'HAMBÚRGUERES', 'CARNES GRELHADAS', 'PEIXES E MARISCOS',
        'PRATOS TRADICIONAIS', 'PRATOS VEGETARIANOS',
        'ARROZ E ACOMPANHAMENTOS', 'WRAPS E TACOS', 'PETISCOS',
        'SOBREMESAS', 'CREPES E PANQUECAS', 'COMIDA ASIÁTICA',
        'GRELHADOS NO CARVÃO', 'INFANTIL', 'PEQUENO-ALMOÇO',
        'PRATOS EXECUTIVOS'
    );

    -- Buscar famílias de BEBIDAS
    SELECT ARRAY_AGG(id) INTO v_familias_bebida
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
    );

    -- ===================================
    -- 1. GERAR 300 PRODUTOS DE COZINHA (NÃO-CONTÁVEIS)
    -- ===================================

    RAISE NOTICE 'Gerando 300 produtos de COZINHA (não-contáveis)...';

    FOR v_contador IN 1..300 LOOP
        -- Selecionar família aleatória de comidas
        v_familia_id := v_familias_comida[1 + floor(random() * array_length(v_familias_comida, 1))::int];

        -- Gerar nome do produto
        v_nome_produto := 'PRATO COZINHA ' || LPAD(v_contador::TEXT, 3, '0');

        -- Gerar preços aleatórios
        v_preco_compra := 50 + (random() * 150)::DECIMAL(10,2);
        v_preco_venda := v_preco_compra * (1.5 + random() * 0.5); -- Margem 50-100%

        -- Inserir produto (NÃO-CONTÁVEL, sem estoque)
        INSERT INTO produtos (
            nome,
            familia_id,
            preco,
            preco_compra,
            estoque,
            contavel,
            iva,
            setor_id,
            area_id,
            ativo
        ) VALUES (
            v_nome_produto,
            v_familia_id,
            ROUND(v_preco_venda, 2),
            ROUND(v_preco_compra, 2),
            0, -- Estoque 0 (não-contável)
            false, -- NÃO contável
            CASE WHEN random() > 0.8 THEN 'Isento' ELSE 'Incluso' END,
            v_setor_restaurante,
            v_area_cozinha,
            true
        );
    END LOOP;

    RAISE NOTICE '✓ 300 produtos de COZINHA criados!';

    -- ===================================
    -- 2. GERAR 300 PRODUTOS DE BAR (CONTÁVEIS)
    -- ===================================

    RAISE NOTICE 'Gerando 300 produtos de BAR (contáveis)...';

    FOR v_contador IN 1..300 LOOP
        -- Selecionar família aleatória de bebidas
        v_familia_id := v_familias_bebida[1 + floor(random() * array_length(v_familias_bebida, 1))::int];

        -- Gerar nome do produto
        v_nome_produto := 'BEBIDA BAR ' || LPAD(v_contador::TEXT, 3, '0');

        -- Gerar preços aleatórios
        v_preco_compra := 20 + (random() * 100)::DECIMAL(10,2);
        v_preco_venda := v_preco_compra * (1.8 + random() * 0.7); -- Margem 80-150%

        -- Gerar estoque aleatório
        v_estoque := 10 + floor(random() * 200)::int;

        -- Inserir produto (CONTÁVEL, com estoque)
        INSERT INTO produtos (
            nome,
            familia_id,
            preco,
            preco_compra,
            estoque,
            contavel,
            iva,
            setor_id,
            area_id,
            ativo
        ) VALUES (
            v_nome_produto,
            v_familia_id,
            ROUND(v_preco_venda, 2),
            ROUND(v_preco_compra, 2),
            v_estoque,
            true, -- CONTÁVEL
            CASE WHEN random() > 0.9 THEN 'Isento' ELSE 'Incluso' END,
            v_setor_restaurante,
            v_area_bar,
            true
        );
    END LOOP;

    RAISE NOTICE '✓ 300 produtos de BAR criados!';
    RAISE NOTICE '✓ Total: 600 produtos gerados com sucesso!';

END $$;

-- ===================================
-- VERIFICAÇÃO
-- ===================================

-- Contar produtos criados
SELECT
    CASE
        WHEN contavel THEN 'BAR (Contável)'
        ELSE 'COZINHA (Não-Contável)'
    END as tipo,
    COUNT(*) as total,
    AVG(preco_compra) as preco_compra_medio,
    AVG(preco) as preco_venda_medio,
    SUM(estoque) as estoque_total
FROM produtos
GROUP BY contavel;

-- Produtos por área
SELECT
    a.nome as area,
    COUNT(p.id) as total_produtos,
    SUM(CASE WHEN p.contavel THEN 1 ELSE 0 END) as contaveis,
    SUM(CASE WHEN NOT p.contavel THEN 1 ELSE 0 END) as nao_contaveis
FROM areas a
LEFT JOIN produtos p ON a.id = p.area_id
WHERE a.nome IN ('BAR', 'COZINHA')
GROUP BY a.nome;

-- Distribuição por família (top 10)
SELECT
    f.nome as familia,
    COUNT(p.id) as total_produtos,
    ROUND(AVG(p.preco), 2) as preco_medio
FROM familias f
LEFT JOIN produtos p ON f.id = p.familia_id
WHERE p.id IS NOT NULL
GROUP BY f.nome
ORDER BY total_produtos DESC
LIMIT 10;

-- Ver alguns produtos criados
SELECT
    codigo,
    nome,
    CASE WHEN contavel THEN 'Sim' ELSE 'Não' END as contavel,
    preco_compra,
    preco as preco_venda,
    estoque,
    iva
FROM produtos
WHERE nome LIKE 'PRATO COZINHA%' OR nome LIKE 'BEBIDA BAR%'
ORDER BY codigo
LIMIT 20;

-- ===================================
-- ESTATÍSTICAS FINAIS
-- ===================================

SELECT
    '=== RESUMO GERAL ===' as info;

SELECT
    'Total de Produtos' as metrica,
    COUNT(*)::TEXT as valor
FROM produtos
UNION ALL
SELECT
    'Produtos Contáveis (BAR)',
    COUNT(*)::TEXT
FROM produtos
WHERE contavel = true AND area_id = (SELECT id FROM areas WHERE nome = 'BAR' LIMIT 1)
UNION ALL
SELECT
    'Produtos Não-Contáveis (COZINHA)',
    COUNT(*)::TEXT
FROM produtos
WHERE contavel = false AND area_id = (SELECT id FROM areas WHERE nome = 'COZINHA' LIMIT 1)
UNION ALL
SELECT
    'Estoque Total (apenas contáveis)',
    SUM(estoque)::TEXT
FROM produtos
WHERE contavel = true;

-- ===================================
-- NOTAS
-- ===================================
-- 1. Códigos gerados automaticamente pelo trigger
-- 2. Produtos de COZINHA: NÃO-CONTÁVEIS (estoque = 0)
-- 3. Produtos de BAR: CONTÁVEIS (estoque entre 10-210)
-- 4. Preços variam aleatoriamente
-- 5. Margem de lucro: COZINHA 50-100%, BAR 80-150%
-- 6. 80-90% têm IVA Incluso, 10-20% Isento
-- 7. Distribuídos entre as 40 famílias criadas
-- ===================================
