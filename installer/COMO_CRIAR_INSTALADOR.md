# Como Criar Instalador Profissional do PosFaturix

## 📋 Pré-requisitos

### 1. **Inno Setup** (Instalador Windows)
- Download: https://jrsoftware.org/isdl.php
- Versão: 6.x ou superior
- Instalação: Execute o installer e siga as instruções
- **GRÁTIS e Open Source**

### 2. **Flutter Build Completo**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

### 3. **Ícone da Aplicação**
- Já está em: `assets/favicon.ico`
- Será usado automaticamente pelo instalador

---

## 🚀 Passo a Passo - Criar Instalador

### **Passo 1: Fazer Build do Flutter**

```bash
cd C:\Users\Frentex\source\posfaturix

# Limpar builds antigos
flutter clean

# Obter dependências
flutter pub get

# Build para Windows (Release)
flutter build windows --release
```

Aguarde até completar. Arquivos gerados em:
```
build\windows\x64\runner\Release\
```

### **Passo 2: Verificar Arquivos Necessários**

Certifique-se que existem:

✅ `build\windows\x64\runner\Release\posfaturix.exe`
✅ `build\windows\x64\runner\Release\*.dll` (várias DLLs)
✅ `build\windows\x64\runner\Release\data\` (pasta com recursos)
✅ `assets\favicon.ico` (ícone da aplicação)
✅ `installer\database_inicial.sql`
✅ `installer\configurar_database.bat`
✅ `installer\README_INSTALACAO.txt`

### **Passo 3: Abrir Inno Setup**

1. Abra **Inno Setup Compiler**
2. File → Open
3. Navegue até: `C:\Users\Frentex\source\posfaturix\installer\`
4. Abra: `installer.iss`

### **Passo 4: Compilar Instalador**

1. No Inno Setup, clique em **Build → Compile** (ou pressione **F9**)
2. Aguarde compilação (leva 1-2 minutos)
3. Instalador será gerado em:

```
C:\Users\Frentex\source\posfaturix\installer\Output\
PosFaturix_Setup_1.0.0.exe
```

### **Passo 5: Testar Instalador**

1. Copie `PosFaturix_Setup_1.0.0.exe` para outro local
2. Execute como **Administrador**
3. Siga o assistente:
   - Escolha pasta de instalação
   - Configure PostgreSQL (host, porta, senha)
   - Configure usuário admin
   - Aguarde instalação
4. Execute "Configurar Base de Dados"
5. Inicie o PosFaturix e teste

---

## 🔧 Configuração do Instalador

### **Alterar Versão**

Edite `installer.iss` (linha 13):

```pascal
#define MyAppVersion "1.0.0"  // Altere aqui
```

### **Alterar Nome da Empresa**

Edite `installer.iss` (linha 14):

```pascal
#define MyAppPublisher "Faturix Solutions"  // Altere aqui
```

### **Alterar Ícone**

Se quiser usar outro ícone:

1. Coloque o `.ico` em `assets/`
2. Edite `installer.iss` (linha 35):

```pascal
SetupIconFile=..\assets\SEU_ICONE.ico
```

### **Adicionar Arquivos Extras**

Edite `installer.iss`, seção `[Files]`:

```pascal
Source: "caminho\arquivo.txt"; DestDir: "{app}"; Flags: ignoreversion
```

---

## 📦 Distribuir Instalador

### **Opção 1: Enviar Diretamente**

1. Copie `PosFaturix_Setup_1.0.0.exe`
2. Envie por email, pen drive, ou rede

**Tamanho aproximado: 100-150 MB**

### **Opção 2: Criar USB Bootável**

1. Copie para pen drive:
   - `PosFaturix_Setup_1.0.0.exe`
   - `postgresql-15-windows-x64.exe` (PostgreSQL installer)
   - `vc_redist.x64.exe` (Visual C++ Runtime)

2. Crie `INSTALAR.bat`:
```batch
@echo off
echo Instalando Visual C++ Redistributable...
vc_redist.x64.exe /quiet /norestart

echo.
echo Instalando PostgreSQL...
echo (Siga as instruções na tela)
postgresql-15-windows-x64.exe

