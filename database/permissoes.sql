-- ===================================
-- SISTEMA DE PERMISSÕES
-- ===================================

-- ===================================
-- 1. CRIAR TABELA PERMISSOES
-- ===================================
CREATE TABLE IF NOT EXISTS permissoes (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) NOT NULL UNIQUE,
    nome VARCHAR(200) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(50),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================================
-- 2. CRIAR TABELA PERFIL_PERMISSOES
-- ===================================
CREATE TABLE IF NOT EXISTS perfil_permissoes (
    id SERIAL PRIMARY KEY,
    perfil_id INTEGER NOT NULL REFERENCES perfis_usuario(id) ON DELETE CASCADE,
    permissao_id INTEGER NOT NULL REFERENCES permissoes(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(perfil_id, permissao_id)
);

-- ===================================
-- 3. ÍNDICES PARA PERFORMANCE
-- ===================================
CREATE INDEX IF NOT EXISTS idx_perfil_permissoes_perfil ON perfil_permissoes(perfil_id);
CREATE INDEX IF NOT EXISTS idx_perfil_permissoes_permissao ON perfil_permissoes(permissao_id);
CREATE INDEX IF NOT EXISTS idx_permissoes_codigo ON permissoes(codigo);
CREATE INDEX IF NOT EXISTS idx_permissoes_categoria ON permissoes(categoria);

-- ===================================
-- 4. INSERIR PERMISSÕES DO SISTEMA
-- ===================================

-- Permissões de Vendas/Caixa
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas'),
    ('fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa'),
    ('imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas de clientes'),
    ('imprimir_cotacao', 'Imprimir Cotação', 'VENDAS', 'Permitir imprimir cotações'),
    ('unir_contas', 'Unir Contas', 'VENDAS', 'Permitir juntar contas de mesas')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Stock
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock'),
    ('acerto_stock', 'Notificar Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock'),
    ('transferencia_stock', 'Transferência de Stock', 'STOCK', 'Permitir transferir stock entre setores'),
    ('ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock'),
    ('reportar_stock_critico', 'Reportar Stock Crítico', 'STOCK', 'Permitir gerar relatório de stock crítico'),
    ('reportar_variacao_stock', 'Reportar Variação de Stock', 'STOCK', 'Permitir gerar relatório de variação de stock')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Cadastros
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('registar_produtos', 'Registar Produtos', 'CADASTROS', 'Permitir criar e editar produtos'),
    ('registar_familias', 'Registar Famílias', 'CADASTROS', 'Permitir criar e editar famílias de produtos'),
    ('registar_promocoes', 'Registar Promoções', 'CADASTROS', 'Permitir criar e editar promoções'),
    ('registar_unidades_medida', 'Registar Unidades de Medida', 'CADASTROS', 'Permitir criar unidades de medida'),
    ('registar_encomenda', 'Registar Encomenda', 'CADASTROS', 'Permitir criar encomendas'),
    ('registar_fornecedores', 'Registar Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores'),
    ('registar_clientes', 'Registar Clientes', 'CADASTROS', 'Permitir criar e editar clientes'),
    ('registar_setores', 'Registar Setores', 'CADASTROS', 'Permitir criar e editar setores')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Financeiro
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('registar_despesas', 'Registar Despesas', 'FINANCEIRO', 'Permitir registar despesas'),
    ('registar_divida', 'Registar Dívida', 'FINANCEIRO', 'Permitir registar dívidas de clientes'),
    ('notificar_despesas', 'Notificar Despesas', 'FINANCEIRO', 'Permitir visualizar notificações de despesas'),
    ('notificar_pagamentos_mes', 'Notificar Pagamentos Mês', 'FINANCEIRO', 'Permitir ver pagamentos mensais')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Relatórios
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('relatorios', 'Relatórios', 'RELATORIOS', 'Permitir acesso a relatórios gerais'),
    ('reportar_margens_email', 'Reportar Margens (E-mail)', 'RELATORIOS', 'Permitir enviar relatório de margens por email'),
    ('reportar_margens_fecho', 'Reportar Margens (Fecho)', 'RELATORIOS', 'Permitir ver margens no fecho de caixa'),
    ('notificar_margens_mes', 'Notificar Margens Mês', 'RELATORIOS', 'Permitir ver margens mensais'),
    ('relatorio_vendas', 'Relatório de Vendas', 'RELATORIOS', 'Permitir ver relatório de vendas'),
    ('relatorio_faturas', 'Relatório de Faturas', 'RELATORIOS', 'Permitir ver relatório de faturas de entrada')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Administração
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração'),
    ('gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários'),
    ('gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis de usuários'),
    ('gestao_permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil'),
    ('configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões de Notificações
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('enviar_notificacoes', 'Enviar Notificações', 'NOTIFICACOES', 'Permitir enviar notificações'),
    ('notificar_entrada_stock', 'Notificar Entrada de Stock', 'NOTIFICACOES', 'Permitir visualizar notificações de entrada de stock'),
    ('notificar_registo_produto', 'Notificar Registo de Produto', 'NOTIFICACOES', 'Permitir visualizar notificações de novos produtos')
ON CONFLICT (codigo) DO NOTHING;

-- Permissões Diversas
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    ('registar_consumo_interno', 'Registar Consumo Interno', 'DIVERSOS', 'Permitir registar consumo interno de produtos'),
    ('guias_saida', 'Guias de Saída', 'DIVERSOS', 'Permitir gerar guias de saída')
ON CONFLICT (codigo) DO NOTHING;

-- ===================================
-- 5. CRIAR PERFIL SUPER ADMINISTRADOR
-- ===================================
INSERT INTO perfis_usuario (nome, descricao) VALUES
    ('Super Administrador', 'Acesso total a todas as funcionalidades do sistema')
ON CONFLICT (nome) DO NOTHING;

-- ===================================
-- 6. ATRIBUIR TODAS AS PERMISSÕES AO SUPER ADMINISTRADOR
-- ===================================
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    id
FROM permissoes
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 7. ATRIBUIR PERMISSÕES BÁSICAS AO ADMINISTRADOR
-- ===================================
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
    id
FROM permissoes
WHERE categoria IN ('ADMIN', 'RELATORIOS', 'CADASTROS', 'FINANCEIRO')
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 8. ATRIBUIR PERMISSÕES AO CAIXA
-- ===================================
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Caixa'),
    id
FROM permissoes
WHERE codigo IN ('efectuar_pagamento', 'imprimir_conta', 'imprimir_cotacao', 'unir_contas', 'fechar_caixa', 'registar_clientes')
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 9. ATRIBUIR PERMISSÕES AO ESTOQUISTA
-- ===================================
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Estoquista'),
    id
FROM permissoes
WHERE categoria = 'STOCK' OR codigo IN ('registar_produtos', 'registar_familias')
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 10. ATRIBUIR PERMISSÕES AO GERENTE
-- ===================================
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Gerente'),
    id
FROM permissoes
WHERE categoria IN ('RELATORIOS', 'VENDAS', 'STOCK', 'FINANCEIRO')
ON CONFLICT (perfil_id, permissao_id) DO NOTHING;

-- ===================================
-- 11. VIEW PARA CONSULTAR PERMISSÕES POR PERFIL
-- ===================================
CREATE OR REPLACE VIEW v_perfil_permissoes AS
SELECT
    p.id as perfil_id,
    p.nome as perfil_nome,
    perm.id as permissao_id,
    perm.codigo as permissao_codigo,
    perm.nome as permissao_nome,
    perm.categoria as permissao_categoria,
    CASE WHEN pp.id IS NOT NULL THEN true ELSE false END as tem_permissao
FROM perfis_usuario p
CROSS JOIN permissoes perm
LEFT JOIN perfil_permissoes pp ON pp.perfil_id = p.id AND pp.permissao_id = perm.id
WHERE p.ativo = true AND perm.ativo = true
ORDER BY p.nome, perm.categoria, perm.nome;

-- ===================================
-- 12. FUNÇÃO PARA VERIFICAR PERMISSÃO
-- ===================================
CREATE OR REPLACE FUNCTION usuario_tem_permissao(
    p_usuario_id INTEGER,
    p_codigo_permissao VARCHAR
) RETURNS BOOLEAN AS $$
DECLARE
    v_tem_permissao BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM usuarios u
        INNER JOIN perfil_permissoes pp ON pp.perfil_id = u.perfil_id
        INNER JOIN permissoes perm ON perm.id = pp.permissao_id
        WHERE u.id = p_usuario_id
        AND perm.codigo = p_codigo_permissao
        AND u.ativo = true
        AND perm.ativo = true
    ) INTO v_tem_permissao;

    RETURN v_tem_permissao;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- 13. VERIFICAÇÃO
-- ===================================

-- Ver todas as permissões
SELECT categoria, codigo, nome FROM permissoes ORDER BY categoria, nome;

-- Ver perfis e quantidade de permissões
SELECT
    p.nome as perfil,
    COUNT(pp.id) as total_permissoes
FROM perfis_usuario p
LEFT JOIN perfil_permissoes pp ON pp.perfil_id = p.id
GROUP BY p.id, p.nome
ORDER BY p.nome;

-- Ver permissões do Super Administrador
SELECT
    perm.categoria,
    perm.nome
FROM perfil_permissoes pp
INNER JOIN permissoes perm ON perm.id = pp.permissao_id
WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador')
ORDER BY perm.categoria, perm.nome;

-- ===================================
-- COMENTÁRIOS
-- ===================================
COMMENT ON TABLE permissoes IS 'Operações/permissões disponíveis no sistema';
COMMENT ON TABLE perfil_permissoes IS 'Permissões atribuídas a cada perfil de usuário';
COMMENT ON COLUMN permissoes.codigo IS 'Código único da permissão usado no código';
COMMENT ON COLUMN permissoes.categoria IS 'Categoria da permissão (VENDAS, STOCK, ADMIN, etc)';

-- ===================================
-- ROLLBACK (se necessário)
-- ===================================
-- DROP FUNCTION IF EXISTS usuario_tem_permissao(INTEGER, VARCHAR);
-- DROP VIEW IF EXISTS v_perfil_permissoes;
-- DROP TABLE IF EXISTS perfil_permissoes CASCADE;
-- DROP TABLE IF EXISTS permissoes CASCADE;
-- ===================================
