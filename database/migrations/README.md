# Migrações de Banco de Dados - PosFaturix

Este diretório contém scripts de migração para atualizar o banco de dados existente com novas funcionalidades.

## Como Aplicar Migrações

### Opção 1: Via pgAdmin 4 (Recomendado)

1. Abra o pgAdmin 4
2. Conecte ao servidor PostgreSQL
3. Selecione o banco de dados `pdv_system`
4. Clique com botão direito → **Query Tool**
5. Abra o arquivo de migração desejado (File → Open)
6. Execute o script (F5 ou botão Execute)
7. Verifique a saída para confirmar o sucesso

### Opção 2: Via Terminal/Command Line

```bash
psql -h localhost -p 5432 -U postgres -d pdv_system -f add_vendas_status.sql
```

**Nota:** Substitua `localhost`, `5432`, `postgres` e `pdv_system` pelos valores corretos do seu ambiente.

## Migrações Disponíveis

### 1. add_vendas_status.sql

**Data:** 2025-11-30
**Descrição:** Adiciona coluna `status` à tabela `vendas` para permitir cancelamento de vendas

**Mudanças:**
- ✅ Adiciona coluna `status` (valores: 'finalizada', 'cancelada')
- ✅ Adiciona coluna `cliente_id` (se não existir)
- ✅ Adiciona coluna `usuario_id` (se não existir)
- ✅ Adiciona coluna `observacoes` (se não existir)
- ✅ Cria índices para melhor performance
- ✅ Atualiza vendas existentes com status 'finalizada'

**Pré-requisitos:** Nenhum
**Reversível:** Não (não remove colunas, apenas adiciona)

**Impacto:**
- **Sem impacto em dados existentes** - Todas vendas existentes ficam como 'finalizada'
- **Sem downtime** - Aplicação continua funcionando durante migração
- **Compatível com versões anteriores** - Código antigo continua funcionando

**Como Aplicar:**

```bash
# Via psql
psql -h localhost -U postgres -d pdv_system -f add_vendas_status.sql

# Via pgAdmin
# 1. Abra pgAdmin
# 2. Query Tool no database pdv_system
# 3. Abra e execute add_vendas_status.sql
```

**Verificação:**

Após aplicar, você pode verificar se funcionou executando:

```sql
SELECT
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_name = 'vendas'
ORDER BY ordinal_position;
```

Você deve ver as colunas:
- `status` (character varying, default: 'finalizada')
- `cliente_id` (integer)
- `usuario_id` (integer)
- `observacoes` (text)

## Novas Instalações

**Importante:** Para novas instalações, essas mudanças já estão incluídas no arquivo `installer/database_inicial.sql`.

Não é necessário aplicar migrações se você está instalando o sistema pela primeira vez.

## Troubleshooting

### Erro: "relation vendas does not exist"

**Causa:** Banco de dados não foi criado ou não está usando o banco correto.

**Solução:**
1. Verifique se está conectado ao banco correto: `pdv_system`
2. Execute o script de criação inicial: `installer/database_inicial.sql`

### Erro: "permission denied"

**Causa:** Usuário não tem permissões para alterar a tabela.

**Solução:**
1. Use o usuário `postgres` (superusuário)
2. Ou garanta que seu usuário tem privilégios:
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE pdv_system TO seu_usuario;
   GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO seu_usuario;
   ```

### Erro: "column already exists"

**Causa:** Migração já foi aplicada anteriormente.

**Solução:**
- Isso é normal! O script verifica se a coluna existe antes de adicionar.
- Se você vir mensagens "já existe", significa que a migração já foi aplicada.
- Verifique os avisos (NOTICE) no output do script.

## Boas Práticas

1. **Sempre faça backup antes de aplicar migrações:**
   ```bash
   pg_dump -h localhost -U postgres pdv_system > backup_antes_migracao.sql
   ```

2. **Teste em ambiente de desenvolvimento primeiro**

3. **Leia o script antes de executar** - entenda o que ele faz

4. **Verifique os resultados após aplicar** - execute queries de verificação

5. **Mantenha registro das migrações aplicadas** - anote data e versão

## Histórico de Migrações

| Data       | Arquivo                  | Descrição                       | Status |
|------------|--------------------------|---------------------------------|--------|
| 2025-11-30 | add_vendas_status.sql    | Adiciona status e cancelamento  | ✅      |

## Suporte

Se encontrar problemas ao aplicar migrações:

1. Verifique os logs do PostgreSQL
2. Execute o script linha por linha no Query Tool
3. Consulte a documentação do PostgreSQL
4. Entre em contato com o suporte técnico

---

**Última atualização:** 30/11/2025
**Versão do Sistema:** 1.0.0
