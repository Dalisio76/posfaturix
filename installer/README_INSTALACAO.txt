========================================================
  POSFATURIX - GUIA DE INSTALAÇÃO
========================================================

Obrigado por instalar o PosFaturix!

========================================================
  REQUISITOS DO SISTEMA
========================================================

✓ Windows 10 ou superior (64-bit)
✓ 4GB RAM mínimo (8GB recomendado)
✓ 500MB espaço em disco
✓ PostgreSQL 12 ou superior
✓ Microsoft Visual C++ 2015-2022 Redistributable

========================================================
  PRIMEIROS PASSOS
========================================================

1. INSTALAR POSTGRESQL
   --------------------------------------------------
   Se ainda não tem PostgreSQL instalado:

   a) Baixe em: https://www.postgresql.org/download/windows/
   b) Execute o instalador
   c) Durante instalação:
      - Defina uma SENHA (anote!)
      - Porta padrão: 5432
      - Locale: Portuguese_Brazil
   d) Ao finalizar, marque "Stack Builder" (opcional)

2. CONFIGURAR BASE DE DADOS
   --------------------------------------------------
   Método 1 (AUTOMÁTICO - Recomendado):

   a) Clique em "Configurar Base de Dados" no Menu Iniciar
   b) OU execute: C:\Program Files\PosFaturix\configurar_database.bat
   c) Siga as instruções na tela
   d) Pronto! Database configurada automaticamente.

   Método 2 (MANUAL):

   a) Abra pgAdmin 4 (instalado com PostgreSQL)
   b) Conecte ao servidor local
   c) Clique direito em "Databases" → Create → Database
   d) Nome: pdv_system
   e) Clique direito em pdv_system → Query Tool
   f) Abra: C:\Program Files\PosFaturix\database\database_inicial.sql
   g) Execute (F5)

3. INICIAR APLICAÇÃO
   --------------------------------------------------
   a) Clique no ícone do PosFaturix na Área de Trabalho
      OU Menu Iniciar → PosFaturix

   b) Tela de login:
      - Código padrão: 0000
      - Usuário: Admin

   c) Você está dentro!

========================================================
  CONFIGURAÇÕES INICIAIS
========================================================

1. CONFIGURAR IMPRESSORA
   --------------------------------------------------
   Admin → Configurações → Impressoras

   - Adicione suas impressoras (térmicas ou A4)
   - Configure impressoras por área (Bar, Cozinha)
   - Teste impressão

2. CONFIGURAR EMPRESA
   --------------------------------------------------
   Admin → Configurações → Empresa

   - Nome da empresa
   - NIF/CNPJ
   - Morada
   - Telefone
   - Email

3. ADICIONAR PRODUTOS
   --------------------------------------------------
   Admin → Produtos

   - Criar Setores (Bebidas, Comidas, etc.)
   - Criar Famílias (Refrigerantes, Cervejas, etc.)
   - Adicionar Produtos

4. CONFIGURAR USUÁRIOS
   --------------------------------------------------
   Admin → Usuários

   - Criar perfis (Caixa, Garçom, etc.)
   - Adicionar usuários
   - Definir permissões

========================================================
  USANDO O SISTEMA
========================================================

VENDA DIRETA:
1. Selecione produtos
2. Clique em "FINALIZAR (F2)"
3. Escolha forma de pagamento
4. Confirme

VENDA COM MESA:
1. Clique em "PEDIDO/MESA (F3)"
2. Selecione mesa
3. Adicione produtos
4. "Fechar Mesa" quando terminar
5. Escolha forma de pagamento

FECHO DE CAIXA:
1. Clique em "FECHO CAIXA (F5)"
2. Confira valores
3. Confirme
4. Relatório será impresso

========================================================
  INSTALAÇÃO EM REDE (MÚLTIPLOS TERMINAIS)
========================================================

Para usar em vários computadores/tablets:

SERVIDOR (Computador com PostgreSQL):
1. Anote o IP do servidor
   - Abra CMD
   - Digite: ipconfig
   - Anote "Endereço IPv4" (ex: 192.168.1.10)

2. Configurar PostgreSQL para aceitar conexões:
   a) Abra: C:\Program Files\PostgreSQL\15\data\postgresql.conf
   b) Encontre: #listen_addresses = 'localhost'
   c) Altere para: listen_addresses = '*'
   d) Salve

   e) Abra: C:\Program Files\PostgreSQL\15\data\pg_hba.conf
   f) Adicione no final:
      host    all    all    192.168.1.0/24    md5
   g) Salve

   h) Reinicie PostgreSQL:
      - Painel de Controle → Serviços
      - Localize "postgresql-x64-15"
      - Reiniciar

TERMINAIS (Outros computadores):
1. Instale PosFaturix normalmente
2. NÃO configure database (pular etapa)
3. Abra: C:\Program Files\PosFaturix\lib\core\database\database_config.dart
   (Use Notepad++)
4. Altere:
   static const String host = '192.168.1.10'; // IP do servidor
   static const String terminalNome = 'Caixa 2'; // Nome do terminal
5. Salve
6. Inicie PosFaturix

========================================================
  PROBLEMAS COMUNS
========================================================

ERRO: "Não é possível conectar à base de dados"
--------------------------------------------------
✓ PostgreSQL está rodando?
  - Painel de Controle → Serviços
  - "postgresql-x64-15" deve estar "Em execução"

✓ Senha está correta?
  - Verifique em database_config.dart

✓ Database foi criada?
  - Execute "Configurar Base de Dados"

ERRO: "Falha ao carregar aplicação"
--------------------------------------------------
✓ Instale: Microsoft Visual C++ Redistributable
  - Baixe: https://aka.ms/vs/17/release/vc_redist.x64.exe
  - Execute e instale

IMPRESSORA NÃO IMPRIME
--------------------------------------------------
✓ Impressora configurada?
  - Admin → Configurações → Impressoras

✓ Nome da impressora está correto?
  - Admin → VER IMPRESSORAS DO WINDOWS
  - Copie o nome exato

✓ Impressora térmica:
  - Pode ter limite de buffer
  - Use fonte menor
  - Divida recibos longos

========================================================
  BACKUP DA BASE DE DADOS
========================================================

CRIAR BACKUP (Importante! Faça semanalmente):
--------------------------------------------------
Método 1 (pgAdmin):
1. Abra pgAdmin 4
2. Clique direito em "pdv_system"
3. Backup...
4. Escolha local e nome (ex: pdv_backup_2025-01-15.sql)
5. Format: Plain
6. Backup

Método 2 (Linha de comando):
1. Abra CMD como Administrador
2. Execute:
   cd "C:\Program Files\PostgreSQL\15\bin"
   pg_dump -U postgres -d pdv_system > C:\Backups\pdv_backup.sql
3. Digite senha do PostgreSQL

RESTAURAR BACKUP:
--------------------------------------------------
1. Abra pgAdmin 4
2. Clique direito em "pdv_system"
3. Restore...
4. Escolha o arquivo .sql ou .backup
5. Restore

========================================================
  DESINSTALAR
========================================================

1. Painel de Controle → Programas → Desinstalar
2. Localize "PosFaturix"
3. Clique em Desinstalar

ATENÇÃO: A base de dados NÃO será removida!
Para remover completamente:
1. Abra pgAdmin 4
2. Clique direito em "pdv_system"
3. Delete/Drop → CASCADE

========================================================
  SUPORTE
========================================================

Documentação: C:\Program Files\PosFaturix\docs\

Email: suporte@faturix.com (exemplo)
Telefone: +351 XXX XXX XXX (exemplo)

GitHub: https://github.com/faturix (exemplo)

========================================================
  LICENÇA
========================================================

PosFaturix © 2025 Faturix Solutions
Todos os direitos reservados.

Este software é fornecido "como está", sem garantias.

========================================================

Boas vendas! 🚀
