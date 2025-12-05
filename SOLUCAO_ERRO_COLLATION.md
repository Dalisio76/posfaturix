# 🔧 SOLUÇÃO: Erro de Collation no PostgreSQL

## ❌ ERRO:
```
ERROR: new collation (Portuguese_Brazil.1252) is incompatible
with the collation of template database (Portuguese_Mozambique.1252)
```

---

## 🎯 CAUSA

O script estava forçando **collation do Brasil**, mas o PostgreSQL no computador está configurado para **Moçambique** (ou outro país).

---

## ✅ SOLUÇÃO APLICADA

### Arquivos Corrigidos:

1. **`installer/configurar_database.bat`** - Linha 187
   - ❌ Antes: `CREATE DATABASE ... LC_COLLATE='Portuguese_Brazil.1252' ...`
   - ✅ Agora: `CREATE DATABASE ... WITH ENCODING='UTF8';`
   - **Usa collation padrão do sistema automaticamente**

2. **`database/create_database_clean.sql`** - Comentários atualizados
   - Instruções corrigidas
   - Funciona em qualquer país

---

## 🚀 COMO APLICAR A CORREÇÃO

### Opção 1: Recompilar Aplicação (Recomendado)

```bash
# Executar o script de build
build_completo.bat
```

Isso vai:
1. ✅ Atualizar `installer/database_inicial.sql` com correção
2. ✅ Recompilar aplicação
3. ✅ Criar novo instalador

### Opção 2: Corrigir Manualmente no Cliente

Se já instalou no cliente e deu erro:

#### Passo 1: Apagar database criada com erro
```bash
cd "C:\Program Files\PosFaturix\database"
psql -U postgres -c "DROP DATABASE IF EXISTS pdv_system;" postgres
```

#### Passo 2: Corrigir arquivo BAT
Abrir `C:\Program Files\PosFaturix\database\configurar_database.bat`

Procurar linha ~187 que tem:
```bat
psql ... -c "CREATE DATABASE %DB_NAME% WITH ENCODING='UTF8' LC_COLLATE='Portuguese_Brazil.1252' LC_CTYPE='Portuguese_Brazil.1252';" postgres
```

Substituir por:
```bat
psql ... -c "CREATE DATABASE %DB_NAME% WITH ENCODING='UTF8';" postgres
```

#### Passo 3: Executar novamente
```bash
configurar_database.bat
```

### Opção 3: Criar Database Manualmente

#### Via pgAdmin 4:
```
1. Abrir pgAdmin 4
2. Conectar ao PostgreSQL
3. Botão direito em "Databases" > Create > Database
4. Nome: pdv_system
5. Encoding: UTF8
6. Template: template0
7. Collation: (deixar padrão)
8. Salvar

9. Abrir Query Tool
10. Abrir arquivo: database_inicial.sql
11. Executar (F5)
```

#### Via psql (Linha de comando):
```bash
# 1. Criar database
psql -U postgres -c "CREATE DATABASE pdv_system WITH ENCODING='UTF8';"

# 2. Executar script
psql -U postgres -d pdv_system -f "C:\Program Files\PosFaturix\database\database_inicial.sql"
```

---

## 🌍 POR QUE FUNCIONA EM QUALQUER PAÍS?

**Antes:**
```sql
CREATE DATABASE pdv_system
WITH ENCODING='UTF8'
LC_COLLATE='Portuguese_Brazil.1252'  -- ❌ Só funciona no Brasil
LC_CTYPE='Portuguese_Brazil.1252';   -- ❌ Só funciona no Brasil
```

**Agora:**
```sql
CREATE DATABASE pdv_system
WITH ENCODING='UTF8';  -- ✅ Usa configuração do sistema
```

**Resultado:**
- 🇧🇷 Brasil: Usa `Portuguese_Brazil.1252`
- 🇲🇿 Moçambique: Usa `Portuguese_Mozambique.1252`
- 🇵🇹 Portugal: Usa `Portuguese_Portugal.1252`
- 🇦🇴 Angola: Usa `Portuguese_Angola.1252`
- 🌍 Qualquer país: Funciona!

---

## 📋 CHECKLIST DE VERIFICAÇÃO

Após aplicar correção, verificar:

- [ ] Script `configurar_database.bat` atualizado
- [ ] Database criada sem erros
- [ ] Aplicação conecta normalmente
- [ ] Login funciona (Admin / 0000)
- [ ] Vendas funcionam
- [ ] Caracteres especiais (ã, ç, ê) aparecem corretamente

---

## 🔍 VERIFICAR COLLATION DO POSTGRESQL

Para ver qual collation está configurada no seu PostgreSQL:

```sql
-- Ver collation do template padrão
SELECT datname, datcollate, datctype
FROM pg_database
WHERE datname = 'template1';

-- Ver collations disponíveis
SELECT * FROM pg_collation WHERE collname LIKE '%ortugues%';
```

**Saída exemplo (Moçambique):**
```
       datname       |         datcollate          |          datctype
---------------------+-----------------------------+-----------------------------
 template1           | Portuguese_Mozambique.1252  | Portuguese_Mozambique.1252
```

---

## ⚠️ PREVENÇÃO

Para evitar este problema em futuras instalações:

### 1. Sempre usar collation padrão
```sql
CREATE DATABASE nome_db WITH ENCODING='UTF8';
-- NÃO especificar LC_COLLATE e LC_CTYPE
```

### 2. Ou detectar collation do sistema
```bash
# Detectar automaticamente
psql -U postgres -t -c "SELECT datcollate FROM pg_database WHERE datname='template1';" > collation.txt
set /p COLLATION=<collation.txt

# Usar na criação
psql -c "CREATE DATABASE pdv_system WITH ENCODING='UTF8' LC_COLLATE='%COLLATION%' LC_CTYPE='%COLLATION%';"
```

### 3. Usar template0 (mais seguro)
```sql
CREATE DATABASE pdv_system
WITH TEMPLATE template0
ENCODING='UTF8';
```

---

## 🆘 SE AINDA TIVER PROBLEMAS

### Problema: "template database is being accessed by other users"

**Solução:**
```sql
-- Forçar desconexão de outros usuários
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'pdv_system'
  AND pid <> pg_backend_pid();

-- Depois apagar
DROP DATABASE pdv_system;
```

### Problema: "database already exists"

**Solução:**
```sql
-- Conectar a outra database primeiro
\c postgres

-- Depois apagar
DROP DATABASE IF EXISTS pdv_system;
```

### Problema: Caracteres aparecem errados (� ao invés de ã)

**Causa:** Encoding incorreto

**Solução:**
```sql
-- Recriar com encoding correto
DROP DATABASE pdv_system;
CREATE DATABASE pdv_system WITH ENCODING='UTF8';
```

---

## 📞 SUPORTE

Se precisar de ajuda:

**WhatsApp:** +258 XX XXX XXXX
**Email:** suporte@posfaturix.com

Envie print do erro e informações:
- Sistema operacional
- Versão do PostgreSQL
- País/Região

---

**Problema resolvido! ✅**

Sistema agora funciona em **qualquer país** automaticamente.
