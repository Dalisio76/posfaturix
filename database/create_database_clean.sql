-- =====================================================
-- POSFATURIX - BASE DE DADOS LIMPA E COMPLETA
-- =====================================================
-- Este arquivo cria toda a estrutura da base de dados do zero
-- Inclui todas as tabelas, índices, funções, views e migrations aplicadas
--
-- Data de Criação: 05/12/2025
-- Versão: 2.0
--
-- INSTRUÇÕES:
-- 1. Criar base de dados: CREATE DATABASE pdv_system WITH ENCODING='UTF8';
-- 2. Conectar à base de dados criada
-- 3. Executar este script completo
--
-- NOTA: Collation será a padrão do sistema (funciona em qualquer país)
-- =====================================================

-- Limpar se já existir (CUIDADO! Remove tudo)
-- DROP SCHEMA public CASCADE;
-- CREATE SCHEMA public;

-- =====================================================
-- PARTE 1: ESTRUTURA BASE (PRODUTOS E VENDAS)
-- =====================================================

-- TABELA: familias (categorias de produtos)
CREATE TABLE IF NOT EXISTS familias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: setores (departamentos/setores de produtos)
CREATE TABLE IF NOT EXISTS setores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: areas (áreas de venda)
CREATE TABLE IF NOT EXISTS areas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: produtos
CREATE TABLE IF NOT EXISTS produtos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    codigo_barras VARCHAR(50),
    nome VARCHAR(200) NOT NULL,
    familia_id INTEGER REFERENCES familias(id) ON DELETE SET NULL,
    setor_id INTEGER REFERENCES setores(id) ON DELETE SET NULL,
    area_id INTEGER REFERENCES areas(id) ON DELETE SET NULL,
    preco DECIMAL(10,2) NOT NULL,
    preco_custo DECIMAL(10,2) DEFAULT 0,
    estoque INTEGER DEFAULT 0,
    estoque_minimo INTEGER DEFAULT 0,
    unidade_medida VARCHAR(20) DEFAULT 'UN',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: composicao_produtos (produtos compostos)
CREATE TABLE IF NOT EXISTS composicao_produtos (
    id SERIAL PRIMARY KEY,
    produto_pai_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    produto_componente_id INTEGER NOT NULL REFERENCES produtos(id) ON DELETE CASCADE,
    quantidade DECIMAL(10,3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(produto_pai_id, produto_componente_id)
);

-- TABELA: vendas
CREATE TABLE IF NOT EXISTS vendas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    numero_venda INTEGER,
    total DECIMAL(10,2) NOT NULL,
    data_venda TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    terminal VARCHAR(50),
    cliente_id INTEGER,
    usuario_id INTEGER,
    status VARCHAR(20) DEFAULT 'finalizada',
    observacoes TEXT,
    CONSTRAINT chk_vendas_status CHECK (status IN ('finalizada', 'cancelada'))
);

-- TABELA: itens_venda
CREATE TABLE IF NOT EXISTS itens_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    produto_id INTEGER REFERENCES produtos(id),
    quantidade INTEGER NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

