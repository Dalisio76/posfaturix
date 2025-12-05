# 🚀 GUIA DE BUILD PARA PRODUÇÃO
## PosFaturix - Versão 2.5

**Data:** 05/12/2025
**Versão:** 2.5.0

---

## ✅ CHECKLIST PRÉ-BUILD

Antes de compilar, verificar:

- [ ] **Usuário padrão correto:** Admin / 0000
- [ ] **Database atualizada:** `database/create_database_clean.sql`
- [ ] **Installer atualizado:** `installer/database_inicial.sql`
- [ ] **Notificações:** Email vem da empresa
- [ ] **Licença:** Sistema de anuidade funcionando
- [ ] **Bloqueio empresa:** Nome bloqueia após primeira config
- [ ] **Testes:** Todos funcionando

---

## 📦 PASSO 1: PREPARAR CÓDIGO

### 1.1 Atualizar Versão

**Arquivo:** `pubspec.yaml`
```yaml
version: 2.5.0+25
```

### 1.2 Verificar Dependências

```bash
flutter pub get
flutter pub upgrade
```

### 1.3 Limpar Build Anterior

```bash
flutter clean
```

---

## 🗄️ PASSO 2: ATUALIZAR DATABASE DO INSTALLER

### 2.1 Copiar Database Limpa

```bash
# Windows CMD
copy database\create_database_clean.sql installer\database_inicial.sql

# ou PowerShell
Copy-Item database\create_database_clean.sql installer\database_inicial.sql
```

### 2.2 Verificar Conteúdo

Abrir `installer/database_inicial.sql` e confirmar:

✅ Usuário: `Admin` / `0000`
✅ Tabela usuarios com campo `codigo`
✅ Todas funções presentes
✅ Todas views criadas
✅ Dados iniciais incluídos

---

## 🔨 PASSO 3: COMPILAR APLICAÇÃO

### 3.1 Build Release

```bash
flutter build windows --release
```

**Aguardar:** 5-10 minutos

**Saída esperada:**
```
✓ Built build\windows\runner\Release\posfaturix.exe (XX.X MB)
```

### 3.2 Verificar Arquivos

Pasta: `build\windows\runner\Release\`

Deve conter:
```
✓ posfaturix.exe (executável principal)
✓ data/ (pasta de dados)
✓ flutter_windows.dll
✓ pdfium.dll
✓ printing_plugin.dll
✓ url_launcher_windows_plugin.dll
✓ [outros plugins necessários]
```

---

## 📋 PASSO 4: TESTAR BUILD LOCALMENTE

### 4.1 Testar Executável

```bash
cd build\windows\runner\Release
posfaturix.exe
```

**Verificar:**
- [ ] Sistema abre corretamente
- [ ] Tela de configuração de DB aparece
- [ ] Login funciona (Admin / 0000)
- [ ] Módulos funcionam
- [ ] Relatórios carregam
- [ ] Licença não está expirada

### 4.2 Testar Instalação Limpa

```bash
# 1. Criar pasta temporária
mkdir C:\Temp\PosFaturix_Test

# 2. Copiar arquivos
xcopy build\windows\runner\Release C:\Temp\PosFaturix_Test\ /E /I

# 3. Executar
cd C:\Temp\PosFaturix_Test
posfaturix.exe
```

---

## 📦 PASSO 5: CRIAR INSTALADOR (INNO SETUP)

### 5.1 Verificar Inno Setup

```bash
# Verificar se está instalado
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" /?
```

**Não instalado?**
- Download: https://jrsoftware.org/isdl.php
- Instalar versão 6.x

### 5.2 Atualizar Script do Instalador

**Arquivo:** `installer/installer.iss`

```ini
#define MyAppName "PosFaturix"
#define MyAppVersion "2.5.0"
#define MyAppPublisher "Frentex"
#define MyAppExeName "posfaturix.exe"
#define MyAppURL "https://posfaturix.com"

