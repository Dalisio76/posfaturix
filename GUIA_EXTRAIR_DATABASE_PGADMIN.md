# 📘 GUIA: EXTRAIR BASE DE DADOS LIMPA NO PGADMIN4

**Objetivo:** Exportar apenas a ESTRUTURA da base de dados (sem dados) para criar instalador limpo

---

## 🎯 MÉTODO 1: BACKUP APENAS ESTRUTURA (RECOMENDADO)

### Passo 1: Abrir pgAdmin4

1. **Abra o pgAdmin4**
2. **Conecte ao servidor PostgreSQL**
   - Expanda: Servers → PostgreSQL XX
   - Digite a senha se solicitado

### Passo 2: Selecionar a Base de Dados

1. **Expanda:** Servers → PostgreSQL XX → Databases
2. **Clique com botão direito** em: `pdv_system`
3. **Selecione:** Backup...

### Passo 3: Configurar o Backup

Na janela que abrir, configure:

#### Aba "General":
- **Filename:** Clique em `📁` e escolha:
  ```
  C:\Users\Frentex\source\posfaturix\database\estrutura_limpa.sql
  ```
- **Format:** `Plain` (muito importante!)
- **Encoding:** `UTF8`
- **Role name:** Deixe em branco

#### Aba "Dump Options":

**Seção "Sections":**
- ✅ **Pre-data:** MARCADO (estrutura antes dos dados)
- ❌ **Data:** DESMARCADO (não queremos dados!)
- ✅ **Post-data:** MARCADO (índices e constraints)

**Seção "Type of objects":**
- ✅ **Only schema:** MARCADO

**Seção "Do not save":**
- ✅ **Owner:** MARCADO (não salvar proprietários)
- ✅ **Privilege:** MARCADO (não salvar permissões)
- ❌ **Tablespace:** DESMARCADO

**Seção "Queries":**
- ✅ **Use Column Inserts:** MARCADO
- ✅ **Use Insert commands:** MARCADO
- ❌ **Include DROP DATABASE statement:** DESMARCADO

**Seção "Disable":**
- ❌ **Trigger:** DESMARCADO
- ❌ **Dollar quoting:** DESMARCADO

### Passo 4: Executar o Backup

1. **Clique em:** Backup
2. **Aguarde** a conclusão (alguns segundos)
3. **Verifique** se terminou sem erros na aba "Messages"
4. **Clique em:** Done

### Passo 5: Verificar Arquivo Gerado

1. **Navegue até:** `C:\Users\Frentex\source\posfaturix\database\`
2. **Verifique** se existe: `estrutura_limpa.sql`
3. **Abra o arquivo** em um editor de texto
4. **Verifique** se contém:
   - `CREATE TABLE` statements ✅
   - `CREATE INDEX` statements ✅
   - `CREATE FUNCTION` statements ✅
   - `INSERT INTO` statements com dados iniciais (perfis, permissões) ✅
   - **NÃO deve ter:** INSERT INTO com seus produtos/vendas ❌

---

## 🎯 MÉTODO 2: USANDO SQL QUERY (ALTERNATIVO)

Se o método 1 não funcionar, use este método:

### Passo 1: Abrir Query Tool

1. **No pgAdmin4**, clique com botão direito em: `pdv_system`
2. **Selecione:** Query Tool

### Passo 2: Executar Comando de Dump

Cole e execute este comando:

```sql
-- Este comando mostra o comando pg_dump que você deve executar
SELECT 'Execute este comando no terminal:' as instrucao
UNION ALL
SELECT 'pg_dump -h localhost -p 5432 -U postgres -d pdv_system --schema-only --no-owner --no-privileges --clean --if-exists > estrutura_limpa.sql';
```

### Passo 3: Executar no Terminal

1. **Abra o Prompt de Comando** (cmd)
2. **Navegue até a pasta do projeto:**
   ```cmd
   cd C:\Users\Frentex\source\posfaturix\database
   ```
3. **Defina a senha:**
   ```cmd
   set PGPASSWORD=postgres
   ```
4. **Execute o dump:**
   ```cmd
   pg_dump -h localhost -p 5432 -U postgres -d pdv_system --schema-only --no-owner --no-privileges --clean --if-exists > estrutura_limpa.sql
   ```
5. **Verifique o arquivo:**
   ```cmd
   dir estrutura_limpa.sql
   ```

---

## 🎯 MÉTODO 3: DUMP COMPLETO E DEPOIS LIMPAR (MAIS TRABALHOSO)

### Passo 1: Dump Completo

1. **Botão direito** em `pdv_system` → Backup...
2. **Filename:** `C:\Users\Frentex\source\posfaturix\database\dump_completo.sql`
3. **Format:** Plain
4. **Deixe todas as opções padrão**
5. **Backup**

### Passo 2: Editar o Arquivo

1. **Abra:** `dump_completo.sql` em um editor
2. **Procure por:** `COPY public.vendas` (ou outras tabelas com seus dados)
3. **Delete** todas as linhas COPY que contenham seus dados
4. **Mantenha** apenas:
   - CREATE TABLE
   - CREATE INDEX
   - CREATE FUNCTION
   - CREATE VIEW
   - INSERT INTO para perfis_usuario, permissoes, formas_pagamento (dados iniciais)

---

## ✅ APÓS EXTRAIR: LIMPAR E PREPARAR O ARQUIVO

### Passo 1: Abrir o Arquivo Extraído

1. **Abra:** `database\estrutura_limpa.sql` em um editor

### Passo 2: Adicionar Cabeçalho

No início do arquivo, adicione:

```sql
-- =====================================================
-- POSFATURIX - BASE DE DADOS LIMPA E COMPLETA
-- =====================================================
-- Este arquivo foi extraído da base de dados em produção
-- Contém apenas a estrutura e dados iniciais essenciais
--
-- Data de Extração: 05/12/2025
-- Versão: 2.5.0
--
-- INSTRUÇÕES:
-- 1. Criar base de dados: CREATE DATABASE pdv_system WITH ENCODING='UTF8';
-- 2. Conectar à base de dados criada
-- 3. Executar este script completo
--
-- NOTA: Collation será a padrão do sistema (funciona em qualquer país)
-- =====================================================
```

### Passo 3: Remover Linhas Problemáticas

Procure e remova (se existir):

```sql
-- Remover linhas como estas:
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;
SET default_tablespace = '';
SET default_table_access_method = heap;

