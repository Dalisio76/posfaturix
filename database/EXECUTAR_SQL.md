# 🚀 Como Executar o SQL do Fecho de Caixa

## ⚠️ IMPORTANTE: Execute este SQL AGORA!

### **Opção 1: SQL Shell (psql) - RECOMENDADO**

1. Abra o **SQL Shell (psql)** (procure no menu Iniciar)

2. Pressione **Enter** em tudo até pedir a senha

3. Digite a senha do PostgreSQL e pressione Enter

4. Execute os comandos:

```sql
-- Conectar ao banco de dados
\c pdv_system

-- Executar o arquivo SQL
\i 'C:/Users/Frentex/source/posfaturix/database/fecho_caixa.sql'
```

**ATENÇÃO**: Ajuste o caminho se necessário!

---

### **Opção 2: pgAdmin**

1. Abra o **pgAdmin**

2. Conecte-se ao servidor PostgreSQL

3. Navegue até: **Servers > PostgreSQL > Databases > pdv_system**

4. Clique com botão direito em **pdv_system** > **Query Tool**

5. Abra o arquivo: **File > Open** > Selecione `database/fecho_caixa.sql`

6. Clique no botão **Execute** (ícone de play ▶)

---

### **Opção 3: Comando Direto (CMD/PowerShell)**

Abra o CMD ou PowerShell e execute:

```bash
psql -U postgres -d pdv_system -f "C:\Users\Frentex\source\posfaturix\database\fecho_caixa.sql"
```

Digite a senha quando solicitado.

---

## ✅ Como Verificar se Funcionou

Depois de executar o SQL, verifique se as views foram criadas:

```sql
-- No SQL Shell ou pgAdmin
\c pdv_system

-- Verificar views
SELECT table_name FROM information_schema.views
WHERE table_schema = 'public'
AND table_name LIKE '%caixa%';
```

Você deve ver:
- v_caixa_atual
- v_resumo_caixa
- v_despesas_caixa
- v_pagamentos_divida_caixa
- v_produtos_vendidos_caixa
- v_resumo_produtos_caixa

---

## 🐛 Se der Erro

Se aparecer erro de "relation already exists", tudo bem! Significa que algumas tabelas já existem.

Se der outro erro, copie e cole aqui para eu ajudar!
