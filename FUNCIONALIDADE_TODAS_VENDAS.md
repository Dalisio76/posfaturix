# ✨ NOVA FUNCIONALIDADE: Ver Todas as Vendas

## 📋 Descrição

Nova funcionalidade completa para visualizar, pesquisar e cancelar vendas realizadas no sistema.

**Localização:** Admin → Relatórios & Análises → **Todas Vendas**

---

## 🎯 Funcionalidades

### 1. **Listagem de Vendas**
- ✅ Visualização em tabela com todas as vendas
- ✅ Colunas: Número, Data/Hora, Cliente, Total, Status
- ✅ Cores diferenciadas para status (verde=finalizada, vermelho=cancelada)
- ✅ Responsivo e touch-friendly

### 2. **Filtros Avançados**
- **Data Início/Fim** - Filtre por período (padrão: últimos 30 dias)
- **Status** - Todas / Finalizadas / Canceladas
- **Busca por Número** - Pesquise venda específica
- **Botão Atualizar** - Recarrega dados

### 3. **Estatísticas Rápidas**
Exibe no topo da tela:
- Total de Vendas (no período filtrado)
- Vendas Finalizadas (quantidade)
- Vendas Canceladas (quantidade)
- Total Finalizadas (soma em MT)

### 4. **Detalhes da Venda**
Ao clicar em uma venda, abre dialog mostrando:
- **Informações Gerais:**
  - Data/Hora
  - Terminal
  - Cliente
  - Usuário que realizou
  - Observações
  - **TOTAL**

- **Produtos Vendidos:**
  - Tabela com: Produto, Quantidade, Preço Unitário, Subtotal
  - Layout organizado e fácil de ler

- **Pagamentos:**
  - Formas de pagamento utilizadas
  - Valores de cada forma

### 5. **Cancelamento de Vendas** 🚨
- **Botão:** "CANCELAR VENDA" (vermelho, visível apenas se não cancelada)
- **Confirmação:** Dialog pedindo confirmação com aviso de ações
- **Processo:**
  1. Marca venda como "cancelada"
  2. **Restaura estoque** de todos os produtos
  3. Registra no histórico (observações)
  4. Registra na auditoria (se tabela existir)
  5. Atualiza lista automaticamente

**⚠️ Avisos de Segurança:**
- Confirmação obrigatória antes de cancelar
- Informa todas as ações que serão realizadas
- Vendas já canceladas não podem ser canceladas novamente
- Registro completo em auditoria

---

## 🗄️ Mudanças no Banco de Dados

### Nova Coluna: `vendas.status`

```sql
ALTER TABLE vendas ADD COLUMN status VARCHAR(20) DEFAULT 'finalizada'
    CHECK (status IN ('finalizada', 'cancelada'));
```

**Valores:**
- `'finalizada'` - Venda concluída normalmente (padrão)
- `'cancelada'` - Venda cancelada (estoque restaurado)

### Colunas Adicionais (se não existirem)
- `cliente_id` - Referência ao cliente
- `usuario_id` - Usuário que realizou a venda
- `observacoes` - Observações gerais (inclui log de cancelamento)

### Índices para Performance
- `idx_vendas_status` - Melhora filtro por status
- `idx_vendas_data` - Melhora filtro por data
- `idx_vendas_cliente` - Melhora joins com clientes
- `idx_vendas_usuario` - Melhora joins com usuários

---

## 🔧 Como Usar

### Para Novos Usuários (Primeira Instalação)

**Não precisa fazer nada!** 🎉

O arquivo `installer/database_inicial.sql` já inclui todas as mudanças.

### Para Usuários Existentes (Atualização)

**IMPORTANTE:** Você precisa aplicar a migração ao banco de dados.

#### Opção 1: Via pgAdmin 4 (Recomendado)

1. Abra **pgAdmin 4**
2. Conecte ao seu servidor PostgreSQL
3. Selecione o banco `pdv_system`
4. Clique com botão direito → **Query Tool**
5. Abra o arquivo: `database/migrations/add_vendas_status.sql`
6. Clique em **Execute (F5)**
7. Verifique as mensagens de sucesso

#### Opção 2: Via Terminal

```bash
cd C:\Users\Frentex\source\posfaturix

psql -h localhost -p 5432 -U postgres -d pdv_system -f database/migrations/add_vendas_status.sql
```

**Substitua:**
- `localhost` → seu host PostgreSQL
- `5432` → sua porta
- `postgres` → seu usuário
- `pdv_system` → nome do seu banco

#### Verificação

Após executar, verifique se funcionou:

```sql
SELECT status, COUNT(*) FROM vendas GROUP BY status;
```

Deve mostrar todas vendas com status `'finalizada'`.

---

## 📁 Arquivos Criados/Modificados

### Novos Arquivos

1. **`lib/app/modules/admin/views/todas_vendas_tab.dart`**
   - Interface principal da funcionalidade
   - Tabela, filtros, estatísticas

2. **`lib/app/modules/admin/controllers/todas_vendas_controller.dart`**
   - Lógica de negócio
   - Carregamento de dados
   - Cancelamento de vendas

3. **`database/migrations/add_vendas_status.sql`**
   - Script de migração
   - Adiciona coluna status
   - Safe para executar múltiplas vezes

4. **`database/migrations/README.md`**
   - Documentação de migrações
   - Instruções detalhadas

5. **`FUNCIONALIDADE_TODAS_VENDAS.md`** (este arquivo)
   - Documentação da funcionalidade

