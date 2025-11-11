# Instruções de Instalação - Clientes, Dívidas e Despesas

## 📋 O que foi implementado

✅ **SQL Database:**
- Tabela `clientes` com todos os campos necessários
- Tabela `dividas` para controle de dívidas
- Tabela `pagamentos_divida` para histórico de pagamentos
- Tabela `despesas` para registro de despesas
- Views úteis para relatórios
- Triggers e Functions para automação
- Alterações na tabela `vendas` para suportar dívidas

✅ **Flutter Models:**
- `cliente_model.dart` - Modelo de cliente
- `divida_model.dart` - Modelo de dívida
- `despesa_model.dart` - Modelo de despesa
- `pagamento_divida_model.dart` - Modelo de pagamento

✅ **Flutter Repositories:**
- `cliente_repository.dart` - CRUD completo de clientes
- `divida_repository.dart` - CRUD completo de dívidas
- `despesa_repository.dart` - CRUD completo de despesas
- `pagamento_divida_repository.dart` - Histórico de pagamentos

✅ **Interface Admin:**
- `clientes_tab.dart` - Gestão de clientes
- `despesas_tab.dart` - Gestão de despesas
- Integração no `admin_page.dart`
- Métodos no `admin_controller.dart`

---

## 🚀 Passo 1: Executar SQL

### Abrir SQL Shell (psql)

1. Procure por "SQL Shell (psql)" no menu iniciar
2. Pressione Enter em todas as opções até pedir senha
3. Digite a senha do PostgreSQL e pressione Enter

### Conectar ao banco de dados

```sql
\c pdv_system
```

### Executar o script SQL

Existem duas opções:

**Opção A - Copiar e colar:**
1. Abra o arquivo: `database/clientes_dividas_despesas.sql`
2. Copie todo o conteúdo
3. Cole no SQL Shell
4. Pressione Enter

**Opção B - Executar arquivo:**
```sql
\i 'C:/Users/Frentex/source/posfaturix/database/clientes_dividas_despesas.sql'
```

### Verificar instalação

```sql
-- Ver tabelas criadas
\dt

-- Ver dados de exemplo
SELECT * FROM clientes;
SELECT * FROM despesas;

-- Ver views
SELECT * FROM v_clientes_dividas;
SELECT * FROM v_devedores;

-- Sair
\q
```

---

## 🎯 Passo 2: Testar a aplicação Flutter

1. Execute a aplicação:
```bash
flutter run
```

2. Acesse o menu **Administração**

3. Você verá dois novos itens no menu:
   - **Clientes** - Gestão de clientes
   - **Despesas** - Registro de despesas

4. Teste as funcionalidades:
   - ✅ Adicionar novo cliente
   - ✅ Editar cliente existente
   - ✅ Remover cliente
   - ✅ Adicionar nova despesa
   - ✅ Editar despesa existente
   - ✅ Remover despesa

---

## 📊 Estrutura das Tabelas

### Clientes
- `id` - Identificador único
- `nome` - Nome completo (obrigatório)
- `contacto` / `contacto2` - Telefones
- `email` - Email
- `endereco` / `bairro` / `cidade` - Localização
- `nuit` - Número de identificação fiscal
- `observacoes` - Notas adicionais
- `ativo` - Status (ativo/inativo)

### Dívidas
- `id` - Identificador único
- `cliente_id` - Referência ao cliente
- `venda_id` - Referência à venda (opcional)
- `valor_total` - Valor total da dívida
- `valor_pago` - Valor já pago
- `valor_restante` - Calculado automaticamente
- `status` - PENDENTE / PARCIAL / PAGO (automático)
- `data_divida` / `data_vencimento` - Datas

### Despesas
- `id` - Identificador único
- `descricao` - Descrição da despesa
- `valor` - Valor da despesa
- `categoria` - OPERACIONAL / UTILIDADES / PESSOAL / etc
- `forma_pagamento_id` - Como foi pago
- `data_despesa` - Data e hora
- `observacoes` - Notas adicionais
- `usuario` - Quem registrou

---

## 🔄 Próximos Passos (Sistema de Dívidas nas Vendas)

O sistema já está preparado para integrar dívidas nas vendas. Para isso, será necessário:

1. **Modificar a tela de vendas** para permitir:
   - Selecionar um cliente
   - Escolher venda a crédito
   - Registrar a dívida automaticamente

2. **Criar tela de devedores** para:
   - Listar todos os clientes com dívidas
   - Ver histórico de dívidas por cliente
   - Registrar pagamentos

3. **Dialog de pagamento de dívida** para:
   - Selecionar forma de pagamento
   - Registrar pagamento parcial ou total
   - Atualizar status automaticamente

Tudo isso já está contemplado no arquivo `GUIA_CLIENTES_DIVIDAS_DESPESAS.md`!

---

## ⚠️ Possíveis Erros

### Erro: "relation already exists"
- **Causa:** Tabelas já foram criadas anteriormente
- **Solução:** Você pode ignorar este erro ou deletar as tabelas antes:
```sql
DROP TABLE IF EXISTS pagamentos_divida CASCADE;
DROP TABLE IF EXISTS dividas CASCADE;
DROP TABLE IF EXISTS despesas CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;
```

### Erro: "column does not exist"
- **Causa:** Alterações na tabela vendas já foram aplicadas
- **Solução:** Ignore ou verifique se as colunas já existem:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'vendas';
```

### Erro de compilação Flutter
- **Causa:** Imports faltando
- **Solução:** Execute:
```bash
flutter pub get
flutter clean
flutter run
```

---

## 📝 Notas Importantes

1. **Backup:** Sempre faça backup do banco de dados antes de executar scripts SQL
2. **Desenvolvimento:** Este sistema foi implementado seguindo o padrão do projeto existente
3. **Teclado Virtual:** O teclado virtual já implementado em "pesquisar" pode ser integrado nas telas de cliente quando necessário
4. **Validações:** As validações básicas já estão implementadas nos dialogs
5. **Formatação:** O sistema usa `Formatters.formatarMoeda()` para exibir valores em Meticais

---

## ✅ Checklist de Verificação

- [ ] SQL executado sem erros
- [ ] Tabelas criadas (clientes, dividas, despesas, pagamentos_divida)
- [ ] Views criadas (v_clientes_dividas, v_devedores, etc)
- [ ] Dados de exemplo inseridos
- [ ] Aplicação Flutter compilada sem erros
- [ ] Menu Admin exibe "Clientes" e "Despesas"
- [ ] É possível adicionar/editar/remover clientes
- [ ] É possível adicionar/editar/remover despesas
- [ ] Formulários estão validando campos obrigatórios

---

## 🆘 Suporte

Se encontrar algum problema:
1. Verifique os logs do PostgreSQL
2. Verifique o console do Flutter para erros
3. Certifique-se de que o `DatabaseService` está configurado corretamente
4. Verifique se todas as dependências estão instaladas (`flutter pub get`)

---

**Desenvolvido seguindo o padrão do projeto PosFaturix**
