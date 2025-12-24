# PosFaturix v2.6.0 - Documento de Referência

## Correções Pendentes no Banco de Dados

### View v_produtos_completo (EXECUTAR NO POSTGRESQL)
```sql
DROP VIEW IF EXISTS public.v_produtos_completo;

CREATE VIEW public.v_produtos_completo AS
SELECT p.id, p.codigo, p.nome, p.codigo_barras, p.familia_id, p.preco,
       p.preco_compra, p.estoque, p.ativo, p.contavel, p.iva,
       p.created_at, p.updated_at, p.setor_id, p.area_id,
       f.nome AS familia_nome, s.nome AS setor_nome, a.nome AS area_nome,
       CASE WHEN p.preco_compra > 0
            THEN round(((p.preco - p.preco_compra) / p.preco_compra) * 100, 2)
            ELSE 0 END AS margem_lucro_percentual,
       EXISTS (SELECT 1 FROM produto_composicao pc WHERE pc.produto_id = p.id) AS tem_composicao
FROM produtos p
LEFT JOIN familias f ON p.familia_id = f.id
LEFT JOIN setores s ON p.setor_id = s.id
LEFT JOIN areas a ON p.area_id = a.id;
```

## Estrutura Principal

### Credenciais Padrão
- **Administrador**: Admin / 0000
- **PostgreSQL**: postgres / postgres

### Arquivos Importantes
- `installer/database_inicial32.sql` - Schema do banco para instalação
- `database/exportar_estrutura.bat` - Exporta schema para installer
- `database/migrations/` - Scripts de migração

### Funcionalidades Implementadas
1. **Vendas**: PDV com código de barras, carrinho, pagamentos múltiplos
2. **Pedidos/Mesas**: Sistema de mesas com pedidos por área
3. **Caixa**: Abertura/fecho com conferência e relatórios
4. **Clientes/Dívidas**: Gestão de crédito e pagamentos parciais
5. **Administração**: Produtos, famílias, setores, áreas, impressoras
6. **Relatórios**: Vendas, stock, fechos de caixa, devedores
7. **Licença**: Sistema de anuidade com verificação

### Configuração de Rede
- PostgreSQL: Editar `pg_hba.conf` e `postgresql.conf`
- Liberar porta 5432 no firewall
- Usar IP do servidor (não hostname)

## Notas de Desenvolvimento

### Código de Barras
- Campo persiste em `produtos.codigo_barras`
- View `v_produtos_completo` deve incluir `codigo_barras`
- Formatos válidos: EAN-13, EAN-8, UPC-A, UPC-E

### Scaner em Vendas
- Campo com autofocus na tela de vendas
- Enter processa código e mantém foco
- Busca por `codigo` ou `codigo_barras`

### Pesquisa de Produtos
- Enter seleciona primeiro produto da lista
- Teclado QWERTY virtual disponível

### Impressão
- Usa fonte Helvetica (nativa, sem internet)
- Textos sanitizados para remover acentos (compatibilidade)
- Impressora padrão: "balcao" (configurar em WindowsPrinterService)
- Formato: papel térmico 80mm com altura dinâmica

## Versão 2.7.0 - Correções

### Corrigido
1. **Impressão lenta**: Removida dependência de Google Fonts (Roboto)
2. **Aviso Unicode**: Sanitização de texto para fonte Helvetica
3. **Snackbars**: Removidos para evitar erro "No Overlay widget found"
4. **Código de barras**: View corrigida para incluir `codigo_barras`
5. **Foco do scanner**: Campo mantém foco após cada leitura
6. **Pesquisa Enter**: Primeiro produto selecionado ao pressionar Enter

### Segurança - Validação de Duplicados

**Na Aplicação:**
- Produtos: não aceita nome ou código de barras duplicado
- Clientes: não aceita nome, telefone ou NUIT duplicado
- Dialog permanece aberto após salvar para continuar registrando

**Na Base de Dados (executar scripts SQL):**
```
1. database/migrations/verificar_duplicados.sql  -- Verificar duplicados existentes
2. database/migrations/add_unique_constraints.sql -- Aplicar constraints
```

**Constraints criadas:**
- `idx_produtos_nome_unique` - Nome único (case insensitive)
- `idx_produtos_codigo_barras_unique` - Código de barras único
- `idx_produtos_codigo_unique` - Código único
- `idx_clientes_nome_unique` - Nome único
- `idx_clientes_contacto_unique` - Telefone único
- `idx_clientes_nuit_unique` - NUIT único
- `idx_familias_nome_unique` - Nome único
- `idx_formas_pagamento_nome_unique` - Nome único
- `idx_setores_nome_unique` - Nome único
- `idx_areas_nome_unique` - Nome único
- `idx_usuarios_nome_unique` - Nome único