-- TABELA: formas_pagamento
CREATE TABLE IF NOT EXISTS formas_pagamento (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    tipo VARCHAR(20) DEFAULT 'DINHEIRO',
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: pagamentos_venda
CREATE TABLE IF NOT EXISTS pagamentos_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER REFERENCES vendas(id) ON DELETE CASCADE,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    valor DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PARTE 2: SISTEMA DE USUÁRIOS E PERMISSÕES
-- =====================================================

-- TABELA: perfis_usuario
CREATE TABLE IF NOT EXISTS perfis_usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    descricao TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    codigo VARCHAR(8) NOT NULL UNIQUE,
    perfil_id INTEGER REFERENCES perfis_usuario(id),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: permissoes
CREATE TABLE IF NOT EXISTS permissoes (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(50),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: perfil_permissoes
CREATE TABLE IF NOT EXISTS perfil_permissoes (
    id SERIAL PRIMARY KEY,
    perfil_id INTEGER NOT NULL REFERENCES perfis_usuario(id) ON DELETE CASCADE,
    permissao_id INTEGER NOT NULL REFERENCES permissoes(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(perfil_id, permissao_id)
);

-- =====================================================
-- PARTE 3: CLIENTES E FORNECEDORES
-- =====================================================

-- TABELA: clientes
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nuit VARCHAR(50),
    telefone VARCHAR(50),
    email VARCHAR(200),
    endereco TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: fornecedores
CREATE TABLE IF NOT EXISTS fornecedores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    nuit VARCHAR(50),
    telefone VARCHAR(50),
    email VARCHAR(200),
    endereco TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PARTE 4: SISTEMA DE CAIXA
-- =====================================================

-- TABELA: caixas
CREATE TABLE IF NOT EXISTS caixas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) NOT NULL,
    terminal VARCHAR(100),
    usuario VARCHAR(200),
    data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_fechamento TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ABERTO',

    -- Totais de vendas pagas (dinheiro entrou)
    total_vendas_pagas DECIMAL(10,2) DEFAULT 0,
    qtd_vendas_pagas INTEGER DEFAULT 0,

    -- Totais por forma de pagamento
    total_cash DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_cash INTEGER DEFAULT 0,
    total_emola DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_emola INTEGER DEFAULT 0,
    total_mpesa DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_mpesa INTEGER DEFAULT 0,
    total_pos DECIMAL(10,2) DEFAULT 0,
    qtd_transacoes_pos INTEGER DEFAULT 0,

    -- Vendas a crédito (não entrou dinheiro)
    total_vendas_credito DECIMAL(10,2) DEFAULT 0,
    qtd_vendas_credito INTEGER DEFAULT 0,

    -- Pagamentos de dívidas (dinheiro entrou)
    total_dividas_pagas DECIMAL(10,2) DEFAULT 0,
    qtd_dividas_pagas INTEGER DEFAULT 0,

    -- Despesas (dinheiro saiu)
    total_despesas DECIMAL(10,2) DEFAULT 0,
    qtd_despesas INTEGER DEFAULT 0,

    -- Saldo final
    total_entradas DECIMAL(10,2) DEFAULT 0,
    total_saidas DECIMAL(10,2) DEFAULT 0,
    saldo_final DECIMAL(10,2) DEFAULT 0,

    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_caixas_status CHECK (status IN ('ABERTO', 'FECHADO'))
);

-- TABELA: dividas (contas a receber de clientes)
CREATE TABLE IF NOT EXISTS dividas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    venda_id INTEGER REFERENCES vendas(id),
    valor_total DECIMAL(10,2) NOT NULL,
    valor_pago DECIMAL(10,2) DEFAULT 0,
    saldo_devedor DECIMAL(10,2) NOT NULL,
    data_divida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'PENDENTE',
    observacoes TEXT,
    CONSTRAINT chk_dividas_status CHECK (status IN ('PENDENTE', 'PAGA', 'PARCIAL'))
);

-- TABELA: pagamentos_divida
CREATE TABLE IF NOT EXISTS pagamentos_divida (
    id SERIAL PRIMARY KEY,
    divida_id INTEGER NOT NULL REFERENCES dividas(id) ON DELETE CASCADE,
    caixa_id INTEGER REFERENCES caixas(id),
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    valor DECIMAL(10,2) NOT NULL,
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT
);

-- TABELA: despesas
CREATE TABLE IF NOT EXISTS despesas (
    id SERIAL PRIMARY KEY,
    caixa_id INTEGER REFERENCES caixas(id),
    descricao VARCHAR(200) NOT NULL,
    categoria VARCHAR(100),
    valor DECIMAL(10,2) NOT NULL,
    data_despesa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT
);

