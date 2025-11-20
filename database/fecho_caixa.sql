-- ===================================
-- SISTEMA DE FECHO DE CAIXA - POSFaturix
-- Baseado em CORRECAO_GUIA_FECHO_CAIXA.md
-- ===================================

-- ===================================
-- TABELA: caixas (CORRIGIDA)
-- ===================================
CREATE TABLE IF NOT EXISTS caixas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    terminal VARCHAR(50),
    usuario VARCHAR(100),
    data_abertura TIMESTAMP NOT NULL,
    data_fechamento TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ABERTO', -- ABERTO, FECHADO

    -- VENDAS PAGAS (dinheiro entrou no caixa)
    total_vendas_pagas DECIMAL(10,2) DEFAULT 0,
    qtd_vendas_pagas INTEGER DEFAULT 0,

    -- Totais por forma de pagamento (vendas + pagamentos de dívidas)
    total_cash DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_cash INTEGER DEFAULT 0,

    total_emola DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_emola INTEGER DEFAULT 0,

    total_mpesa DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_mpesa INTEGER DEFAULT 0,

    total_pos DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_pos INTEGER DEFAULT 0,

    -- VENDAS A CRÉDITO (dinheiro NÃO entrou ainda)
    total_vendas_credito DECIMAL(10,2) DEFAULT 0,
    qtd_vendas_credito INTEGER DEFAULT 0,

    -- PAGAMENTOS DE DÍVIDAS ANTIGAS (dinheiro entrou)
    total_dividas_pagas DECIMAL(10,2) DEFAULT 0,
    qtd_dividas_pagas INTEGER DEFAULT 0,

    -- DESPESAS (dinheiro saiu)
    total_despesas DECIMAL(10,2) DEFAULT 0,
    qtd_despesas INTEGER DEFAULT 0,

    -- SALDO FINAL = (vendas_pagas + dividas_pagas) - despesas
    total_entradas DECIMAL(10,2) DEFAULT 0,
    total_saidas DECIMAL(10,2) DEFAULT 0,
    saldo_final DECIMAL(10,2) DEFAULT 0,

    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_caixas_status ON caixas(status);
CREATE INDEX IF NOT EXISTS idx_caixas_data_abertura ON caixas(data_abertura);
CREATE INDEX IF NOT EXISTS idx_caixas_terminal ON caixas(terminal);
CREATE INDEX IF NOT EXISTS idx_caixas_numero ON caixas(numero);

COMMENT ON TABLE caixas IS 'Controle de abertura e fechamento de caixa com totais detalhados';
COMMENT ON COLUMN caixas.total_vendas_pagas IS 'Soma de vendas pagas (tipo_venda = NORMAL)';
COMMENT ON COLUMN caixas.total_vendas_credito IS 'Soma de vendas a crédito (tipo_venda = DIVIDA) - não entra no saldo';
COMMENT ON COLUMN caixas.total_cash IS 'Soma de TODAS transações em CASH (vendas + pagamentos de dívidas)';
COMMENT ON COLUMN caixas.saldo_final IS 'Dinheiro real em caixa = (vendas_pagas + dividas_pagas) - despesas';

