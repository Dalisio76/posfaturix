#!/usr/bin/env python3
"""
Processa o backup pdv2.sql e cria database_inicial.sql limpo
Remove comandos problemáticos e adiciona dados iniciais
"""

import re

def processar_backup():
    print("Processando pdv2.sql...")

    # Ler arquivo original
    with open('../pdv2.sql', 'r', encoding='utf-8') as f:
        linhas = f.readlines()

    print(f"Total de linhas lidas: {len(linhas)}")

    # Criar novo arquivo
    saida = []

    # Adicionar cabeçalho
    saida.append("-- =====================================================\n")
    saida.append("-- POSFATURIX - BASE DE DADOS LIMPA E COMPLETA\n")
    saida.append("-- =====================================================\n")
    saida.append("-- Extraído da base de dados em produção\n")
    saida.append("-- Data de Extração: 06/12/2025\n")
    saida.append("-- Versão: 2.5.0\n")
    saida.append("--\n")
    saida.append("-- INSTRUÇÕES:\n")
    saida.append("-- 1. Conectar à base de dados já criada\n")
    saida.append("-- 2. Executar este script completo\n")
    saida.append("--\n")
    saida.append("-- NOTA: Collation será a padrão do sistema (funciona em qualquer país)\n")
    saida.append("-- =====================================================\n\n")

    # Processar linhas
    pular = True
    contador_skipped = 0

    for i, linha in enumerate(linhas):
        # Pular até encontrar primeira função ou tabela
        if pular:
            if linha.startswith('CREATE FUNCTION') or linha.startswith('CREATE TABLE'):
                pular = False
                print(f"Começando a copiar a partir da linha {i+1}")
            else:
                contador_skipped += 1
                continue

        # Pular linhas específicas
        if any(x in linha for x in [
            '\\restrict',
            '\\unrestrict',
            '\\connect',
            'DROP DATABASE',
            'CREATE DATABASE',
            'SET statement_timeout',
            'SET lock_timeout',
            'SET idle_in_transaction',
            'SET transaction_timeout',
            'SET client_encoding',
            'SET standard_conforming',
            'SELECT pg_catalog.set_config',
            'SET check_function_bodies',
            'SET xmloption',
            'SET client_min_messages',
            'SET row_security',
            'TOC entry'
        ]):
            continue

        # Adicionar linha
        saida.append(linha)

    print(f"Linhas ignoradas do início: {contador_skipped}")
    print(f"Linhas processadas: {len(saida)}")

    # Salvar arquivo
    with open('database_inicial_novo.sql', 'w', encoding='utf-8') as f:
        f.writelines(saida)

    print("Arquivo database_inicial_novo.sql criado com sucesso!")
    print("\nPRÓXIMOS PASSOS:")
    print("1. Adicionar dados iniciais (perfis, permissões, usuários, etc)")
    print("2. Copiar para installer/database_inicial.sql")

if __name__ == '__main__':
    processar_backup()
