# INSTRUÇÕES DE IMPLEMENTAÇÃO - EXPANSÃO PDV

Este documento contém as instruções passo a passo para implementar a expansão do Sistema PDV.

## STATUS DA IMPLEMENTAÇÃO

Arquivos criados/atualizados:

### FASE 1: Base de Dados
- ✅ `database/expansao_pdv.sql` - Script SQL para criar novas tabelas

### FASE 2: Models
- ✅ `lib/app/data/models/empresa_model.dart`
- ✅ `lib/app/data/models/forma_pagamento_model.dart`
- ✅ `lib/app/data/models/setor_model.dart`
- ✅ `lib/app/data/models/area_model.dart`
- ✅ `lib/app/data/models/venda_model.dart` (atualizado)

### FASE 3: Repositories
- ✅ `lib/app/data/repositories/empresa_repository.dart`
- ✅ `lib/app/data/repositories/forma_pagamento_repository.dart`
- ✅ `lib/app/data/repositories/setor_repository.dart`
- ✅ `lib/app/data/repositories/area_repository.dart`
- ✅ `lib/app/data/repositories/venda_repository.dart` (atualizado)

### FASE 4 e 5: Admin com Drawer e CRUD
- ✅ `lib/app/modules/admin/controllers/admin_controller.dart` (atualizado)
- ✅ `lib/app/modules/admin/admin_page.dart` (atualizado com Drawer)
- ✅ `lib/app/modules/admin/views/empresa_tab.dart`
- ✅ `lib/app/modules/admin/views/formas_pagamento_tab.dart`
- ✅ `lib/app/modules/admin/views/setores_tab.dart`
- ✅ `lib/app/modules/admin/views/areas_tab.dart`

### FASE 6: Formas de Pagamento na Venda
- ✅ `lib/app/modules/vendas/controllers/vendas_controller.dart` (atualizado)

### FASE 7: Impressão com Dados da Empresa
- ✅ `lib/core/utils/windows_printer_service.dart` (atualizado)

---

## 🚀 PASSOS PARA IMPLEMENTAÇÃO

### PASSO 1: Executar Script SQL no PostgreSQL

1. Abra o **pgAdmin** ou **psql** (SQL Shell)
2. Conecte-se ao database `pdv_system`

```bash
# No psql:
\c pdv_system
```

3. Execute o script SQL:
   - Abra o arquivo: `database/expansao_pdv.sql`
   - Copie todo o conteúdo
   - Cole no pgAdmin ou psql
   - Execute

4. Verifique se as tabelas foram criadas:

```sql
-- Ver todas as tabelas
\dt

-- Ver dados da empresa
SELECT * FROM empresa;

-- Ver formas de pagamento
SELECT * FROM formas_pagamento;

-- Ver setores
SELECT * FROM setores;

-- Ver áreas
SELECT * FROM areas;
```

### PASSO 2: Executar o Projeto Flutter

1. Certifique-se de que o PostgreSQL está rodando
2. Abra o terminal na pasta do projeto
3. Execute:

```bash
flutter run -d windows
```

### PASSO 3: Testar as Funcionalidades

#### 3.1 Testar Admin - Empresa

1. Na aplicação, vá para **Admin**
2. Abra o menu lateral (ícone ☰)
3. Clique em **"Dados da Empresa"**
4. Clique em **EDITAR**
5. Atualize os dados:
   - Nome: FRENTEX E SERVICOS
   - NUIT: 123456789
   - Endereço: Av. Julius Nyerere, Maputo
   - Cidade: Maputo
   - Email: contato@frentex.co.mz
   - Contacto: +258 84 123 4567
6. Clique em **SALVAR**
7. Verifique que os dados foram salvos

#### 3.2 Testar Formas de Pagamento

1. No menu lateral do Admin, clique em **"Formas de Pagamento"**
2. Verifique que existem 4 formas: CASH, EMOLA, MPESA, POS
3. Teste **adicionar** uma nova forma (ex: PIX)
4. Teste **editar** uma forma existente
5. Teste **deletar** uma forma (se não estiver em uso)

#### 3.3 Testar Setores

1. No menu lateral do Admin, clique em **"Setores"**
2. Verifique os setores padrão
3. Teste CRUD (Criar, Editar, Deletar)

#### 3.4 Testar Áreas

1. No menu lateral do Admin, clique em **"Áreas"**
2. Verifique as áreas padrão
3. Teste CRUD (Criar, Editar, Deletar)

#### 3.5 Testar Venda com Forma de Pagamento

1. Volte para a tela de **Vendas**
2. Adicione produtos ao carrinho
3. Clique em **"Finalizar Venda"**
4. **NOVO:** Aparecerá um dialog para selecionar a forma de pagamento
5. Selecione uma forma (ex: CASH)
6. Clique em **CONFIRMAR**
7. Escolha se deseja imprimir
8. Verifique que a venda foi registrada

#### 3.6 Testar Impressão

1. Finalize uma venda
2. Escolha **SIM, IMPRIMIR**
3. Verifique que o cupom impresso contém:
   - ✅ Nome da empresa (FRENTEX E SERVICOS)
   - ✅ NUIT
   - ✅ Endereço
   - ✅ Cidade
   - ✅ Contacto
   - ✅ Forma de pagamento

