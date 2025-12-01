# Changelog - Funcionalidade Todas Vendas

## Versão 1.0.1 (2025-12-01)

### ✅ Mudanças

#### Moeda Atualizada
- **Antes:** Euro (€)
- **Depois:** Metical (MT)
- **Arquivos alterados:**
  - `lib/app/modules/admin/controllers/todas_vendas_controller.dart`
  - `lib/app/modules/admin/views/todas_vendas_tab.dart`
- **Mudança:** Agora usa `Formatters.formatarMoeda()` que já estava configurado no sistema

#### Permissões Atualizadas
- **Antes:** `relatorios`
- **Depois:** `visualizar_relatorios`
- **Arquivo alterado:**
  - `lib/app/modules/admin/admin_page.dart`
- **Impacto:** Alinhado com as outras funcionalidades de relatórios do sistema

#### Outras Permissões Corrigidas
Também foram atualizadas para consistência:
- Relatórios: `visualizar_relatorios`
- Margens/Lucros: `visualizar_margens`
- Stock: `visualizar_stock`

---

## Versão 1.0.0 (2025-11-30)

### 🎉 Release Inicial

#### Funcionalidades Implementadas
- ✅ Listagem completa de vendas
- ✅ Filtros avançados (data, status, número)
- ✅ Estatísticas em tempo real
- ✅ Detalhes da venda com produtos e pagamentos
- ✅ Cancelamento de vendas com restauração de estoque
- ✅ Auditoria de cancelamentos
- ✅ Interface responsiva e touch-friendly

#### Arquivos Criados
1. `lib/app/modules/admin/views/todas_vendas_tab.dart`
2. `lib/app/modules/admin/controllers/todas_vendas_controller.dart`
3. `database/migrations/add_vendas_status.sql`
4. `database/migrations/add_vendas_status_v2.sql`
5. `database/migrations/EXECUTAR_AGORA.sql`
6. `database/migrations/SIMPLES.sql`
7. `database/migrations/README.md`
8. `database/migrations/CORRIGIR_ERRO_TRANSACAO.md`
9. `database/migrations/COPIE_E_COLE.txt`
10. `database/migrations/aplicar_migracao.bat`
11. `FUNCIONALIDADE_TODAS_VENDAS.md`
12. `APLICAR_MIGRACAO_VENDAS.txt`

#### Arquivos Modificados
1. `lib/app/data/models/venda_model.dart`
2. `lib/app/data/repositories/venda_repository.dart`
3. `lib/app/modules/admin/admin_page.dart`
4. `installer/database_inicial.sql`

#### Database
- Nova coluna: `vendas.status` (VARCHAR(20))
- Novas colunas auxiliares: `cliente_id`, `usuario_id`, `observacoes`
- 4 novos índices para performance
- Constraint CHECK para validação de status

---

## 📊 Resumo de Mudanças

| Versão | Data       | Mudanças            | Arquivos |
|--------|------------|---------------------|----------|
| 1.0.1  | 2025-12-01 | Moeda MT, Permissões | 3        |
| 1.0.0  | 2025-11-30 | Release inicial     | 16       |

---

## 🔄 Como Atualizar

### De 1.0.0 para 1.0.1

Não há migração de banco de dados necessária. Apenas atualize os arquivos:

```bash
# Substitua os arquivos modificados na versão 1.0.1
# Reinicie a aplicação
```

**Nota:** Usuários que tiverem a permissão `relatorios` continuarão funcionando, mas a nova permissão correta é `visualizar_relatorios`.

---

## 🐛 Bugs Corrigidos

### Versão 1.0.1
- Nenhum bug corrigido (apenas melhorias)

### Versão 1.0.0
- Erro de transação SQL ao aplicar migração
- Sintaxe SQL RAISE NOTICE fora de bloco DO
- Múltiplos scripts criados para resolver problemas de migração

---

## 📝 Notas de Desenvolvimento

### Compatibilidade
- PostgreSQL 9.6+
- Flutter 3.x
- Dart SDK

### Dependências
- `intl` package (formatação de moeda/data)
- `get` package (state management)

### Performance
- Índices criados nas colunas mais consultadas
- Queries otimizadas com filtros eficientes

---

**Última atualização:** 01/12/2025
**Versão atual:** 1.0.1