-- TABELA: conferencias_caixa (conferência manual do caixa)
CREATE TABLE IF NOT EXISTS conferencias_caixa (
    id SERIAL PRIMARY KEY,
    caixa_id INTEGER NOT NULL REFERENCES caixas(id),
    contado_cash DECIMAL(10,2) DEFAULT 0,
    contado_emola DECIMAL(10,2) DEFAULT 0,
    contado_mpesa DECIMAL(10,2) DEFAULT 0,
    contado_pos DECIMAL(10,2) DEFAULT 0,
    diferenca_cash DECIMAL(10,2) DEFAULT 0,
    diferenca_emola DECIMAL(10,2) DEFAULT 0,
    diferenca_mpesa DECIMAL(10,2) DEFAULT 0,
    diferenca_pos DECIMAL(10,2) DEFAULT 0,
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PARTE 5: FATURAS DE ENTRADA (STOCK)
-- =====================================================

-- TABELA: faturas_entrada
CREATE TABLE IF NOT EXISTS faturas_entrada (
    id SERIAL PRIMARY KEY,
    numero_fatura VARCHAR(100) NOT NULL,
    fornecedor_id INTEGER REFERENCES fornecedores(id),
    data_fatura DATE NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABELA: itens_fatura_entrada
CREATE TABLE IF NOT EXISTS itens_fatura_entrada (
    id SERIAL PRIMARY KEY,
    fatura_id INTEGER NOT NULL REFERENCES faturas_entrada(id) ON DELETE CASCADE,
    produto_id INTEGER NOT NULL REFERENCES produtos(id),
    quantidade DECIMAL(10,3) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL
);

-- TABELA: acertos_stock (ajustes manuais de estoque)
CREATE TABLE IF NOT EXISTS acertos_stock (
    id SERIAL PRIMARY KEY,
    produto_id INTEGER NOT NULL REFERENCES produtos(id),
    quantidade_anterior INTEGER NOT NULL,
    quantidade_nova INTEGER NOT NULL,
    diferenca INTEGER NOT NULL,
    motivo VARCHAR(200),
    observacoes TEXT,
    usuario_id INTEGER REFERENCES usuarios(id),
    data_acerto TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- PARTE 6: ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Produtos
CREATE INDEX IF NOT EXISTS idx_produtos_familia ON produtos(familia_id);
CREATE INDEX IF NOT EXISTS idx_produtos_setor ON produtos(setor_id);
CREATE INDEX IF NOT EXISTS idx_produtos_area ON produtos(area_id);
CREATE INDEX IF NOT EXISTS idx_produtos_ativo ON produtos(ativo);
CREATE INDEX IF NOT EXISTS idx_produtos_codigo_barras ON produtos(codigo_barras);
CREATE INDEX IF NOT EXISTS idx_produtos_estoque_baixo ON produtos(estoque_minimo) WHERE estoque < estoque_minimo;

-- Vendas
CREATE INDEX IF NOT EXISTS idx_vendas_data ON vendas(data_venda);
CREATE INDEX IF NOT EXISTS idx_vendas_status ON vendas(status);
CREATE INDEX IF NOT EXISTS idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_vendas_usuario ON vendas(usuario_id);
CREATE INDEX IF NOT EXISTS idx_vendas_numero_venda ON vendas(numero_venda) WHERE numero_venda IS NOT NULL;

-- Itens Venda
CREATE INDEX IF NOT EXISTS idx_itens_venda ON itens_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_itens_produto ON itens_venda(produto_id);

-- Pagamentos
CREATE INDEX IF NOT EXISTS idx_pagamentos_venda ON pagamentos_venda(venda_id);

-- Usuários e Permissões
CREATE INDEX IF NOT EXISTS idx_usuarios_codigo ON usuarios(codigo);
CREATE INDEX IF NOT EXISTS idx_usuarios_perfil ON usuarios(perfil_id);
CREATE INDEX IF NOT EXISTS idx_perfil_permissoes_perfil ON perfil_permissoes(perfil_id);
CREATE INDEX IF NOT EXISTS idx_perfil_permissoes_permissao ON perfil_permissoes(permissao_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_codigo ON permissoes(codigo);
CREATE INDEX IF NOT EXISTS idx_permissoes_categoria ON permissoes(categoria);

-- Caixas
CREATE INDEX IF NOT EXISTS idx_caixas_status ON caixas(status);
CREATE INDEX IF NOT EXISTS idx_caixas_data_abertura ON caixas(data_abertura DESC);

-- Dívidas
CREATE INDEX IF NOT EXISTS idx_dividas_cliente ON dividas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_dividas_status ON dividas(status);
CREATE INDEX IF NOT EXISTS idx_pagamentos_divida_divida ON pagamentos_divida(divida_id);
CREATE INDEX IF NOT EXISTS idx_pagamentos_divida_caixa ON pagamentos_divida(caixa_id);

-- Despesas
CREATE INDEX IF NOT EXISTS idx_despesas_caixa ON despesas(caixa_id);
CREATE INDEX IF NOT EXISTS idx_despesas_data ON despesas(data_despesa);

-- Faturas
CREATE INDEX IF NOT EXISTS idx_faturas_entrada_fornecedor ON faturas_entrada(fornecedor_id);
CREATE INDEX IF NOT EXISTS idx_itens_fatura_entrada_fatura ON itens_fatura_entrada(fatura_id);
CREATE INDEX IF NOT EXISTS idx_itens_fatura_entrada_produto ON itens_fatura_entrada(produto_id);

-- =====================================================
-- PARTE 7: FUNÇÕES DO SISTEMA
-- =====================================================

-- Função: Obter próximo número sequencial de venda
CREATE OR REPLACE FUNCTION obter_proximo_numero_venda()
RETURNS INTEGER AS $$
DECLARE
    proximo_numero INTEGER;
BEGIN
    SELECT COALESCE(MAX(numero_venda), 0) + 1
    INTO proximo_numero
    FROM vendas;

    RETURN proximo_numero;
END;
$$ LANGUAGE plpgsql;

-- Função: Abater estoque de produto (considera composição)
CREATE OR REPLACE FUNCTION abater_estoque_produto(
    p_produto_id INTEGER,
    p_quantidade INTEGER
)
RETURNS VOID AS $$
DECLARE
    v_componente RECORD;
BEGIN
    -- Abater estoque do produto principal
    UPDATE produtos
    SET estoque = estoque - p_quantidade
    WHERE id = p_produto_id;

    -- Abater estoque dos componentes (se for produto composto)
    FOR v_componente IN
        SELECT produto_componente_id, quantidade
        FROM composicao_produtos
        WHERE produto_pai_id = p_produto_id
    LOOP
        UPDATE produtos
        SET estoque = estoque - (v_componente.quantidade * p_quantidade)
        WHERE id = v_componente.produto_componente_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Função: Abrir caixa
CREATE OR REPLACE FUNCTION abrir_caixa(
    p_terminal VARCHAR(100),
    p_usuario VARCHAR(200)
)
RETURNS INTEGER AS $$
DECLARE
    v_caixa_id INTEGER;
    v_numero VARCHAR(50);
BEGIN
    -- Gerar número do caixa
    SELECT 'CX' || LPAD((COALESCE(MAX(id), 0) + 1)::TEXT, 6, '0')
    INTO v_numero
    FROM caixas;

    -- Criar novo caixa
    INSERT INTO caixas (numero, terminal, usuario, status)
    VALUES (v_numero, p_terminal, p_usuario, 'ABERTO')
    RETURNING id INTO v_caixa_id;

    RETURN v_caixa_id;
END;
$$ LANGUAGE plpgsql;

-- Função: Calcular totais do caixa
CREATE OR REPLACE FUNCTION calcular_totais_caixa(p_caixa_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_caixa RECORD;
BEGIN
    SELECT data_abertura, data_fechamento
    INTO v_caixa
    FROM caixas
    WHERE id = p_caixa_id;

    IF v_caixa IS NULL THEN
        RAISE EXCEPTION 'Caixa não encontrado';
    END IF;

    -- Calcular totais de vendas por forma de pagamento
    WITH vendas_periodo AS (
        SELECT v.id, v.total, pv.forma_pagamento_id, pv.valor, fp.tipo
        FROM vendas v
        LEFT JOIN pagamentos_venda pv ON v.id = pv.venda_id
        LEFT JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_caixa.data_abertura
          AND (v_caixa.data_fechamento IS NULL OR v.data_venda <= v_caixa.data_fechamento)
          AND v.status = 'finalizada'
    )
    UPDATE caixas SET
        total_cash = COALESCE((SELECT SUM(valor) FROM vendas_periodo WHERE tipo = 'CASH'), 0),
        qtd_transacoes_cash = COALESCE((SELECT COUNT(DISTINCT id) FROM vendas_periodo WHERE tipo = 'CASH'), 0),
        total_emola = COALESCE((SELECT SUM(valor) FROM vendas_periodo WHERE tipo = 'EMOLA'), 0),
        qtd_transacoes_emola = COALESCE((SELECT COUNT(DISTINCT id) FROM vendas_periodo WHERE tipo = 'EMOLA'), 0),
        total_mpesa = COALESCE((SELECT SUM(valor) FROM vendas_periodo WHERE tipo = 'MPESA'), 0),
        qtd_transacoes_mpesa = COALESCE((SELECT COUNT(DISTINCT id) FROM vendas_periodo WHERE tipo = 'MPESA'), 0),
        total_pos = COALESCE((SELECT SUM(valor) FROM vendas_periodo WHERE tipo = 'POS'), 0),
        qtd_transacoes_pos = COALESCE((SELECT COUNT(DISTINCT id) FROM vendas_periodo WHERE tipo = 'POS'), 0)
    WHERE id = p_caixa_id;

    -- Calcular totais de despesas
    UPDATE caixas SET
        total_despesas = COALESCE((
            SELECT SUM(valor)
            FROM despesas
            WHERE caixa_id = p_caixa_id
        ), 0),
        qtd_despesas = COALESCE((
            SELECT COUNT(*)
            FROM despesas
            WHERE caixa_id = p_caixa_id
        ), 0)
    WHERE id = p_caixa_id;

    -- Calcular totais de pagamentos de dívidas
    UPDATE caixas SET
        total_dividas_pagas = COALESCE((
            SELECT SUM(valor)
            FROM pagamentos_divida
            WHERE caixa_id = p_caixa_id
        ), 0),
        qtd_dividas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM pagamentos_divida
            WHERE caixa_id = p_caixa_id
        ), 0)
    WHERE id = p_caixa_id;

    -- Calcular saldo final
    UPDATE caixas SET
        total_entradas = total_cash + total_emola + total_mpesa + total_pos + total_dividas_pagas,
        total_saidas = total_despesas,
        saldo_final = (total_cash + total_emola + total_mpesa + total_pos + total_dividas_pagas) - total_despesas
    WHERE id = p_caixa_id;
END;
$$ LANGUAGE plpgsql;

-- Função: Fechar caixa
CREATE OR REPLACE FUNCTION fechar_caixa(
    p_caixa_id INTEGER,
    p_observacoes TEXT DEFAULT NULL
)
RETURNS TABLE(
    sucesso BOOLEAN,
    numero_caixa VARCHAR,
    saldo_final DECIMAL,
    total_entradas DECIMAL,
    total_saidas DECIMAL
) AS $$
DECLARE
    v_caixa RECORD;
BEGIN
    -- Calcular totais antes de fechar
    PERFORM calcular_totais_caixa(p_caixa_id);

    -- Atualizar status e data de fechamento
    UPDATE caixas SET
        status = 'FECHADO',
        data_fechamento = CURRENT_TIMESTAMP,
        observacoes = COALESCE(observacoes || E'\n\n', '') || COALESCE(p_observacoes, '')
    WHERE id = p_caixa_id
    RETURNING * INTO v_caixa;

    -- Retornar resultado
    RETURN QUERY SELECT
        TRUE as sucesso,
        v_caixa.numero,
        v_caixa.saldo_final,
        v_caixa.total_entradas,
        v_caixa.total_saidas;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- PARTE 8: VIEWS DO SISTEMA
-- =====================================================

-- View: Resumo do caixa
CREATE OR REPLACE VIEW v_resumo_caixa AS
SELECT
    c.*,
    (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos) as soma_formas_validacao,
    CASE
        WHEN c.total_entradas = (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos + c.total_dividas_pagas) THEN 'OK'
        ELSE 'DIVERGENTE'
    END as status_validacao,
    (c.total_entradas = (c.total_cash + c.total_emola + c.total_mpesa + c.total_pos + c.total_dividas_pagas)) as totais_corretos
FROM caixas c;

-- View: Caixa atual (aberto)
CREATE OR REPLACE VIEW v_caixa_atual AS
SELECT * FROM caixas WHERE status = 'ABERTO' ORDER BY data_abertura DESC LIMIT 1;

-- View: Produtos com informações completas
CREATE OR REPLACE VIEW v_produtos_completo AS
SELECT
    p.*,
    f.nome as familia_nome,
    s.nome as setor_nome,
    a.nome as area_nome,
    CASE
        WHEN p.estoque = 0 THEN 'SEM STOCK'
        WHEN p.estoque < p.estoque_minimo * 0.3 THEN 'CRITICO'
        WHEN p.estoque < p.estoque_minimo * 0.6 THEN 'BAIXO'
        WHEN p.estoque < p.estoque_minimo THEN 'ALERTA'
        ELSE 'OK'
    END as nivel_stock,
    CASE
        WHEN p.estoque_minimo > 0 THEN ROUND((p.estoque::DECIMAL / p.estoque_minimo * 100), 2)
        ELSE 100
    END as percentual_stock
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id;

-- View: Vendas com informações completas
CREATE OR REPLACE VIEW v_vendas_completo AS
SELECT
    v.*,
    c.nome as cliente_nome,
    u.nome as usuario_nome,
    COUNT(iv.id) as total_itens
FROM vendas v
LEFT JOIN clientes c ON v.cliente_id = c.id
LEFT JOIN usuarios u ON v.usuario_id = u.id
LEFT JOIN itens_venda iv ON v.id = iv.venda_id
GROUP BY v.id, v.numero, v.numero_venda, v.total, v.data_venda, v.terminal,
         v.cliente_id, v.usuario_id, v.status, v.observacoes, c.nome, u.nome;

-- View: Produtos com stock baixo
CREATE OR REPLACE VIEW v_produtos_stock_baixo AS
SELECT
    p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    f.nome as familia_nome,
    p.setor_id,
    s.nome as setor_nome,
    p.estoque,
    p.estoque_minimo,
    CASE
        WHEN p.estoque_minimo > 0 THEN ROUND((p.estoque::DECIMAL / p.estoque_minimo * 100), 2)
        ELSE 100
    END as percentual,
    CASE
        WHEN p.estoque = 0 THEN 'SEM STOCK'
        WHEN p.estoque < p.estoque_minimo * 0.3 THEN 'CRITICO'
        WHEN p.estoque < p.estoque_minimo * 0.6 THEN 'BAIXO'
        WHEN p.estoque < p.estoque_minimo THEN 'ALERTA'
    END as nivel
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
WHERE p.estoque < p.estoque_minimo AND p.ativo = true;

-- =====================================================
-- PARTE 9: DADOS INICIAIS
-- =====================================================

-- Perfis de usuário
INSERT INTO perfis_usuario (nome, descricao) VALUES
    ('Super Administrador', 'Acesso total ao sistema'),
    ('Administrador', 'Administrador com acesso a relatórios e configurações'),
    ('Gerente', 'Gerente com acesso a relatórios'),
    ('Operador', 'Operador de caixa básico'),
    ('Vendedor', 'Vendedor sem acesso administrativo')
ON CONFLICT (nome) DO NOTHING;

-- Permissões do sistema
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    -- Vendas
    ('efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas'),
    ('fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa'),
    ('cancelar_venda', 'Cancelar Venda', 'VENDAS', 'Permitir cancelar vendas'),
    ('imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas'),

    -- Stock
    ('entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock'),
    ('acerto_stock', 'Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock'),
    ('ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock'),
    ('gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada'),

    -- Cadastros
    ('gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos'),
    ('gestao_familias', 'Gestão de Famílias', 'CADASTROS', 'Permitir criar e editar famílias'),
    ('gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes'),
    ('gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores'),
    ('gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores'),
    ('gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas'),

    -- Financeiro
    ('gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas'),
    ('gestao_dividas', 'Gestão de Dívidas', 'FINANCEIRO', 'Permitir registar e gerenciar dívidas'),
    ('gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento'),

    -- Relatórios
    ('visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais'),
    ('visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros'),
    ('visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock'),

    -- Administração
    ('acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração'),
    ('gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários'),
    ('gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis'),
    ('gestao_permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil'),
    ('configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais'),
    ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa')
ON CONFLICT (codigo) DO NOTHING;

-- Dar todas as permissões ao Super Administrador e Administrador
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    id
FROM permissoes
WHERE ativo = true
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
    id
FROM permissoes
WHERE ativo = true
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- Formas de pagamento padrão
INSERT INTO formas_pagamento (nome, tipo) VALUES
    ('Dinheiro', 'CASH'),
    ('Emola', 'EMOLA'),
    ('M-Pesa', 'MPESA'),
    ('POS/Cartão', 'POS'),
    ('Transferência', 'TRANSFERENCIA'),
    ('Crédito', 'CREDITO')
ON CONFLICT DO NOTHING;

-- USUÁRIO SUPER ADMINISTRADOR PADRÃO
-- Nome: Admin
-- Código: 0000
INSERT INTO usuarios (nome, codigo, perfil_id) VALUES
    ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'))
ON CONFLICT (codigo) DO UPDATE SET nome = 'Admin', ativo = true;

-- Famílias de produtos padrão
INSERT INTO familias (nome, descricao) VALUES
    ('BEBIDAS', 'Bebidas em geral'),
    ('COMIDAS', 'Pratos e lanches'),
    ('SOBREMESAS', 'Doces e sobremesas'),
    ('PETISCOS', 'Petiscos e aperitivos'),
    ('OUTROS', 'Outros produtos')
ON CONFLICT DO NOTHING;

-- Setores padrão
INSERT INTO setores (nome, descricao) VALUES
    ('BAR', 'Bar e bebidas'),
    ('COZINHA', 'Cozinha e pratos quentes'),
    ('CONFEITARIA', 'Doces e sobremesas'),
    ('DIVERSOS', 'Produtos diversos')
ON CONFLICT DO NOTHING;

-- =====================================================
-- COMENTÁRIOS NAS TABELAS E COLUNAS
-- =====================================================

COMMENT ON TABLE produtos IS 'Tabela de produtos do sistema';
COMMENT ON COLUMN produtos.estoque_minimo IS 'Quantidade mínima de estoque antes de alertar';
COMMENT ON COLUMN produtos.codigo_barras IS 'Código de barras do produto para leitura';

COMMENT ON TABLE vendas IS 'Tabela de vendas realizadas';
COMMENT ON COLUMN vendas.numero IS 'Número legado/técnico da venda (mantido para compatibilidade)';
COMMENT ON COLUMN vendas.numero_venda IS 'Número sequencial simples da venda (1, 2, 3...)';

COMMENT ON TABLE caixas IS 'Tabela de controle de caixas (abertura e fecho)';
COMMENT ON TABLE dividas IS 'Contas a receber de clientes (vendas a crédito)';
COMMENT ON TABLE despesas IS 'Despesas registradas no caixa';

COMMENT ON FUNCTION obter_proximo_numero_venda() IS 'Retorna o próximo número sequencial disponível para uma venda';
COMMENT ON FUNCTION abater_estoque_produto(INTEGER, INTEGER) IS 'Abate estoque do produto e seus componentes (se for produto composto)';
COMMENT ON FUNCTION abrir_caixa(VARCHAR, VARCHAR) IS 'Abre um novo caixa e retorna o ID';
COMMENT ON FUNCTION calcular_totais_caixa(INTEGER) IS 'Calcula e atualiza todos os totais do caixa';
COMMENT ON FUNCTION fechar_caixa(INTEGER, TEXT) IS 'Fecha o caixa e retorna o resumo final';

-- =====================================================
-- FIM DO SCRIPT
-- =====================================================
-- Base de dados criada com sucesso!
--
-- PRÓXIMOS PASSOS:
-- 1. Verificar se todas as tabelas foram criadas: \dt
-- 2. Verificar views: \dv
-- 3. Verificar funções: \df
-- 4. Fazer login com: admin@sistema.com / admin123
-- 5. IMPORTANTE: Mudar a senha padrão!
-- =====================================================

SELECT 'BASE DE DADOS CRIADA COM SUCESSO!' as status;
SELECT COUNT(*) || ' tabelas criadas' as info FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
SELECT COUNT(*) || ' views criadas' as info FROM information_schema.views WHERE table_schema = 'public';
SELECT COUNT(*) || ' funções criadas' as info FROM information_schema.routines WHERE routine_schema = 'public';
