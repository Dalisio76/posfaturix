#!/usr/bin/env python3
"""
Adiciona dados iniciais ao estrutura_completa.sql
Baseado nas estruturas REAIS das tabelas
"""

def adicionar_dados():
    print("Adicionando dados iniciais baseados na estrutura REAL...")

    # Ler arquivo
    with open('estrutura_completa.sql', 'r', encoding='utf-8') as f:
        conteudo = f.read()

    # Encontrar onde inserir (antes do "-- Completed on" ou no final)
    marcador = "-- Completed on"
    if marcador in conteudo:
        partes = conteudo.split(marcador)
        antes = partes[0]
        depois = marcador + partes[1]
    else:
        antes = conteudo
        depois = "\n\n-- PostgreSQL database dump complete\n--\n"

    # Dados iniciais a adicionar (BASEADOS NA ESTRUTURA REAL)
    dados_iniciais = """

-- =====================================================
-- DADOS INICIAIS ESSENCIAIS
-- =====================================================
-- Adicionados automaticamente baseados na estrutura real

-- =====================================================
-- 1. PERFIS DE USUÁRIO
-- =====================================================
-- Tabela: perfis_usuario (id, nome, descricao, ativo, created_at, updated_at)

DO $$
BEGIN
    -- Super Administrador
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Super Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao)
        VALUES ('Super Administrador', 'Acesso total ao sistema');
    END IF;

    -- Administrador
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao)
        VALUES ('Administrador', 'Administrador com acesso a relatórios e configurações');
    END IF;

    -- Gerente
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Gerente') THEN
        INSERT INTO perfis_usuario (nome, descricao)
        VALUES ('Gerente', 'Gerente com acesso a relatórios');
    END IF;

    -- Operador
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Operador') THEN
        INSERT INTO perfis_usuario (nome, descricao)
        VALUES ('Operador', 'Operador de caixa básico');
    END IF;

    -- Vendedor
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Vendedor') THEN
        INSERT INTO perfis_usuario (nome, descricao)
        VALUES ('Vendedor', 'Vendedor sem acesso administrativo');
    END IF;
END $$;

-- =====================================================
-- 2. PERMISSÕES DO SISTEMA
-- =====================================================
-- Tabela: permissoes (id, codigo, nome, descricao, categoria, ativo, created_at)

DO $$
BEGIN
    -- Vendas
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'efectuar_pagamento') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'fechar_caixa') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'cancelar_venda') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('cancelar_venda', 'Cancelar Venda', 'VENDAS', 'Permitir cancelar vendas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'imprimir_conta') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas');
    END IF;

    -- Stock
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'entrada_stock') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'acerto_stock') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('acerto_stock', 'Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'ver_stock') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_faturas') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada');
    END IF;

    -- Cadastros
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_produtos') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_familias') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_familias', 'Gestão de Famílias', 'CADASTROS', 'Permitir criar e editar famílias');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_clientes') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_fornecedores') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_setores') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_areas') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas');
    END IF;

    -- Financeiro
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_despesas') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_dividas') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_dividas', 'Gestão de Dívidas', 'FINANCEIRO', 'Permitir registar e gerenciar dívidas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_pagamentos') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento');
    END IF;

    -- Relatórios
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'visualizar_relatorios') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'visualizar_margens') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'visualizar_stock') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock');
    END IF;

    -- Administração
    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'acesso_admin') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_usuarios') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_perfis') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_permissoes') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'configuracoes_sistema') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_empresa') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM permissoes WHERE codigo = 'gestao_mesas') THEN
        INSERT INTO permissoes (codigo, nome, categoria, descricao)
        VALUES ('gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas');
    END IF;
END $$;

-- =====================================================
-- 3. VINCULAR PERMISSÕES AOS PERFIS
-- =====================================================

-- Dar todas as permissões ao Super Administrador
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    p.id
FROM permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador')
      AND pp.permissao_id = p.id
  );

-- Dar todas as permissões ao Administrador
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
    p.id
FROM permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Administrador')
      AND pp.permissao_id = p.id
  );

-- =====================================================
-- 4. USUÁRIO ADMINISTRADOR PADRÃO
-- =====================================================
-- Tabela: usuarios (id, nome, perfil_id, codigo, ativo, created_at, updated_at, terminal_id_atual)
-- Nome: Admin
-- Código: 0000

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE codigo = '0000') THEN
        INSERT INTO usuarios (nome, codigo, perfil_id)
        VALUES ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'));
    ELSE
        UPDATE usuarios
        SET nome = 'Admin',
            ativo = true,
            perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador')
        WHERE codigo = '0000';
    END IF;
END $$;

-- =====================================================
-- 5. FORMAS DE PAGAMENTO PADRÃO
-- =====================================================
-- Tabela: formas_pagamento (id, nome, descricao, ativo, created_at)
-- NOTA: Esta tabela NÃO tem coluna "tipo"!

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Dinheiro') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('Dinheiro', 'Pagamento em dinheiro');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Emola') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('Emola', 'Pagamento via Emola');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'M-Pesa') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('M-Pesa', 'Pagamento via M-Pesa');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'POS/Cartão') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('POS/Cartão', 'Pagamento via POS ou cartão');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Transferência') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('Transferência', 'Transferência bancária');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Crédito') THEN
        INSERT INTO formas_pagamento (nome, descricao)
        VALUES ('Crédito', 'Venda a crédito');
    END IF;
END $$;

-- =====================================================
-- 6. FAMÍLIAS DE PRODUTOS PADRÃO
-- =====================================================
-- Tabela: familias (id, nome, descricao, ativo, created_at)

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'BEBIDAS') THEN
        INSERT INTO familias (nome, descricao)
        VALUES ('BEBIDAS', 'Bebidas em geral');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'COMIDAS') THEN
        INSERT INTO familias (nome, descricao)
        VALUES ('COMIDAS', 'Pratos e lanches');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'SOBREMESAS') THEN
        INSERT INTO familias (nome, descricao)
        VALUES ('SOBREMESAS', 'Doces e sobremesas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'PETISCOS') THEN
        INSERT INTO familias (nome, descricao)
        VALUES ('PETISCOS', 'Petiscos e aperitivos');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'OUTROS') THEN
        INSERT INTO familias (nome, descricao)
        VALUES ('OUTROS', 'Outros produtos');
    END IF;
END $$;

-- =====================================================
-- 7. SETORES PADRÃO
-- =====================================================
-- Tabela: setores (id, nome, descricao, ativo, created_at)

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'BAR') THEN
        INSERT INTO setores (nome, descricao)
        VALUES ('BAR', 'Bar e bebidas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'COZINHA') THEN
        INSERT INTO setores (nome, descricao)
        VALUES ('COZINHA', 'Cozinha e pratos quentes');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'CONFEITARIA') THEN
        INSERT INTO setores (nome, descricao)
        VALUES ('CONFEITARIA', 'Doces e sobremesas');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'DIVERSOS') THEN
        INSERT INTO setores (nome, descricao)
        VALUES ('DIVERSOS', 'Produtos diversos');
    END IF;
END $$;

-- =====================================================
-- FIM DOS DADOS INICIAIS
-- =====================================================

-- Mensagem de sucesso
DO $$
BEGIN
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'BASE DE DADOS CRIADA COM SUCESSO!';
    RAISE NOTICE '====================================================';
    RAISE NOTICE 'Usuário padrão: Admin';
    RAISE NOTICE 'Código: 0000';
    RAISE NOTICE '====================================================';
END $$;

-- Verificar dados inseridos
SELECT COUNT(*) || ' perfis de usuário criados' as info FROM perfis_usuario;
SELECT COUNT(*) || ' permissões criadas' as info FROM permissoes;
SELECT COUNT(*) || ' formas de pagamento criadas' as info FROM formas_pagamento;
SELECT COUNT(*) || ' famílias criadas' as info FROM familias;
SELECT COUNT(*) || ' setores criados' as info FROM setores;
SELECT COUNT(*) || ' usuários criados' as info FROM usuarios;

"""

    # Montar arquivo final
    conteudo_final = antes + dados_iniciais + "\n" + depois

    # Salvar
    with open('estrutura_completa_com_dados.sql', 'w', encoding='utf-8') as f:
        f.write(conteudo_final)

    print("[OK] Arquivo criado: estrutura_completa_com_dados.sql")
    print(f"   Tamanho: {len(conteudo_final)} caracteres")
    print("")
    print("Dados iniciais adicionados:")
    print("  - 5 Perfis de usuário")
    print("  - 27 Permissões")
    print("  - Vinculação perfil-permissões")
    print("  - Usuário Admin (código: 0000)")
    print("  - 6 Formas de pagamento")
    print("  - 5 Famílias de produtos")
    print("  - 4 Setores")

if __name__ == '__main__':
    adicionar_dados()