### PASSO 4: Verificar no Banco de Dados

Execute estas queries para verificar os dados:

```sql
-- Verificar última venda com forma de pagamento
SELECT
    v.id,
    v.numero,
    v.total,
    fp.nome as forma_pagamento,
    v.data_venda
FROM vendas v
LEFT JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
ORDER BY v.data_venda DESC
LIMIT 5;

-- Ver estatísticas por forma de pagamento
SELECT
    fp.nome as forma_pagamento,
    COUNT(v.id) as total_vendas,
    SUM(v.total) as total_valor
FROM vendas v
LEFT JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
GROUP BY fp.nome
ORDER BY total_vendas DESC;
```

---

## ✅ CHECKLIST DE VERIFICAÇÃO

### Banco de Dados
- [ ] Tabela `empresa` criada e com dados
- [ ] Tabela `formas_pagamento` criada e com dados
- [ ] Tabela `setores` criada e com dados
- [ ] Tabela `areas` criada e com dados
- [ ] Campo `forma_pagamento_id` adicionado à tabela `vendas`
- [ ] Views criadas corretamente

### Admin
- [ ] Menu Drawer funciona
- [ ] Navegação entre seções funciona
- [ ] CRUD de Empresa funciona
- [ ] CRUD de Formas de Pagamento funciona
- [ ] CRUD de Setores funciona
- [ ] CRUD de Áreas funciona
- [ ] CRUD de Famílias funciona (já existia)
- [ ] CRUD de Produtos funciona (já existia)

### Vendas
- [ ] Dialog de forma de pagamento aparece ao finalizar venda
- [ ] É possível selecionar uma forma de pagamento
- [ ] Não é possível finalizar sem selecionar forma
- [ ] Venda é registrada com forma de pagamento no banco

### Impressão
- [ ] Cupom imprime com nome da empresa
- [ ] Cupom imprime com NUIT, endereço, cidade
- [ ] Cupom imprime com contacto e email
- [ ] Cupom imprime a forma de pagamento selecionada
- [ ] Layout do cupom está correto (80mm)

---

## 🔧 SOLUÇÃO DE PROBLEMAS

### Erro: "forma_pagamento_id does not exist"

Se aparecer este erro ao registrar venda:

```sql
-- Execute no PostgreSQL:
ALTER TABLE vendas ADD COLUMN IF NOT EXISTS forma_pagamento_id INTEGER REFERENCES formas_pagamento(id);
```

### Erro: "Drawer não abre"

- Verifique se o `AdminPage` tem `Scaffold` com parâmetro `drawer`
- Verifique se todos os imports das tabs estão corretos

### Erro: "Dados da empresa null"

```sql
-- Verificar se existe registro:
SELECT * FROM empresa;

-- Se não existir, inserir:
INSERT INTO empresa (nome, nuit, endereco, cidade, email, contacto)
VALUES ('FRENTEX E SERVICOS', '123456789', 'Av. Julius Nyerere, Maputo', 'Maputo', 'contato@frentex.co.mz', '+258 84 123 4567');
```

### Erro de compilação Flutter

Execute:

```bash
flutter clean
flutter pub get
flutter run -d windows
```

---

## 📊 FUNCIONALIDADES IMPLEMENTADAS

### ✅ Dados da Empresa
- Visualizar dados da empresa
- Editar dados da empresa (nome, NUIT, endereço, cidade, email, contacto)
- Dados aparecem no cupom impresso

### ✅ Formas de Pagamento
- Listar todas as formas de pagamento
- Adicionar nova forma de pagamento
- Editar forma de pagamento existente
- Deletar forma de pagamento (soft delete)
- Ícones personalizados por tipo (CASH, EMOLA, MPESA, POS)

### ✅ Setores
- CRUD completo de setores
- Lista ordenada por nome
- Soft delete (ativo/inativo)

### ✅ Áreas
- CRUD completo de áreas
- Lista ordenada por nome
- Soft delete (ativo/inativo)

### ✅ Admin com Drawer
- Menu lateral organizado
- Navegação entre seções
- Visual moderno com destaque de seção ativa

### ✅ Vendas com Forma de Pagamento
- Seleção obrigatória de forma de pagamento
- Dialog com radio buttons
- Validação antes de confirmar
- Forma de pagamento salva no banco

### ✅ Impressão Aprimorada
- Cabeçalho com dados completos da empresa
- Forma de pagamento no cupom
- Rodapé personalizado com nome da empresa
- Layout otimizado para papel 80mm

---

## 🎉 PRÓXIMAS FUNCIONALIDADES SUGERIDAS

- [ ] Relatórios de vendas por forma de pagamento
- [ ] Relatórios por setor/área
- [ ] Múltiplos usuários com login
- [ ] Controle de permissões
- [ ] Comandas por área
- [ ] Transferência entre áreas
- [ ] Dashboard com gráficos
- [ ] Histórico de vendas com filtros

---

**Desenvolvido com ❤️ para Frentex e Serviços**

*Expansão v2.0 - Novembro 2025*