-- ===================================
-- FUNCTION: Calcular Totais do Caixa (CORRIGIDA)
-- ===================================
CREATE OR REPLACE FUNCTION calcular_totais_caixa(p_caixa_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_data_abertura TIMESTAMP;
    v_data_fechamento TIMESTAMP;
    v_total_cash DECIMAL(10,2);
    v_total_emola DECIMAL(10,2);
    v_total_mpesa DECIMAL(10,2);
    v_total_pos DECIMAL(10,2);
BEGIN
    -- Buscar datas do caixa
    SELECT data_abertura, COALESCE(data_fechamento, NOW())
    INTO v_data_abertura, v_data_fechamento
    FROM caixas
    WHERE id = p_caixa_id;

    IF v_data_abertura IS NULL THEN
        RAISE EXCEPTION 'Caixa não encontrado: %', p_caixa_id;
    END IF;

    -- ===================================
    -- 1. VENDAS PAGAS (tipo_venda = 'NORMAL')
    -- ===================================
    UPDATE caixas SET
        total_vendas_pagas = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
        ), 0),
        qtd_vendas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 2. VENDAS A CRÉDITO (tipo_venda = 'DIVIDA')
    -- ===================================
    UPDATE caixas SET
        total_vendas_credito = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'DIVIDA'
        ), 0),
        qtd_vendas_credito = COALESCE((
            SELECT COUNT(*)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'DIVIDA'
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 3. TOTAIS POR FORMA DE PAGAMENTO
    -- (Vendas pagas + Pagamentos de dívidas)
    -- ===================================

    -- 3.1. CASH
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_cash, v_total_pos -- usando v_total_pos temporariamente como contador
    FROM (
        -- Pagamentos de vendas em CASH
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'CASH'

        UNION ALL

        -- Pagamentos de dívidas em CASH
        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'CASH'
    ) AS todos_cash;

    UPDATE caixas SET
        total_cash = v_total_cash,
        qtd_transacoes_cash = v_total_pos -- contador temporário
    WHERE id = p_caixa_id;

    -- 3.2. EMOLA
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_emola, v_total_pos
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'EMOLA'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'EMOLA'
    ) AS todos_emola;

    UPDATE caixas SET
        total_emola = v_total_emola,
        qtd_transacoes_emola = v_total_pos
    WHERE id = p_caixa_id;

    -- 3.3. MPESA
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_mpesa, v_total_pos
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'MPESA'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'MPESA'
    ) AS todos_mpesa;

    UPDATE caixas SET
        total_mpesa = v_total_mpesa,
        qtd_transacoes_mpesa = v_total_pos
    WHERE id = p_caixa_id;

    -- 3.4. POS
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_pos, v_total_cash -- reutilizando variável
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'POS'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'POS'
    ) AS todos_pos;

    UPDATE caixas SET
        total_pos = v_total_pos,
        qtd_transacoes_pos = v_total_cash -- contador temporário
    WHERE id = p_caixa_id;

    -- ===================================
    -- 4. PAGAMENTOS DE DÍVIDAS (TOTAL GERAL)
    -- ===================================
    UPDATE caixas SET
        total_dividas_pagas = COALESCE((
            SELECT SUM(pd.valor)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0),
        qtd_dividas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 5. DESPESAS
    -- ===================================
    UPDATE caixas SET
        total_despesas = COALESCE((
            SELECT SUM(valor)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0),
        qtd_despesas = COALESCE((
            SELECT COUNT(*)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 6. CALCULAR SALDO FINAL
    -- ===================================
    UPDATE caixas SET
        total_entradas = total_vendas_pagas + total_dividas_pagas,
        total_saidas = total_despesas,
        saldo_final = (total_vendas_pagas + total_dividas_pagas) - total_despesas
    WHERE id = p_caixa_id;

    -- ===================================
    -- 7. VALIDAÇÃO (a soma deve bater!)
    -- ===================================
    SELECT
        total_cash + total_emola + total_mpesa + total_pos
    INTO v_total_cash -- reutilizando para validação
    FROM caixas WHERE id = p_caixa_id;

    -- A soma das formas DEVE ser igual ao total de entradas
    -- Se não bater, algo está errado!
    IF ABS(v_total_cash - (SELECT total_entradas FROM caixas WHERE id = p_caixa_id)) > 0.01 THEN
        RAISE WARNING 'ATENÇÃO: Soma das formas (%) diferente do total de entradas (%). Verificar!',
            v_total_cash,
            (SELECT total_entradas FROM caixas WHERE id = p_caixa_id);
    END IF;

END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calcular_totais_caixa IS 'Calcula todos os totais do caixa considerando múltiplas formas de pagamento por venda';

-- ===================================
-- FUNCTION: Abrir Caixa
-- ===================================
CREATE OR REPLACE FUNCTION abrir_caixa(
    p_terminal VARCHAR(50) DEFAULT 'TERMINAL-01',
    p_usuario VARCHAR(100) DEFAULT 'Sistema'
)
RETURNS INTEGER AS $$
DECLARE
    v_caixa_aberto_id INTEGER;
    v_novo_caixa_id INTEGER;
    v_numero VARCHAR(50);
BEGIN
    -- Verificar se já existe caixa aberto
    SELECT id INTO v_caixa_aberto_id
    FROM caixas
    WHERE status = 'ABERTO'
    LIMIT 1;

    IF v_caixa_aberto_id IS NOT NULL THEN
        RAISE EXCEPTION 'Já existe um caixa aberto (ID: %). Feche o caixa antes de abrir um novo.', v_caixa_aberto_id;
    END IF;

    -- Gerar número único do caixa
    v_numero := 'CX' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS');

    -- Inserir novo caixa
    INSERT INTO caixas (numero, terminal, usuario, data_abertura, status)
    VALUES (v_numero, p_terminal, p_usuario, NOW(), 'ABERTO')
    RETURNING id INTO v_novo_caixa_id;

    RAISE NOTICE 'Caixa % aberto com sucesso! ID: %', v_numero, v_novo_caixa_id;

    RETURN v_novo_caixa_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION abrir_caixa IS 'Abre um novo caixa. Impede abertura se já houver caixa aberto.';

-- ===================================
-- FUNCTION: Fechar Caixa
-- ===================================
CREATE OR REPLACE FUNCTION fechar_caixa(
    p_caixa_id INTEGER,
    p_observacoes TEXT DEFAULT NULL
)
RETURNS TABLE(
    sucesso BOOLEAN,
    numero_caixa VARCHAR(50),
    saldo_final_retorno DECIMAL(10,2),
    total_entradas_retorno DECIMAL(10,2),
    total_saidas_retorno DECIMAL(10,2)
) AS $$
DECLARE
    v_status VARCHAR(20);
    v_numero VARCHAR(50);
BEGIN
    -- Verificar se caixa existe
    SELECT status, numero INTO v_status, v_numero
    FROM caixas
    WHERE id = p_caixa_id;

    IF v_numero IS NULL THEN
        RAISE EXCEPTION 'Caixa % não encontrado', p_caixa_id;
    END IF;

    IF v_status = 'FECHADO' THEN
        RAISE EXCEPTION 'Caixa % já está fechado', v_numero;
    END IF;

    -- Calcular todos os totais
    PERFORM calcular_totais_caixa(p_caixa_id);

    -- Fechar o caixa
    UPDATE caixas
    SET status = 'FECHADO',
        data_fechamento = NOW(),
        observacoes = p_observacoes
    WHERE id = p_caixa_id;

    RAISE NOTICE 'Caixa % fechado com sucesso!', v_numero;

    -- Retornar informações do fechamento
    RETURN QUERY
    SELECT
        TRUE,
        c.numero,
        c.saldo_final,
        c.total_entradas,
        c.total_saidas
    FROM caixas c
    WHERE c.id = p_caixa_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fechar_caixa IS 'Fecha o caixa, calcula totais e retorna resumo do fechamento';

-- ===================================
-- VIEW: Caixa Atual (Aberto)
-- ===================================
CREATE OR REPLACE VIEW v_caixa_atual AS
SELECT
    c.*,
    (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) as soma_formas_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN 'OK'
        ELSE 'ERRO: Totais não batem!'
    END as status_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN TRUE
        ELSE FALSE
    END as totais_corretos
FROM caixas c
WHERE c.status = 'ABERTO'
ORDER BY c.data_abertura DESC
LIMIT 1;

COMMENT ON VIEW v_caixa_atual IS 'Retorna o caixa atualmente aberto com validação de totais';

-- ===================================
-- VIEW: Resumo Completo do Caixa
-- ===================================
CREATE OR REPLACE VIEW v_resumo_caixa AS
SELECT
    c.id,
    c.numero,
    c.terminal,
    c.usuario,
    c.status,
    c.data_abertura,
    c.data_fechamento,

    -- VENDAS PAGAS
    c.total_vendas_pagas,
    c.qtd_vendas_pagas,

    -- VENDAS A CRÉDITO (não entra no saldo)
    c.total_vendas_credito,
    c.qtd_vendas_credito,

    -- POR FORMA DE PAGAMENTO
    c.total_cash,
    c.qtd_transacoes_cash,
    c.total_emola,
    c.qtd_transacoes_emola,
    c.total_mpesa,
    c.qtd_transacoes_mpesa,
    c.total_pos,
    c.qtd_transacoes_pos,

    -- PAGAMENTOS DE DÍVIDAS
    c.total_dividas_pagas,
    c.qtd_dividas_pagas,

    -- DESPESAS
    c.total_despesas,
    c.qtd_despesas,

    -- TOTAIS FINAIS
    c.total_entradas,
    c.total_saidas,
    c.saldo_final,

    -- VALIDAÇÃO
    (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) as soma_formas_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN 'OK'
        ELSE 'ERRO'
    END as status_validacao,
    CASE
        WHEN ABS((c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) - c.total_entradas) < 0.01
        THEN TRUE
        ELSE FALSE
    END as totais_corretos,

    c.observacoes,
    c.created_at
FROM caixas c
ORDER BY c.data_abertura DESC;

COMMENT ON VIEW v_resumo_caixa IS 'Resumo completo de todos os caixas com validação';

-- ===================================
-- VIEW: Detalhes de Despesas do Caixa
-- ===================================
CREATE OR REPLACE VIEW v_despesas_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    d.id as despesa_id,
    d.descricao,
    d.valor,
    d.categoria,
    d.data_despesa,
    d.observacoes,
    d.usuario
FROM caixas c
CROSS JOIN despesas d
WHERE d.data_despesa >= c.data_abertura
  AND d.data_despesa <= COALESCE(c.data_fechamento, NOW())
ORDER BY d.data_despesa DESC;

COMMENT ON VIEW v_despesas_caixa IS 'Lista detalhada de despesas por caixa com categoria';

-- ===================================
-- VIEW: Detalhes de Pagamentos de Dívidas do Caixa
-- ===================================
CREATE OR REPLACE VIEW v_pagamentos_divida_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    pd.id as pagamento_id,
    pd.divida_id,
    pd.valor,
    pd.data_pagamento,
    pd.observacoes,
    fp.nome as forma_pagamento,
    cli.nome as cliente_nome,
    cli.contacto as cliente_contacto,
    d.valor_total as divida_total,
    d.valor_pago as divida_pago,
    d.valor_restante as divida_restante
FROM caixas c
CROSS JOIN pagamentos_divida pd
INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
INNER JOIN dividas d ON pd.divida_id = d.id
INNER JOIN clientes cli ON d.cliente_id = cli.id
WHERE pd.data_pagamento >= c.data_abertura
  AND pd.data_pagamento <= COALESCE(c.data_fechamento, NOW())
ORDER BY pd.data_pagamento DESC;

COMMENT ON VIEW v_pagamentos_divida_caixa IS 'Lista detalhada de pagamentos de dívidas por caixa com dados do cliente';

-- ===================================
-- VIEW: Produtos Vendidos no Caixa
-- ===================================
CREATE OR REPLACE VIEW v_produtos_vendidos_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    v.id as venda_id,
    v.numero as venda_numero,
    v.data_venda,
    v.total as venda_total,
    p.id as produto_id,
    p.nome as produto_nome,
    iv.quantidade,
    iv.preco_unitario,
    iv.subtotal,
    (iv.quantidade * iv.preco_unitario) as total_vendido
FROM caixas c
CROSS JOIN vendas v
INNER JOIN itens_venda iv ON v.id = iv.venda_id
INNER JOIN produtos p ON iv.produto_id = p.id
WHERE v.data_venda >= c.data_abertura
  AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
ORDER BY v.data_venda DESC, p.nome;

COMMENT ON VIEW v_produtos_vendidos_caixa IS 'Lista detalhada de produtos vendidos por caixa';

-- ===================================
-- VIEW: Resumo de Produtos Vendidos (Agregado)
-- ===================================
CREATE OR REPLACE VIEW v_resumo_produtos_caixa AS
SELECT
    c.id as caixa_id,
    c.numero as caixa_numero,
    p.id as produto_id,
    p.nome as produto_nome,
    SUM(iv.quantidade) as quantidade_total,
    iv.preco_unitario,
    SUM(iv.subtotal) as total_vendido
FROM caixas c
CROSS JOIN vendas v
INNER JOIN itens_venda iv ON v.id = iv.venda_id
INNER JOIN produtos p ON iv.produto_id = p.id
WHERE v.data_venda >= c.data_abertura
  AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
  AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
GROUP BY c.id, c.numero, p.id, p.nome, iv.preco_unitario
ORDER BY total_vendido DESC;

COMMENT ON VIEW v_resumo_produtos_caixa IS 'Resumo agregado de produtos vendidos por caixa';

-- ===================================
-- TABELA: conferencias_caixa (NOVA - FASE 1)
-- ===================================
CREATE TABLE IF NOT EXISTS conferencias_caixa (
    id SERIAL PRIMARY KEY,
    caixa_id INTEGER NOT NULL REFERENCES caixas(id) ON DELETE CASCADE,

    -- Valores do Sistema
    sistema_cash DECIMAL(10,2) DEFAULT 0,
    sistema_emola DECIMAL(10,2) DEFAULT 0,
    sistema_mpesa DECIMAL(10,2) DEFAULT 0,
    sistema_pos DECIMAL(10,2) DEFAULT 0,
    sistema_total DECIMAL(10,2) DEFAULT 0,

    -- Valores Contados Manualmente
    contado_cash DECIMAL(10,2) DEFAULT 0,
    contado_emola DECIMAL(10,2) DEFAULT 0,
    contado_mpesa DECIMAL(10,2) DEFAULT 0,
    contado_pos DECIMAL(10,2) DEFAULT 0,
    contado_total DECIMAL(10,2) DEFAULT 0,

    -- Diferenças
    diferenca_cash DECIMAL(10,2) DEFAULT 0,
    diferenca_emola DECIMAL(10,2) DEFAULT 0,
    diferenca_mpesa DECIMAL(10,2) DEFAULT 0,
    diferenca_pos DECIMAL(10,2) DEFAULT 0,
    diferenca_total DECIMAL(10,2) DEFAULT 0,

    -- Status
    conferencia_ok BOOLEAN DEFAULT FALSE,
    observacoes TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice
CREATE INDEX IF NOT EXISTS idx_conferencias_caixa_caixa_id ON conferencias_caixa(caixa_id);

COMMENT ON TABLE conferencias_caixa IS 'Registra a conferência manual dos valores ao fechar o caixa (FASE 1)';

-- ===================================
-- FUNCTION: Registrar Conferência Manual
-- ===================================
CREATE OR REPLACE FUNCTION registrar_conferencia_caixa(
    p_caixa_id INTEGER,
    p_contado_cash DECIMAL(10,2) DEFAULT 0,
    p_contado_emola DECIMAL(10,2) DEFAULT 0,
    p_contado_mpesa DECIMAL(10,2) DEFAULT 0,
    p_contado_pos DECIMAL(10,2) DEFAULT 0,
    p_observacoes TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_sistema_cash DECIMAL(10,2);
    v_sistema_emola DECIMAL(10,2);
    v_sistema_mpesa DECIMAL(10,2);
    v_sistema_pos DECIMAL(10,2);
    v_conferencia_id INTEGER;
BEGIN
    -- Buscar valores do sistema
    SELECT
        total_cash,
        total_emola,
        total_mpesa,
        total_pos
    INTO
        v_sistema_cash,
        v_sistema_emola,
        v_sistema_mpesa,
        v_sistema_pos
    FROM caixas
    WHERE id = p_caixa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Caixa não encontrado: %', p_caixa_id;
    END IF;

    -- Inserir conferência
    INSERT INTO conferencias_caixa (
        caixa_id,
        sistema_cash,
        sistema_emola,
        sistema_mpesa,
        sistema_pos,
        sistema_total,
        contado_cash,
        contado_emola,
        contado_mpesa,
        contado_pos,
        contado_total,
        diferenca_cash,
        diferenca_emola,
        diferenca_mpesa,
        diferenca_pos,
        diferenca_total,
        conferencia_ok,
        observacoes
    ) VALUES (
        p_caixa_id,
        v_sistema_cash,
        v_sistema_emola,
        v_sistema_mpesa,
        v_sistema_pos,
        v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos,
        p_contado_cash,
        p_contado_emola,
        p_contado_mpesa,
        p_contado_pos,
        p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos,
        p_contado_cash - v_sistema_cash,
        p_contado_emola - v_sistema_emola,
        p_contado_mpesa - v_sistema_mpesa,
        p_contado_pos - v_sistema_pos,
        (p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos) -
        (v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos),
        (p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos) =
        (v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos),
        p_observacoes
    )
    RETURNING id INTO v_conferencia_id;

    RETURN v_conferencia_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION registrar_conferencia_caixa IS 'Registra a conferência manual dos valores do caixa';

-- ===================================
-- VIEW: Conferências por Caixa
-- ===================================
CREATE OR REPLACE VIEW v_conferencias_caixa AS
SELECT
    cc.*,
    c.numero as caixa_numero,
    c.status as caixa_status,
    c.data_abertura,
    c.data_fechamento
FROM conferencias_caixa cc
INNER JOIN caixas c ON cc.caixa_id = c.id
ORDER BY cc.created_at DESC;

COMMENT ON VIEW v_conferencias_caixa IS 'Lista de conferências com dados do caixa';