-- Remover linhas de schema (se tiver):
CREATE SCHEMA public;
ALTER SCHEMA public OWNER TO postgres;
COMMENT ON SCHEMA public IS 'standard public schema';
```

### Passo 4: Garantir Collation Livre

Procure por linhas com `LC_COLLATE` ou `LC_CTYPE` e remova essas partes:

**ANTES:**
```sql
CREATE DATABASE pdv_system WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'Portuguese_Brazil.1252' LC_CTYPE = 'Portuguese_Brazil.1252';
```

**DEPOIS:**
```sql
CREATE DATABASE pdv_system WITH ENCODING='UTF8';
```

### Passo 5: Adicionar DROP IF EXISTS

Para cada CREATE TABLE, adicione DROP antes:

**Pode usar Find/Replace:**
- **Find:** `CREATE TABLE`
- **Replace:** `DROP TABLE IF EXISTS tablename CASCADE;\nCREATE TABLE`

Ou adicione no início:

```sql
-- Limpar se já existir (CUIDADO! Remove tudo)
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
```

### Passo 6: Garantir IF NOT EXISTS

Substitua todos os `CREATE TABLE` por `CREATE TABLE IF NOT EXISTS`

**Find/Replace:**
- **Find:** `CREATE TABLE public.`
- **Replace:** `CREATE TABLE IF NOT EXISTS `

### Passo 7: Adicionar Dados Iniciais Essenciais

Garanta que o arquivo tem INSERT para:

```sql
-- Perfis de usuário
INSERT INTO perfis_usuario (nome, descricao) VALUES
    ('Super Administrador', 'Acesso total ao sistema'),
    ('Administrador', 'Administrador com acesso a relatórios'),
    ('Gerente', 'Gerente com acesso a relatórios'),
    ('Operador', 'Operador de caixa básico'),
    ('Vendedor', 'Vendedor sem acesso administrativo')
ON CONFLICT (nome) DO NOTHING;

-- Permissões (todas as 23)
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    -- ... (todas as permissões)
ON CONFLICT (codigo) DO NOTHING;

-- Usuario padrão
INSERT INTO usuarios (nome, codigo, perfil_id) VALUES
    ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'))
ON CONFLICT (codigo) DO UPDATE SET nome = 'Admin', ativo = true;

-- Formas de pagamento
INSERT INTO formas_pagamento (nome, tipo) VALUES
    ('Dinheiro', 'CASH'),
    ('Emola', 'EMOLA'),
    ('M-Pesa', 'MPESA'),
    ('POS/Cartão', 'POS'),
    ('Transferência', 'TRANSFERENCIA'),
    ('Crédito', 'CREDITO')
ON CONFLICT DO NOTHING;

-- Familias
INSERT INTO familias (nome, descricao) VALUES
    ('BEBIDAS', 'Bebidas em geral'),
    ('COMIDAS', 'Pratos e lanches'),
    ('SOBREMESAS', 'Doces e sobremesas'),
    ('PETISCOS', 'Petiscos e aperitivos'),
    ('OUTROS', 'Outros produtos')
ON CONFLICT DO NOTHING;

-- Setores
INSERT INTO setores (nome, descricao) VALUES
    ('BAR', 'Bar e bebidas'),
    ('COZINHA', 'Cozinha e pratos quentes'),
    ('CONFEITARIA', 'Doces e sobremesas'),
    ('DIVERSOS', 'Produtos diversos')
