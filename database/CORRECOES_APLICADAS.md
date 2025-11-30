# Correções Aplicadas no SQL

## Arquivo: sistema_auditoria.sql

### ❌ Problemas Encontrados:
1. **Tabela incorreta:** `vendas_itens` (não existe)
   - **Correto:** `itens_venda`

2. **Tabela incorreta:** `usuario_permissoes` (não existe)
   - **Correto:** `perfil_permissoes`

### ✅ Correções Aplicadas:

#### 1. Linha 90-93: Trigger de Itens de Venda
**ANTES:**
```sql
DROP TRIGGER IF EXISTS trigger_audit_vendas_itens ON vendas_itens;
CREATE TRIGGER trigger_audit_vendas_itens
AFTER INSERT OR UPDATE OR DELETE ON vendas_itens
```

**DEPOIS:**
```sql
DROP TRIGGER IF EXISTS trigger_audit_itens_venda ON itens_venda;
CREATE TRIGGER trigger_audit_itens_venda
AFTER INSERT OR UPDATE OR DELETE ON itens_venda
```

#### 2. Linha 102-105: Trigger de Permissões
**ANTES:**
```sql
DROP TRIGGER IF EXISTS trigger_audit_usuario_permissoes ON usuario_permissoes;
CREATE TRIGGER trigger_audit_usuario_permissoes
AFTER INSERT OR UPDATE OR DELETE ON usuario_permissoes
```

**DEPOIS:**
```sql
DROP TRIGGER IF EXISTS trigger_audit_perfil_permissoes ON perfil_permissoes;
CREATE TRIGGER trigger_audit_perfil_permissoes
AFTER INSERT OR UPDATE OR DELETE ON perfil_permissoes
```

#### 3. Linha 391-394: Mensagem de Conclusão
**ANTES:**
```sql
RAISE NOTICE '   ✓ produtos, vendas, vendas_itens';
RAISE NOTICE '   ✓ usuarios, usuario_permissoes';
```

**DEPOIS:**
```sql
RAISE NOTICE '   ✓ produtos, vendas, itens_venda';
RAISE NOTICE '   ✓ usuarios, perfil_permissoes';
```

### ✅ Verificado:
Todas as outras tabelas referenciadas existem:
- ✓ produtos (schema.sql)
- ✓ vendas (schema.sql)
- ✓ itens_venda (schema.sql)
- ✓ usuarios (usuarios.sql)
- ✓ perfil_permissoes (permissoes.sql)
- ✓ clientes (clientes_dividas_despesas.sql)
- ✓ familias (schema.sql)
- ✓ impressoras (fix_impressoras.sql, sistema_impressoras.sql)
- ✓ areas (expansao_pdv.sql)
- ✓ mesas (sistema_mesas_pedidos.sql)

## Executar SQL Corrigido:

```bash
cd database
psql -U postgres -d posfaturix -f sistema_auditoria.sql
```

Agora deve executar sem erros!
