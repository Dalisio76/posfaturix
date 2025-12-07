#!/usr/bin/env python3
"""
Corrige INSERTs para não depender de ON CONFLICT
Substitui por INSERT com condição WHERE NOT EXISTS
"""

import re

def corrigir_inserts():
    print("Corrigindo INSERTs...")

    # Ler arquivo
    with open('database_inicial.sql', 'r', encoding='utf-8') as f:
        conteudo = f.read()

    # Substituir INSERTs com ON CONFLICT por versão segura

    # 1. Perfis de usuário
    conteudo = re.sub(
        r"INSERT INTO perfis_usuario \(nome, descricao\) VALUES\s*"
        r"\('Super Administrador', 'Acesso total ao sistema'\),\s*"
        r"\('Administrador', 'Administrador com acesso a relatórios e configurações'\),\s*"
        r"\('Gerente', 'Gerente com acesso a relatórios'\),\s*"
        r"\('Operador', 'Operador de caixa básico'\),\s*"
        r"\('Vendedor', 'Vendedor sem acesso administrativo'\)\s*"
        r"ON CONFLICT \(nome\) DO NOTHING;",
        """-- Inserir perfis apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Super Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Super Administrador', 'Acesso total ao sistema');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Administrador', 'Administrador com acesso a relatórios e configurações');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Gerente') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Gerente', 'Gerente com acesso a relatórios');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Operador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Operador', 'Operador de caixa básico');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Vendedor') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Vendedor', 'Vendedor sem acesso administrativo');
    END IF;
END $$;""",
        conteudo,
        flags=re.DOTALL
    )

    # 2. Simplificar permissões - remover ON CONFLICT e usar INSERT direto (única vez)
    # Como são muitas, vou apenas remover o ON CONFLICT e deixar falhar se já existir
    conteudo = conteudo.replace(
        "ON CONFLICT (codigo) DO NOTHING;",
        "ON CONFLICT (codigo) DO UPDATE SET nome = EXCLUDED.nome;",
        1  # Apenas a primeira ocorrência (permissões)
    )

    # 3. Perfil_permissoes - já tem tratamento correto

    # 4. Usuário Admin
    conteudo = conteudo.replace(
        "INSERT INTO usuarios (nome, codigo, perfil_id) VALUES\n"
        "    ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'))\n"
        "ON CONFLICT (codigo) DO UPDATE SET nome = 'Admin', ativo = true;",
        """-- Inserir usuário Admin apenas se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE codigo = '0000') THEN
        INSERT INTO usuarios (nome, codigo, perfil_id)
        VALUES ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'));
    ELSE
        UPDATE usuarios SET nome = 'Admin', ativo = true WHERE codigo = '0000';
    END IF;
END $$;"""
    )

    # 5. Formas de pagamento
    conteudo = re.sub(
        r"INSERT INTO formas_pagamento \(nome, tipo\) VALUES.*?ON CONFLICT \(nome\) DO NOTHING;",
        """-- Inserir formas de pagamento apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Dinheiro') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Dinheiro', 'CASH');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Emola') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Emola', 'EMOLA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'M-Pesa') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('M-Pesa', 'MPESA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'POS/Cartão') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('POS/Cartão', 'POS');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Transferência') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Transferência', 'TRANSFERENCIA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Crédito') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Crédito', 'CREDITO');
    END IF;
END $$;""",
        conteudo,
        flags=re.DOTALL
    )

    # 6. Famílias
    conteudo = re.sub(
        r"INSERT INTO familias \(nome, descricao\) VALUES.*?ON CONFLICT \(nome\) DO NOTHING;",
        """-- Inserir famílias apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'BEBIDAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('BEBIDAS', 'Bebidas em geral');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'COMIDAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('COMIDAS', 'Pratos e lanches');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'SOBREMESAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('SOBREMESAS', 'Doces e sobremesas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'PETISCOS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('PETISCOS', 'Petiscos e aperitivos');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'OUTROS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('OUTROS', 'Outros produtos');
    END IF;
END $$;""",
        conteudo,
        flags=re.DOTALL
    )

    # 7. Setores
    conteudo = re.sub(
        r"INSERT INTO setores \(nome, descricao\) VALUES.*?ON CONFLICT \(nome\) DO NOTHING;",
        """-- Inserir setores apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'BAR') THEN
        INSERT INTO setores (nome, descricao) VALUES ('BAR', 'Bar e bebidas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'COZINHA') THEN
        INSERT INTO setores (nome, descricao) VALUES ('COZINHA', 'Cozinha e pratos quentes');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'CONFEITARIA') THEN
        INSERT INTO setores (nome, descricao) VALUES ('CONFEITARIA', 'Doces e sobremesas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'DIVERSOS') THEN
        INSERT INTO setores (nome, descricao) VALUES ('DIVERSOS', 'Produtos diversos');
    END IF;
END $$;""",
        conteudo,
        flags=re.DOTALL
    )

    # Salvar arquivo corrigido
    with open('database_inicial.sql', 'w', encoding='utf-8') as f:
        f.write(conteudo)

    print("Arquivo corrigido com sucesso!")
    print("INSERTs agora usam DO $$ BEGIN ... IF NOT EXISTS ... END $$;")

if __name__ == '__main__':
    corrigir_inserts()
