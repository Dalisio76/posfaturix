#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Combina estrutura_completa.sql + dados_iniciais_SIMPLES.sql
(versão simplificada sem permissões - para configurar manualmente)
"""

import os

# Diretório base
base_dir = os.path.dirname(os.path.abspath(__file__))

# Arquivos
arquivo_estrutura = os.path.join(base_dir, "estrutura_completa.sql")
arquivo_dados = os.path.join(base_dir, "dados_iniciais_SIMPLES.sql")
arquivo_saida = os.path.join(base_dir, "estrutura_completa_com_dados_SIMPLES.sql")

print("=" * 60)
print("COMBINANDO ARQUIVOS (VERSÃO SIMPLES)")
print("=" * 60)
print(f"Estrutura: {arquivo_estrutura}")
print(f"Dados:     {arquivo_dados}")
print(f"Saída:     {arquivo_saida}")
print()

# Ler estrutura completa
print("Lendo estrutura_completa.sql...")
with open(arquivo_estrutura, 'r', encoding='utf-8') as f:
    linhas_estrutura = f.readlines()

# Ler dados iniciais simples
print("Lendo dados_iniciais_SIMPLES.sql...")
with open(arquivo_dados, 'r', encoding='utf-8') as f:
    conteudo_dados = f.read()

# Encontrar linha "-- PostgreSQL database dump complete"
print("Procurando linha final...")
idx_final = -1
for i, linha in enumerate(linhas_estrutura):
    if "PostgreSQL database dump complete" in linha:
        idx_final = i
        print(f"Encontrado na linha {i + 1}")
        break

if idx_final == -1:
    print("[ERRO] Não encontrei a linha '-- PostgreSQL database dump complete'")
    exit(1)

# Montar arquivo final
print("Montando arquivo final...")
linhas_final = []

# Parte 1: Tudo até antes da linha final
linhas_final.extend(linhas_estrutura[:idx_final])

# Parte 2: Adicionar dados iniciais SIMPLES
linhas_final.append("\n")
linhas_final.append("-- =====================================================\n")
linhas_final.append("-- DADOS INICIAIS: USUÁRIO ADMIN (VERSÃO SIMPLES)\n")
linhas_final.append("-- Adicionado automaticamente por combinar_arquivos_simples.py\n")
linhas_final.append("-- NOTA: Permissões devem ser configuradas manualmente\n")
linhas_final.append("-- =====================================================\n")
linhas_final.append("\n")
linhas_final.append(conteudo_dados)
linhas_final.append("\n")

# Parte 3: Linha final
linhas_final.extend(linhas_estrutura[idx_final:])

# Salvar
print(f"Salvando arquivo: {arquivo_saida}")
with open(arquivo_saida, 'w', encoding='utf-8') as f:
    f.writelines(linhas_final)

print()
print("=" * 60)
print("[OK] ARQUIVO COMBINADO COM SUCESSO!")
print("=" * 60)
print(f"Arquivo criado: {arquivo_saida}")
print(f"Total de linhas: {len(linhas_final)}")
print()
print("IMPORTANTE:")
print("- Este arquivo cria APENAS o usuário Admin/0000")
print("- Permissões devem ser configuradas manualmente na administração")
print()