ON CONFLICT DO NOTHING;
```

### Passo 8: Adicionar Mensagem Final

No final do arquivo, adicione:

```sql
-- =====================================================
-- FIM DO SCRIPT
-- =====================================================

SELECT 'BASE DE DADOS CRIADA COM SUCESSO!' as status;
SELECT COUNT(*) || ' tabelas criadas' as info FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
SELECT COUNT(*) || ' views criadas' as info FROM information_schema.views WHERE table_schema = 'public';
SELECT COUNT(*) || ' funções criadas' as info FROM information_schema.routines WHERE routine_schema = 'public';
```

---

## 🧪 TESTAR O ARQUIVO EXTRAÍDO

### Teste 1: Criar Base de Dados Nova

1. **Abra pgAdmin4**
2. **Query Tool** no servidor (não na base específica)
3. **Execute:**
   ```sql
   DROP DATABASE IF EXISTS pdv_system_teste;
   CREATE DATABASE pdv_system_teste WITH ENCODING='UTF8';
   ```

### Teste 2: Executar o Script

1. **Conecte à base nova:** `pdv_system_teste`
2. **Query Tool**
3. **Abra o arquivo:** File → Open → `database\estrutura_limpa.sql`
4. **Execute:** F5 ou ▶️
5. **Verifique:** Não deve ter ERROR, apenas NOTICE

### Teste 3: Verificar Estrutura

```sql
-- Ver tabelas
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Deve mostrar ~32 tabelas

-- Ver views
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- Deve mostrar 3 views

-- Ver usuário padrão
SELECT * FROM usuarios WHERE codigo = '0000';

-- Deve mostrar Admin
```

---

## 📋 CHECKLIST FINAL

Antes de usar o arquivo extraído como installer, verificar:

- [ ] Arquivo extraído sem erros
- [ ] Testado em base de dados nova
- [ ] Cria todas as tabelas (~32)
- [ ] Cria todas as views (3)
- [ ] Cria todas as funções (5)
- [ ] Usuario Admin existe (codigo 0000)
- [ ] Perfis de usuário existem (5)
- [ ] Permissões existem (23)
- [ ] Formas de pagamento existem (6)
- [ ] Sem collation específica
- [ ] Sem dados de produção (vendas, produtos do cliente)
- [ ] Tem ON CONFLICT DO NOTHING nos INSERTs
- [ ] Tem IF NOT EXISTS nos CREATE TABLE
- [ ] Arquivo termina sem erro quando executado

---

## 🚀 USAR O ARQUIVO EXTRAÍDO

### Copiar para Installer

```bash
# Copiar arquivo extraído para o installer
powershell -Command "Copy-Item -Path 'database\estrutura_limpa.sql' -Destination 'installer\database_inicial.sql' -Force"
```

### Testar Instalador

```bash
# Executar instalador
installer\configurar_database.bat
```

---

## ⚠️ IMPORTANTE

### O que DEVE estar no arquivo:
- ✅ CREATE TABLE (todas as tabelas)
- ✅ CREATE INDEX (todos os índices)
- ✅ CREATE FUNCTION (todas as funções)
- ✅ CREATE VIEW (todas as views)
- ✅ INSERT INTO perfis_usuario (dados iniciais)
- ✅ INSERT INTO permissoes (dados iniciais)
- ✅ INSERT INTO usuarios (Admin/0000)
- ✅ INSERT INTO formas_pagamento (6 formas)
- ✅ INSERT INTO familias (5 famílias)
- ✅ INSERT INTO setores (4 setores)

### O que NÃO deve estar:
- ❌ INSERT INTO produtos (seus produtos)
- ❌ INSERT INTO vendas (suas vendas)
- ❌ INSERT INTO clientes (seus clientes)
- ❌ INSERT INTO fornecedores (seus fornecedores)
- ❌ Collation específica (LC_COLLATE, LC_CTYPE)
- ❌ Owner específico (OWNER TO postgres)
- ❌ Privilégios específicos (GRANT, REVOKE)

---

## 📊 RESUMO

```
┌─────────────────────────────────────────────────────┐
│  EXTRAIR BASE LIMPA - RESUMO                        │
├─────────────────────────────────────────────────────┤
│  1. pgAdmin4 → pdv_system → Backup                  │
│  2. Format: Plain                                   │
│  3. Dump Options:                                   │
│     - Pre-data: ✅                                  │
│     - Data: ❌                                      │
│     - Post-data: ✅                                 │
│     - Only schema: ✅                               │
│     - Owner: ✅ (não salvar)                        │
│     - Privilege: ✅ (não salvar)                    │
│  4. Backup → Aguardar                               │
│  5. Editar arquivo (remover collation, etc)         │
│  6. Adicionar dados iniciais (INSERT INTO)          │
│  7. Testar em base nova                             │
│  8. Copiar para installer/database_inicial.sql      │
└─────────────────────────────────────────────────────┘
```

Pronto! Agora você tem a estrutura REAL da sua base de dados funcionando! 🎉

---

© 2025 Frentex - PosFaturix v2.5.0