[Setup]
AppId={{YOUR-GUID-HERE}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=C:\Users\Frentex\source\posfaturix\installer\output
OutputBaseFilename=PosFaturix_Setup_{#MyAppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
SetupIconFile=C:\Users\Frentex\source\posfaturix\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "Criar atalho no Desktop"; GroupDescription: "Atalhos:"; Flags: unchecked

[Files]
; Executável e DLLs
Source: "C:\Users\Frentex\source\posfaturix\build\windows\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Database
Source: "C:\Users\Frentex\source\posfaturix\installer\database_inicial.sql"; DestDir: "{app}\database"; Flags: ignoreversion

; Scripts
Source: "C:\Users\Frentex\source\posfaturix\installer\configurar_database.bat"; DestDir: "{app}\database"; Flags: ignoreversion
Source: "C:\Users\Frentex\source\posfaturix\installer\encontrar_postgresql.bat"; DestDir: "{app}\database"; Flags: ignoreversion

; Gerador de códigos de licença
Source: "C:\Users\Frentex\source\posfaturix\tools\gerador_codigos.dart"; DestDir: "{app}\tools"; Flags: ignoreversion

; Documentação
Source: "C:\Users\Frentex\source\posfaturix\GUIA_NOTIFICACOES_E_LICENCA.md"; DestDir: "{app}\docs"; Flags: ignoreversion isreadme
Source: "C:\Users\Frentex\source\posfaturix\SISTEMA_ANUIDADE_E_ATUALIZACAO.md"; DestDir: "{app}\docs"; Flags: ignoreversion

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\Configurar Database"; Filename: "{app}\database\configurar_database.bat"
Name: "{group}\Documentação"; Filename: "{app}\docs\GUIA_NOTIFICACOES_E_LICENCA.md"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Iniciar {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Verificar PostgreSQL
function InitializeSetup(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;

  // Verificar se PostgreSQL está instalado
  if not FileExists('C:\Program Files\PostgreSQL\15\bin\psql.exe') and
     not FileExists('C:\Program Files\PostgreSQL\16\bin\psql.exe') then
  begin
    if MsgBox('PostgreSQL não detectado. Deseja continuar mesmo assim?',
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
    end;
  end;
end;

// Executar após instalação
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Avisar sobre configuração do database
    MsgBox('IMPORTANTE:' + #13#10 + #13#10 +
           '1. Execute "Configurar Database" no menu Iniciar' + #13#10 +
           '2. Configure a conexão PostgreSQL' + #13#10 +
           '3. Inicie o PosFaturix', mbInformation, MB_OK);
  end;
end;
```

### 5.3 Compilar Instalador

```bash
cd C:\Users\Frentex\source\posfaturix\installer

"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

**Saída:**
```
Successful compile (X warnings)
Output: C:\Users\Frentex\source\posfaturix\installer\output\PosFaturix_Setup_2.5.0.exe
```

---

## 🧪 PASSO 6: TESTAR INSTALADOR

### 6.1 Testar em Máquina Virtual (Recomendado)

**Preparar VM:**
```
- Windows 10/11 limpo
- PostgreSQL 15/16 instalado
- Sem Flutter/desenvolvimento
```

**Passos:**
1. Copiar `PosFaturix_Setup_2.5.0.exe` para VM
2. Executar como Administrador
3. Seguir wizard de instalação
4. Configurar database
5. Testar funcionalidades

### 6.2 Checklist de Testes

**Instalação:**
- [ ] Instalador abre corretamente
- [ ] Detecta PostgreSQL (ou avisa se não tiver)
- [ ] Cria atalhos no Desktop e Menu Iniciar
- [ ] Copia todos arquivos necessários

**Primeiro Uso:**
- [ ] Sistema abre tela de config de DB
- [ ] Consegue conectar ao PostgreSQL
- [ ] Database é criada corretamente
- [ ] Login funciona (Admin / 0000)
- [ ] Licença mostra 365 dias restantes

**Funcionalidades:**
- [ ] Vendas funcionam
- [ ] Caixa abre/fecha
- [ ] Produtos cadastram
- [ ] Relatórios carregam
- [ ] Stock Baixo funciona
- [ ] Produtos Pedidos por Caixa funciona
- [ ] Impressão funciona (se tiver impressora)

**Licença:**
- [ ] Alerta 30 dias antes (testar mudando data do sistema)
- [ ] Bloqueia após vencimento
- [ ] Código de ativação renova
- [ ] Gerador de códigos funciona

**Nome da Empresa:**
- [ ] Permite configurar na primeira vez
- [ ] Bloqueia após salvar
- [ ] Não permite mudar depois

**Notificações (se configurado):**
- [ ] Email vem dos dados da empresa
- [ ] Funciona quando TEM internet
- [ ] Sistema funciona sem internet

---

## 📤 PASSO 7: DISTRIBUIR

### 7.1 Criar Pasta de Release

```
PosFaturix_v2.5.0/
├── PosFaturix_Setup_2.5.0.exe (instalador)
├── LEIA-ME.txt
├── CHANGELOG.md
├── GUIA_INSTALACAO.pdf
└── tools/
    └── gerador_codigos_licenca.exe
```

### 7.2 Criar Arquivo LEIA-ME.txt

```txt
═══════════════════════════════════════════════
  POSFATURIX v2.5.0
═══════════════════════════════════════════════

REQUISITOS:
- Windows 10/11 (64-bit)
- PostgreSQL 12 ou superior
- 4 GB RAM mínimo

INSTALAÇÃO:
1. Executar PosFaturix_Setup_2.5.0.exe como Administrador
2. Seguir assistente de instalação
3. Configurar conexão com PostgreSQL
4. Fazer login: Admin / 0000

CREDENCIAIS PADRÃO:
Nome: Admin
Código: 0000

LICENÇA:
Sistema válido por 365 dias após instalação.
Aviso automático 30 dias antes do vencimento.

RENOVAÇÃO:
Entre em contato para renovar:
📞 +258 XX XXX XXXX
📧 suporte@posfaturix.com

SUPORTE:
WhatsApp: +258 XX XXX XXXX
Email: suporte@posfaturix.com
Site: www.posfaturix.com

═══════════════════════════════════════════════
© 2025 Frentex. Todos os direitos reservados.
═══════════════════════════════════════════════
```

### 7.3 Criar CHANGELOG.md

```markdown
# Changelog - PosFaturix v2.5.0

## [2.5.0] - 05/12/2025

### ✨ Novidades
- Sistema de anuidade/licenciamento automático (365 dias)
- Notificações por email/WhatsApp (opcional, requer internet)
- Bloqueio do nome da empresa após configuração inicial
- Relatório de Produtos Pedidos por Caixa (abertura/fecho)
- Relatório de Stock Baixo com níveis de alerta
- Relatório de Vendedor/Operador com ranking
- Tela de configuração de database gráfica
- Detecção de instância única (evita múltiplas aberturas)

### 🔧 Melhorias
- Interface compacta estilo Windows
- Numeração de vendas simplificada (1, 2, 3...)
- Email para notificações vem dos dados da empresa
- Sistema 100% offline com funcionalidades online opcionais

### 🐛 Correções
- Corrigido problema de múltiplas instâncias
- Corrigido erro de conexão em outros PCs
- Corrigido relatório de produtos pedidos
- Melhorado tratamento de erros

### 🗄️ Database
- Base de dados limpa e consolidada
- Todas migrations aplicadas
- Usuário padrão: Admin / 0000
- 20 tabelas, 5 funções, 5 views

### ⚠️ Importante
- Primeira instalação cria licença de 365 dias
- Nome da empresa é bloqueado após configuração
- Backup recomendado antes de atualizar

### 📋 Próxima Versão (2.6.0)
- Backup automático
- Sincronização entre terminais
- Modo tablet melhorado
```

### 7.4 Métodos de Distribuição

**Opção 1: USB/Pen Drive**
```
1. Copiar pasta PosFaturix_v2.5.0/ para pen drive
2. Entregar ao cliente
3. Cliente executa instalador
```

**Opção 2: Google Drive / Dropbox**
```
1. Upload da pasta para nuvem
2. Criar link compartilhado
3. Enviar link por email/WhatsApp
```

**Opção 3: Site Próprio**
```
1. Hospedar em servidor próprio
2. Cliente baixa direto do site
3. Verificar hash MD5 para segurança
```

**Opção 4: Rede Local (Multi-Loja)**
```
1. Colocar em servidor de rede
2. Clientes acessam via \\servidor\instaladores\
3. Instalar em cada terminal
```

---

## 🔑 PASSO 8: GERAR CÓDIGOS DE LICENÇA

### 8.1 Ferramenta de Geração

**Já criada:** `tools/gerador_codigos.dart`

```bash
# Executar
dart run tools/gerador_codigos.dart

# Saída
═══════════════════════════════════════
   GERADOR DE CÓDIGOS DE ATIVAÇÃO
═══════════════════════════════════════

Quantos códigos gerar? (1-10): 5

Código 1: 2026-1205-AB3F
Código 2: 2026-1205-CD45
Código 3: 2026-1205-EF78
Código 4: 2026-1205-GH12
Código 5: 2026-1205-IJ90

Cada código válido por 365 dias.
Validade: 05/12/2026
```

### 8.2 Compilar Gerador (Opcional)

Para facilitar distribuição:

```bash
# Criar executável standalone
dart compile exe tools/gerador_codigos.dart -o tools/gerador_codigos_licenca.exe
```

---

## 📊 PASSO 9: DOCUMENTAÇÃO PARA CLIENTE

### Arquivos a Incluir

1. ✅ `GUIA_INSTALACAO.pdf` - Como instalar
2. ✅ `MANUAL_USUARIO.pdf` - Como usar
3. ✅ `GUIA_NOTIFICACOES_E_LICENCA.md` - Sistema de licença
4. ✅ `FAQ.pdf` - Perguntas frequentes

### Criar Guia Rápido

**quick_start.txt:**
```
═══════════════════════════════════════════════
  INÍCIO RÁPIDO - POSFATURIX
═══════════════════════════════════════════════

1️⃣ INSTALAR
   ➤ Executar PosFaturix_Setup_2.5.0.exe
   ➤ Clicar "Avançar" até o fim

2️⃣ CONFIGURAR DATABASE
   ➤ Abrir sistema
   ➤ Preencher dados de conexão:
      Host: localhost
      Porta: 5432
      Database: pdv_system
      Usuário: postgres
      Senha: [sua senha]
   ➤ Clicar "Testar Conexão"
   ➤ Clicar "Salvar"

3️⃣ FAZER LOGIN
   ➤ Nome: Admin
   ➤ Código: 0000
   ➤ Clicar "Entrar"

4️⃣ CONFIGURAR EMPRESA
   ➤ Menu > Definições
   ➤ Preencher dados da empresa
   ➤ ⚠️ NOME NÃO PODERÁ SER MUDADO!
   ➤ Salvar

5️⃣ COMEÇAR A USAR
   ➤ Cadastrar produtos
   ➤ Abrir caixa
   ➤ Fazer vendas

═══════════════════════════════════════════════
```

---

## ✅ CHECKLIST FINAL

Antes de entregar ao cliente:

### Build
- [ ] Versão atualizada (2.5.0)
- [ ] Compilação sem erros
- [ ] Executável funciona
- [ ] Tamanho razoável (~50-100 MB)

### Database
- [ ] Installer/database_inicial.sql atualizado
- [ ] Usuário: Admin / 0000
- [ ] Todas tabelas criadas
- [ ] Funções funcionam
- [ ] Views corretas

### Testes
- [ ] Instalação limpa OK
- [ ] Login funciona
- [ ] Vendas funcionam
- [ ] Caixa funciona
- [ ] Relatórios carregam
- [ ] Licença mostra 365 dias
- [ ] Nome empresa bloqueia

### Documentação
- [ ] LEIA-ME.txt criado
- [ ] CHANGELOG.md atualizado
- [ ] Guia de instalação incluído
- [ ] FAQ incluído

### Distribuição
- [ ] Pasta organizada
- [ ] Instalador testado
- [ ] Hash MD5 gerado (segurança)
- [ ] Backup feito

---

## 🎯 RESUMO EXECUTIVO

### Comandos Principais

```bash
# 1. Limpar e preparar
flutter clean
flutter pub get

# 2. Compilar
flutter build windows --release

# 3. Copiar database
copy database\create_database_clean.sql installer\database_inicial.sql

# 4. Criar instalador
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\installer.iss

# 5. Testar
cd installer\output
PosFaturix_Setup_2.5.0.exe
```

### Arquivos Finais

```
installer/output/
└── PosFaturix_Setup_2.5.0.exe (instalador completo)

[Distribuir este arquivo ao cliente]
```

---

## 📞 SUPORTE PÓS-DISTRIBUIÇÃO

### Para o Cliente

**Problemas Comuns:**

1. **"Não consigo conectar ao database"**
   - Verificar se PostgreSQL está instalado
   - Verificar senha
   - Verificar porta 5432

2. **"Sistema não abre"**
   - Executar como Administrador
   - Verificar antivírus
   - Reinstalar Visual C++ Redistributable

3. **"Licença expirada"**
   - Entre em contato para renovar
   - Você envia código de ativação
   - Cliente digita no sistema

### Para Você

**Gerar Código Emergencial:**
```bash
dart run tools/gerador_codigos.dart
# Enviar código ao cliente por WhatsApp/Email
```

**Atualizar Sistema:**
```bash
# Compilar nova versão
flutter build windows --release

# Criar instalador de atualização
# Cliente instala por cima (mantém dados)
```

---

**Build completo! Sistema pronto para produção! 🚀**

**Versão:** 2.5.0
**Data:** 05/12/2025
**Status:** ✅ PRONTO PARA DISTRIBUIR