echo.
echo Instalando PosFaturix...
PosFaturix_Setup_1.0.0.exe

pause
```

### **Opção 3: Hospedar Online**

Upload para:
- Google Drive
- Dropbox
- OneDrive
- Site próprio

Compartilhe link para download.

---

## 🐛 Solução de Problemas

### **Erro: "File not found: posfaturix.exe"**

**Causa:** Build do Flutter não foi feito ou está em local errado.

**Solução:**
```bash
flutter clean
flutter build windows --release
```

Verifique que existe:
```
build\windows\x64\runner\Release\posfaturix.exe
```

### **Erro: "Cannot find SetupIconFile"**

**Causa:** Ícone não encontrado.

**Solução:**
- Certifique-se que `assets\favicon.ico` existe
- Ou edite `installer.iss` para apontar para ícone correto

### **Instalador Muito Grande**

**Causa:** Build em Debug mode ou muitos arquivos extras.

**Solução:**
1. Use `flutter build windows --release` (não Debug)
2. Remova arquivos desnecessários da seção `[Files]`
3. Compressa fica automática (LZMA2)

### **Não Funciona em Outros Computadores**

**Causa:** Faltam dependências (Visual C++ Runtime).

**Solução:**
1. Certifique-se que o instalador inclui as DLLs
2. Ou adicione no instalador:

Edite `installer.iss`, seção `[Files]`:
```pascal
Source: "C:\Windows\System32\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Windows\System32\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\Windows\System32\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
```

Ou adicione em `[Run]`:
```pascal
Filename: "https://aka.ms/vs/17/release/vc_redist.x64.exe"; Description: "Instalar Visual C++ Runtime"; Flags: shellexec postinstall
```

---

## 🔄 Atualizar Versão

Para criar nova versão:

### 1. Atualizar Código
```bash
# Fazer alterações no código
git commit -am "Nova versão 1.1.0"
git tag v1.1.0
```

### 2. Atualizar installer.iss
```pascal
#define MyAppVersion "1.1.0"  // Nova versão
```

### 3. Rebuild
```bash
flutter clean
flutter build windows --release
```

### 4. Recompilar Instalador
- Abra `installer.iss` no Inno Setup
- F9 (Compile)
- Resultado: `PosFaturix_Setup_1.1.0.exe`

---

## 📊 Checklist Pré-Distribuição

Antes de distribuir o instalador, verifique:

- [ ] Build em **Release** (não Debug)
- [ ] Versão atualizada em `installer.iss`
- [ ] Testado em máquina limpa (sem Flutter/Visual Studio)
- [ ] PostgreSQL configurado corretamente
- [ ] Usuário admin funciona (código 0000)
- [ ] Impressão testada
- [ ] Vendas funcionando
- [ ] Fecho de caixa OK
- [ ] README_INSTALACAO.txt atualizado
- [ ] database_inicial.sql testado
- [ ] Ícone correto
- [ ] Tamanho do instalador razoável (< 200MB)

---

## 🎯 Próximos Passos Avançados

### **Auto-Update (Atualização Automática)**

Para adicionar sistema de auto-update:

1. Hospede versões em servidor
2. Adicione código para verificar atualizações
3. Use Inno Setup Extensions para update

### **Assinatura Digital**

Para evitar avisos de "Publisher Unknown":

1. Compre certificado de code signing
2. Assine o instalador:
```bash
signtool sign /f certificado.pfx /p senha PosFaturix_Setup.exe
```

### **Instalador Online/Offline**

Criar dois instaladores:

- **Online**: Baixa PostgreSQL durante instalação
- **Offline**: Inclui tudo (PostgreSQL, Visual C++, etc.)

---

## 📞 Suporte

Problemas ao criar instalador?

1. Verifique logs do Inno Setup
2. Consulte documentação: https://jrsoftware.org/ishelp/
3. Revise o arquivo `installer.iss`

---

## ✅ Resumo Rápido

```bash
# 1. Build
flutter build windows --release

# 2. Abrir Inno Setup
# File → Open → installer\installer.iss

# 3. Compilar
# Build → Compile (F9)

# 4. Instalador pronto!
# installer\Output\PosFaturix_Setup_1.0.0.exe
```

Pronto! 🚀
