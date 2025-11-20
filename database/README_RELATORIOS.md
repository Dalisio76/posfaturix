# Sistema de Relatórios - Instruções de Instalação

## Pré-requisitos

Antes de usar o sistema de relatórios no admin, você precisa executar o arquivo SQL que cria as views necessárias no banco de dados.

## Como executar o SQL

### Opção 1: Usando pgAdmin ou DBeaver

1. Abra o pgAdmin ou DBeaver
2. Conecte-se ao banco de dados **posfaturix**
3. Abra o arquivo `database/views_relatorios.sql`
4. Execute o script completo

### Opção 2: Usando linha de comando (psql)

```bash
psql -U postgres -d posfaturix -f database/views_relatorios.sql
```

### Opção 3: Copiar e colar

1. Abra o arquivo `database/views_relatorios.sql`
2. Copie todo o conteúdo
3. Cole no query editor do seu cliente PostgreSQL
4. Execute

## Views Criadas

Após executar o script, as seguintes views estarão disponíveis:

1. **v_resumo_caixa** - Resumo completo de todos os caixas (abertos e fechados)
2. **v_despesas_caixa** - Despesas detalhadas por caixa
3. **v_pagamentos_divida_caixa** - Pagamentos de dívidas por caixa
4. **v_produtos_vendidos_caixa** - Produtos vendidos detalhados por caixa
5. **v_resumo_produtos_caixa** - Resumo agregado de produtos por caixa
6. **v_caixa_atual** - Caixa atualmente aberto

## Verificação

O próprio script executa uma verificação no final mostrando quantos registros existem em cada view. Se tudo estiver correto, você verá uma tabela com o nome das views e a quantidade de registros.

## Como usar o sistema de relatórios

Após executar o SQL:

1. Abra o aplicativo POSFaturix
2. Entre em **Admin** (pelo menu principal)
3. Clique em **Relatórios** no drawer lateral
4. Você verá:
   - **Lado esquerdo:** Lista de caixas abertas (verde)
   - **Lado direito:** Lista de caixas fechadas (azul)
   - **Filtro de período:** Para caixas fechadas
5. Clique em qualquer caixa para ver os detalhes completos
6. Use os botões:
   - **Ver Produtos Vendidos** - Lista todos os produtos vendidos
   - **Ver Despesas** - Lista todas as despesas

## Problemas comuns

### Erro: "relation v_resumo_caixa does not exist"
- **Solução:** Execute o arquivo `database/views_relatorios.sql`

### Erro: "column categoria does not exist"
- **Solução:** Execute o arquivo `database/clientes_dividas_despesas.sql` primeiro
- Depois execute `database/views_relatorios.sql`

### Erro: "table caixas does not exist"
- **Solução:** Execute o arquivo `database/fecho_caixa.sql` primeiro
- Depois execute `database/views_relatorios.sql`

## Ordem de execução correta

Se você está começando do zero, execute os arquivos SQL nesta ordem:

1. `database/schema.sql` - Estrutura básica
2. `database/expansao_pdv.sql` - Expansões do sistema
3. `database/clientes_dividas_despesas.sql` - Clientes e despesas
4. `database/fecho_caixa.sql` - Sistema de caixa
5. `database/views_relatorios.sql` - **Views de relatórios (ESTE ARQUIVO)**

## Suporte

Se tiver algum problema, verifique:
- Conexão com o banco de dados está funcionando
- Você tem permissões para criar views
- Todas as tabelas necessárias existem (caixas, despesas, vendas, produtos, etc.)
