#!/usr/bin/env python3
"""
Adiciona dados iniciais ao database_inicial_novo.sql
"""

def adicionar_dados():
    print("Adicionando dados iniciais...")

    # Ler arquivo
    with open('database_inicial_novo.sql', 'r', encoding='utf-8') as f:
        conteudo = f.read()

    # Encontrar onde inserir (antes do "-- Completed on")
    marcador = "-- Completed on"
    if marcador in conteudo:
        partes = conteudo.split(marcador)
        antes = partes[0]
        depois = marcador + partes[1]
    else:
        antes = conteudo
        depois = "\n\n-- PostgreSQL database dump complete\n--\n"

    # Dados iniciais a adicionar
    dados_iniciais = """

-- =====================================================
-- DADOS INICIAIS ESSENCIAIS
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
    ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa'),
    ('gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas')
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

-- USUÁRIO SUPER ADMINISTRADOR PADRÃO
-- Nome: Admin
-- Código: 0000
INSERT INTO usuarios (nome, codigo, perfil_id) VALUES
    ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'))
ON CONFLICT (codigo) DO UPDATE SET nome = 'Admin', ativo = true;

-- Formas de pagamento padrão
INSERT INTO formas_pagamento (nome, tipo) VALUES
    ('Dinheiro', 'CASH'),
    ('Emola', 'EMOLA'),
    ('M-Pesa', 'MPESA'),
    ('POS/Cartão', 'POS'),
    ('Transferência', 'TRANSFERENCIA'),
    ('Crédito', 'CREDITO')
ON CONFLICT (nome) DO NOTHING;

-- Famílias de produtos padrão
INSERT INTO familias (nome, descricao) VALUES
    ('BEBIDAS', 'Bebidas em geral'),
    ('COMIDAS', 'Pratos e lanches'),
    ('SOBREMESAS', 'Doces e sobremesas'),
    ('PETISCOS', 'Petiscos e aperitivos'),
    ('OUTROS', 'Outros produtos')
ON CONFLICT (nome) DO NOTHING;

-- Setores padrão
INSERT INTO setores (nome, descricao) VALUES
    ('BAR', 'Bar e bebidas'),
    ('COZINHA', 'Cozinha e pratos quentes'),
    ('CONFEITARIA', 'Doces e sobremesas'),
    ('DIVERSOS', 'Produtos diversos')
ON CONFLICT (nome) DO NOTHING;

-- =====================================================
-- FIM DOS DADOS INICIAIS
-- =====================================================

SELECT 'BASE DE DADOS CRIADA COM SUCESSO!' as status;
SELECT COUNT(*) || ' tabelas criadas' as info FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

"""

    # Montar arquivo final
    conteudo_final = antes + dados_iniciais + "\n" + depois

    # Salvar
    with open('database_inicial.sql', 'w', encoding='utf-8') as f:
        f.write(conteudo_final)

    print("Arquivo database_inicial.sql criado com sucesso!")
    print(f"Total de caracteres: {len(conteudo_final)}")

if __name__ == '__main__':
    adicionar_dados()
