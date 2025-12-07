#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Adiciona 'public.' antes de todas as tabelas no arquivo de dados iniciais
"""

import os
import re

# Arquivo para corrigir
arquivo = os.path.join(os.path.dirname(__file__), "dados_iniciais_usuario_permissoes.sql")

print("=" * 60)
print("CORRIGINDO SCHEMA PUBLIC")
print("=" * 60)
print(f"Arquivo: {arquivo}")
print()

# Ler arquivo
with open(arquivo, 'r', encoding='utf-8') as f:
    conteudo = f.read()

# Lista de tabelas para adicionar public.
tabelas = [
    'perfis_usuario',
    'permissoes',
    'perfil_permissoes',
    'usuarios'
]

# Fazer substituições
conteudo_original = conteudo
substituicoes = 0

for tabela in tabelas:
    # Padrão 1: FROM tabela (em SELECT)
    padrao1 = rf'\bFROM\s+{tabela}\b'
    conteudo_novo = re.sub(padrao1, f'FROM public.{tabela}', conteudo, flags=re.IGNORECASE)
    substituicoes += len(re.findall(padrao1, conteudo, flags=re.IGNORECASE))
    conteudo = conteudo_novo

    # Padrão 2: INSERT INTO tabela
    padrao2 = rf'\bINSERT\s+INTO\s+{tabela}\b'
    conteudo_novo = re.sub(padrao2, f'INSERT INTO public.{tabela}', conteudo, flags=re.IGNORECASE)
    substituicoes += len(re.findall(padrao2, conteudo, flags=re.IGNORECASE))
    conteudo = conteudo_novo

    # Padrão 3: UPDATE tabela
    padrao3 = rf'\bUPDATE\s+{tabela}\b'
    conteudo_novo = re.sub(padrao3, f'UPDATE public.{tabela}', conteudo, flags=re.IGNORECASE)
    substituicoes += len(re.findall(padrao3, conteudo, flags=re.IGNORECASE))
    conteudo = conteudo_novo

# Evitar duplicação (public.public.)
conteudo = re.sub(r'public\.public\.', 'public.', conteudo)

# Salvar
with open(arquivo, 'w', encoding='utf-8') as f:
    f.write(conteudo)

print(f"Substituições feitas: {substituicoes}")
print()
print("=" * 60)
print("[OK] ARQUIVO CORRIGIDO!")
print("=" * 60)
print()
