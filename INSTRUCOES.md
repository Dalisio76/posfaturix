# Sistema PDV - Frentex

Sistema de Ponto de Venda (PDV) desenvolvido com Flutter, GetX e PostgreSQL.

## Funcionalidades

- **Tela Home**: Menu principal com acesso a Vendas e Admin
- **Módulo Admin**: Gerenciar famílias de produtos e produtos
- **Módulo Vendas**: Realizar vendas com carrinho de compras
- **Banco de Dados**: PostgreSQL com persistência de dados

## Pré-requisitos

1. **Flutter** instalado (https://flutter.dev)
2. **PostgreSQL** instalado (https://www.postgresql.org/download/)
3. **Windows** (configurado para rodar no Windows)

## Configuração do PostgreSQL

### 1. Instalar PostgreSQL

- Baixe e instale o PostgreSQL 15 ou superior
- Durante a instalação, anote a **senha do usuário postgres**
- Porta padrão: `5432`

### 2. Criar o Banco de Dados

Abra o terminal (CMD ou PowerShell) e execute:

```bash
# Conectar ao PostgreSQL
psql -U postgres

# Criar o database
CREATE DATABASE pdv_system;

# Sair
\q
```

### 3. Importar o Schema

Na pasta do projeto, execute:

```bash
psql -U postgres -d pdv_system -f database/schema.sql
```

Isso criará as tabelas e inserirá dados de teste (famílias e produtos).

### 4. Configurar Senha do Banco

Edite o arquivo `lib/core/database/database_config.dart`:

```dart
static const String password = 'SUA_SENHA_AQUI'; // Altere aqui!
```

## Executar o Projeto

### 1. Instalar Dependências

```bash
flutter pub get
```

### 2. Rodar o Aplicativo

```bash
flutter run -d windows
```

## Estrutura do Projeto

```
lib/
├── app/
│   ├── data/
│   │   ├── models/          # Modelos de dados
│   │   └── repositories/    # Acesso ao banco
│   ├── modules/
│   │   ├── home/           # Tela inicial
│   │   ├── admin/          # Módulo de administração
│   │   └── vendas/         # Módulo de vendas
│   └── routes/             # Rotas do app
├── core/
│   ├── database/           # Configuração do banco
│   ├── theme/              # Tema da aplicação
│   └── utils/              # Utilitários
└── main.dart               # Ponto de entrada

database/
└── schema.sql              # Schema do PostgreSQL
```

## Como Usar

### 1. Tela Inicial
- Ao abrir o app, você verá 2 botões: **VENDAS** e **ADMIN**

### 2. Admin (Gerenciar Produtos)
- Clique em **ADMIN**
- Aba **FAMÍLIAS**: Adicione, edite ou remova categorias de produtos
- Aba **PRODUTOS**: Adicione, edite ou remova produtos
- Cada produto deve ter: código, nome, família, preço e estoque

### 3. Vendas (Realizar Vendas)
- Clique em **VENDAS**
- Filtre produtos por família (botões no topo)
- Clique nos produtos para adicionar ao carrinho
- Ajuste quantidades no carrinho (+ e -)
- Clique em **FINALIZAR VENDA** para concluir
- O estoque é atualizado automaticamente

## Testar o Banco de Dados

Você pode verificar os dados diretamente no PostgreSQL:

```bash
# Conectar
psql -U postgres -d pdv_system

# Ver famílias
SELECT * FROM familias;

# Ver produtos
SELECT * FROM produtos;

# Ver vendas
SELECT * FROM vendas ORDER BY id DESC LIMIT 10;

# Ver itens de uma venda
SELECT * FROM itens_venda WHERE venda_id = 1;

# Sair
\q
```

## Solução de Problemas

### Erro: "Não consegue conectar ao PostgreSQL"

1. Verifique se o PostgreSQL está rodando:
```bash
# PowerShell como Admin
Get-Service -Name postgresql*
```

2. Se não estiver, inicie:
```bash
Start-Service postgresql-x64-15
```

### Erro: "password authentication failed"

- Verifique a senha em `lib/core/database/database_config.dart`
- Teste a senha no psql primeiro

### Erro ao importar schema

- Certifique-se de estar na pasta do projeto
- Use o caminho correto: `database/schema.sql`

## Próximos Passos

Após ter o MVP funcionando, você pode adicionar:

- Impressão térmica de cupons
- Relatórios de vendas
- Autenticação de usuários
- Desconto em produtos
- Cancelamento de vendas
- Múltiplas formas de pagamento

## Suporte

Consulte o guia completo em: `GUIA_PDV_FLUTTER_POSTGRESQL.md`

---

Desenvolvido com Flutter + PostgreSQL + GetX