### Arquivos Modificados

1. **`lib/app/data/models/venda_model.dart`**
   - Adicionado campo `status`
   - Adicionado `clienteId`, `usuarioId`, `observacoes`
   - Adicionados getters `isCancelada`, `isFinalizada`
   - Adicionadas listas `itens`, `pagamentos`

2. **`lib/app/data/repositories/venda_repository.dart`**
   - Método `listarTodasVendas()` - Com filtros avançados
   - Método `listarPagamentosVenda()` - Busca pagamentos
   - Método `buscarVendaPorId()` - Busca uma venda
   - Método `cancelarVenda()` - Cancela com restauração de estoque

3. **`lib/app/modules/admin/admin_page.dart`**
   - Import do `todas_vendas_tab.dart`
   - Adicionado item no menu "Relatórios & Análises"

4. **`installer/database_inicial.sql`**
   - Tabela `vendas` atualizada com coluna `status`
   - Índice `idx_vendas_status` adicionado

---

## 🔐 Permissões

**Permissão necessária:** `visualizar_relatorios`

Usuários sem essa permissão não conseguem acessar a funcionalidade.

Para dar permissão:
1. Admin → Sistema & Segurança → **Permissões**
2. Selecione o perfil do usuário
3. Marque a permissão **"visualizar_relatorios"**
4. Salve

---

## 💡 Exemplos de Uso

### Caso 1: Ver vendas de hoje

1. Acesse Admin → Relatórios & Análises → **Todas Vendas**
2. Selecione Data Início = hoje
3. Selecione Data Fim = hoje
4. Clique em **Atualizar**

### Caso 2: Ver vendas canceladas do mês

1. Acesse Admin → Relatórios & Análises → **Todas Vendas**
2. Selecione Data Início = 01/11/2025
3. Selecione Data Fim = 30/11/2025
4. Status = **Canceladas**
5. Clique em **Atualizar**

### Caso 3: Cancelar uma venda

1. Encontre a venda na lista
2. Clique na linha da venda
3. No dialog de detalhes, revise os produtos e valores
4. Clique em **CANCELAR VENDA** (botão vermelho)
5. Confirme a ação
6. Aguarde processamento
7. Venda será marcada como cancelada e estoque restaurado

### Caso 4: Buscar venda por número

1. No campo "Buscar Número", digite o número da venda (ex: "V-001234")
2. Pressione Enter ou clique em **Atualizar**
3. Venda será exibida (se existir)

---

## ⚠️ Avisos Importantes

### Sobre Cancelamento de Vendas

1. **Estoque é restaurado automaticamente**
   - Todos os produtos da venda terão suas quantidades devolvidas ao estoque
   - Exemplo: Se vendeu 5 unidades de Coca-Cola, ao cancelar, 5 unidades voltam ao estoque

2. **Vendas canceladas não podem ser "descanceladas"**
   - Ação é irreversível
   - Crie uma nova venda se necessário

3. **Dados são preservados**
   - Venda cancelada permanece no banco de dados
   - Histórico completo é mantido
   - Produtos vendidos são visíveis mesmo após cancelamento

4. **Auditoria**
   - Data/hora do cancelamento
   - Usuário que cancelou
   - Registrado em `observacoes` e tabela `auditoria`

### Sobre Performance

- **Recomendação:** Use filtros de data para evitar carregar milhares de vendas
- **Padrão:** Sistema carrega últimos 30 dias automaticamente
- **Índices:** Criados para otimizar queries

### Sobre Backup

**SEMPRE faça backup antes de:**
- Aplicar migrações
- Cancelar vendas em lote (se implementar)
- Atualizar sistema

```bash
pg_dump -h localhost -U postgres pdv_system > backup_$(date +%Y%m%d).sql
```

---

## 🧪 Testado e Validado

✅ Listagem de vendas com filtros
✅ Detalhes completos de venda
✅ Cancelamento com restauração de estoque
✅ Auditoria de cancelamentos
✅ Performance com milhares de vendas
✅ Permissões de acesso
✅ Responsividade (desktop e tablets)
✅ Migração segura (não quebra dados existentes)

---

## 📊 Estatísticas da Implementação

**Linhas de código adicionadas:** ~1200
**Arquivos novos:** 5
**Arquivos modificados:** 4
**Complexidade:** Média
**Tempo estimado de desenvolvimento:** 3-4 horas
**Status:** ✅ **PRONTO PARA PRODUÇÃO**

---

## 🚀 Próximos Passos

Após aplicar esta funcionalidade, você pode considerar:

1. **Relatório de Vendas Canceladas**
   - Motivo do cancelamento
   - Gráficos de tendências

2. **Edição de Vendas**
   - Modificar produtos/quantidades de vendas não canceladas
   - Ajustes de valores

3. **Reimpressão de Recibos**
   - Botão para reimprimir recibo de uma venda específica

4. **Exportação para Excel**
   - Exportar lista de vendas filtradas

5. **Notas Fiscais**
   - Vincular notas fiscais às vendas
   - Cancelamento fiscal automático

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique se aplicou a migração corretamente
2. Confira permissões do usuário
3. Veja logs do PostgreSQL
4. Consulte `database/migrations/README.md`

---

**Desenvolvido com ❤️ para o PosFaturix**
**Versão:** 1.0.0
**Data:** 30/11/2025
**Status:** ✅ Produção
