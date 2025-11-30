# 🚀 GUIA COMPLETO - INSTALADOR PROFISSIONAL POSFATURIX

## 📑 Índice

1. [Visão Geral](#visão-geral)
2. [Requisitos](#requisitos)
3. [Preparar Projeto](#preparar-projeto)
4. [Criar Instalador](#criar-instalador)
5. [Instalar em Produção](#instalar-em-produção)
6. [Configuração de Rede](#configuração-de-rede)
7. [Solução de Problemas](#solução-de-problemas)
8. [FAQ](#faq)

---

## 📋 Visão Geral

Este guia explica como criar um instalador profissional do PosFaturix que:

✅ Instala em Program Files
✅ Cria atalhos no Menu Iniciar e Desktop
✅ Configura base de dados automaticamente
✅ Funciona em qualquer computador Windows
✅ Inclui usuário super administrador padrão
✅ Resolve problemas de dependências automaticamente

---

## 💻 Requisitos

### **No Computador de Desenvolvimento (onde você cria o instalador):**

- ✅ Windows 10/11 (64-bit)
- ✅ Flutter SDK instalado e configurado
- ✅ PostgreSQL 12+ instalado
- ✅ Inno Setup 6 (download: https://jrsoftware.org/isdl.php)
- ✅ Git (opcional, mas recomendado)

### **No Computador de Produção (onde será instalado):**

- ✅ Windows 10/11 (64-bit)
- ✅ PostgreSQL 12+ instalado
- ✅ Visual C++ 2015-2022 Redistributable (instalado automaticamente se necessário)

---

## 🔨 Preparar Projeto

### **Passo 1: Verificar Estrutura do Projeto**

Certifique-se que seu projeto tem esta estrutura:

```
posfaturix/
├── assets/
│   └── favicon.ico ✅ (seu ícone)
├── lib/
│   └── ... (código Flutter)
├── installer/ ✅ (criado por mim)
│   ├── installer.iss
│   ├── database_inicial.sql
│   ├── configurar_database.bat
│   ├── README_INSTALACAO.txt
│   ├── preparar_build.bat
│   └── COMO_CRIAR_INSTALADOR.md
├── database/
│   └── *.sql (seus scripts)
└── pubspec.yaml
```

### **Passo 2: Atualizar database_config.dart**

Edite `lib/core/database/database_config.dart`:

```dart
class DatabaseConfig {
  static const String host = 'localhost'; // Padrão
  static const int port = 5432;
  static const String database = 'pdv_system';
  static const String username = 'postgres';
  static const String password = 'SENHA_PADRAO'; // Será configurado na instalação

  // ... resto do código
}
```

**IMPORTANTE**: A senha será configurada durante a instalação, mas defina uma padrão aqui.

### **Passo 3: Configurar Ícone**

Você já tem `favicon.ico` em `assets/`. Perfeito! ✅

Se quiser usar outro:
1. Converta para `.ico` (use: https://icoconvert.com/)
2. Coloque em `assets/`
3. Edite `installer/installer.iss` linha 35

---

## 🏗️ Criar Instalador

### **Método 1: Automático (Recomendado)**

Execute o script que criei:

```batch
cd C:\Users\Frentex\source\posfaturix\installer
preparar_build.bat
```

Este script:
1. ✅ Limpa builds antigos
2. ✅ Obtém dependências
3. ✅ Compila para Windows Release
4. ✅ Verifica arquivos necessários
5. ✅ Abre Inno Setup automaticamente (opcional)

Então no Inno Setup:
- Pressione **F9** (Build → Compile)
- Aguarde 1-2 minutos
- Pronto! Instalador em `installer/Output/`

### **Método 2: Manual**

#### **2.1 Build do Flutter**

```bash
cd C:\Users\Frentex\source\posfaturix

# Limpar
flutter clean

# Dependências
flutter pub get

# Build Release
flutter build windows --release
```

#### **2.2 Compilar Instalador**

1. Abra **Inno Setup Compiler**
2. File → Open → `C:\Users\Frentex\source\posfaturix\installer\installer.iss`
3. Build → Compile (F9)
4. Instalador gerado em `installer/Output/PosFaturix_Setup_1.0.0.exe`

---

## 📦 Instalar em Produção

### **No Computador de Produção:**

#### **Passo 1: Instalar PostgreSQL** (se ainda não tiver)

1. Download: https://www.postgresql.org/download/windows/
2. Execute o instalador
3. Durante instalação:
   - Porta: **5432** (padrão)
   - Senha: **ANOTE ESTA SENHA!**
   - Locale: Portuguese_Brazil (ou deixar padrão)

#### **Passo 2: Executar Instalador do PosFaturix**

1. Copie `PosFaturix_Setup_1.0.0.exe` para o computador
2. Clique direito → **Executar como Administrador**
3. Siga o assistente:

**Tela 1: Bem-vindo**
- Clique "Avançar"

**Tela 2: Pasta de Instalação**
- Padrão: `C:\Program Files\PosFaturix`
- Clique "Avançar"

**Tela 3: Configuração da Base de Dados** ⭐
- Servidor PostgreSQL: `localhost` (se servidor local)
- Porta: `5432`
- Nome da base de dados: `pdv_system`
- Usuário PostgreSQL: `postgres`
- Senha PostgreSQL: **[senha que você definiu]**
- Clique "Avançar"

**Tela 4: Usuário Administrador** ⭐
- Nome do administrador: `Admin` (ou outro)
- Código de acesso: `0000` (ou outro de 4 dígitos)
- Clique "Avançar"

**Tela 5: Atalhos**
- ✅ Criar atalho na Área de Trabalho
- ✅ Criar atalho na Barra de Tarefas
- ⬜ Iniciar com Windows (opcional)
- Clique "Instalar"

**Aguarde instalação...**

**Tela Final:**
- ✅ Executar PosFaturix agora
- ✅ Ver instruções de configuração
- Clique "Concluir"

#### **Passo 3: Configurar Base de Dados**

**Opção A: Automático (Recomendado)**

1. Menu Iniciar → PosFaturix → **Configurar Base de Dados**
2. Confirme com "S"
3. Aguarde...
4. Pronto! Database criada.

**Opção B: Manual**

1. Abra **pgAdmin 4**
2. Conecte ao servidor local (senha do PostgreSQL)
3. Clique direito em "Databases" → Create → Database
4. Nome: `pdv_system`
5. Save
6. Clique direito em `pdv_system` → Query Tool
7. Abra: `C:\Program Files\PosFaturix\database\database_inicial.sql`
8. Execute (F5)

#### **Passo 4: Iniciar Aplicação**

1. Clique no ícone do **PosFaturix** na Área de Trabalho
2. Tela de login aparece
3. Digite o código: `0000` (ou o que você configurou)
4. Pronto! Você está dentro! 🎉

---

## 🌐 Configuração de Rede (Múltiplos Terminais)

Para usar PosFaturix em vários computadores conectados ao mesmo banco de dados:

### **No SERVIDOR (PC com PostgreSQL):**

#### **1. Descobrir IP do Servidor**

```batch
cmd
ipconfig
```

Procure por "Endereço IPv4" (ex: `192.168.1.10`)

#### **2. Configurar PostgreSQL para Aceitar Conexões Externas**

**2.1 Editar postgresql.conf**

```batch
# Abra com Notepad++
C:\Program Files\PostgreSQL\15\data\postgresql.conf
```

Encontre:
```conf
#listen_addresses = 'localhost'
```

Altere para:
```conf
listen_addresses = '*'
```

Salve.

**2.2 Editar pg_hba.conf**

```batch
C:\Program Files\PostgreSQL\15\data\pg_hba.conf
```

Adicione no **final** do arquivo:
```conf
# Permitir conexões da rede local
host    all    all    192.168.1.0/24    md5
```

Salve.

**2.3 Reiniciar PostgreSQL**

```batch
# Painel de Controle → Ferramentas Administrativas → Serviços
# Localize: postgresql-x64-15
# Clique direito → Reiniciar
```

Ou via CMD (como Admin):
```batch
net stop postgresql-x64-15
net start postgresql-x64-15
```

#### **3. Liberar Firewall**

```batch
# CMD como Administrador
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
```

### **Nos TERMINAIS (Outros PCs):**

#### **1. Instalar PosFaturix**

- Execute `PosFaturix_Setup_1.0.0.exe`
- Durante instalação, em "Configuração da Base de Dados":
  - Servidor PostgreSQL: **`192.168.1.10`** (IP do servidor)
  - Porta: `5432`
  - Nome: `pdv_system`
  - Usuário: `postgres`
  - Senha: [senha do servidor]

#### **2. OU Configurar Manualmente**

Se já instalou com `localhost`:

Edite:
```
C:\Program Files\PosFaturix\lib\core\database\database_config.dart
```

Altere:
```dart
static const String host = '192.168.1.10'; // IP do servidor
static const String terminalNome = 'Caixa 2'; // Nome deste terminal
```

Salve e reinicie PosFaturix.

---

## 🔧 Solução de Problemas

### **Problema: "VCRUNTIME140.dll não encontrado"**

**Causa:** Visual C++ Redistributable não instalado.

**Solução:**
```
Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
Execute e instale
Reinicie PosFaturix
```

### **Problema: "Não é possível conectar à base de dados"**

**Causa 1:** PostgreSQL não está rodando.

**Solução:**
```
Painel de Controle → Ferramentas Administrativas → Serviços
Localize: postgresql-x64-15
Status deve ser: "Em execução"
Se não: Clique direito → Iniciar
```

**Causa 2:** Senha incorreta.

**Solução:**
```
Edite: C:\Program Files\PosFaturix\lib\core\database\database_config.dart
Linha: static const String password = 'SENHA_CORRETA';
Salve e reinicie
```

**Causa 3:** Database não foi criada.

**Solução:**
```
Menu Iniciar → PosFaturix → Configurar Base de Dados
```

### **Problema: "Erro ao criar base de dados"**

**Causa:** Locale português não disponível.

**Solução:**

Edite `database_inicial.sql`, linha 13-15:

De:
```sql
LC_COLLATE = 'Portuguese_Brazil.1252'
LC_CTYPE = 'Portuguese_Brazil.1252'
```

Para:
```sql
LC_COLLATE = 'C'
LC_CTYPE = 'C'
```

### **Problema: Instalador não abre no outro PC**

**Causa:** Antivírus bloqueando.

**Solução:**
```
Clique direito no instalador → Propriedades
Aba Geral → ✅ Desbloquear
OK
Execute novamente
```

### **Problema: "Instalador corrom pido" ou erro ao compilar**

**Causa:** Build incompleto ou corrompido.

**Solução:**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

Recompile instalador no Inno Setup.

---

## ❓ FAQ

### **Posso mudar a senha do PostgreSQL depois?**

Sim. Edite `database_config.dart` e troque a senha.

### **Como atualizar para nova versão?**

1. Crie novo build com nova versão
2. Altere versão em `installer.iss` (linha 13)
3. Compile novo instalador
4. Execute novo instalador (sobrescreve antigo)
5. Database não será afetada

### **Como fazer backup da base de dados?**

**Automático (pgAdmin):**
```
Abra pgAdmin 4
Clique direito em pdv_system → Backup
Escolha pasta e nome
Format: Plain
Backup
```

**Linha de comando:**
```batch
cd C:\Program Files\PostgreSQL\15\bin
pg_dump -U postgres -d pdv_system > C:\Backups\pdv_backup.sql
```

### **Posso desinstalar sem perder dados?**

Sim! O desinstalador NÃO remove a base de dados PostgreSQL.

Para remover tudo:
1. Desinstale PosFaturix (Painel de Controle)
2. Abra pgAdmin 4
3. Clique direito em pdv_system → Delete/Drop

### **Quantos terminais posso ter?**

Ilimitado! Desde que:
- Todos conectem ao mesmo servidor PostgreSQL
- Servidor suporte carga (RAM, CPU)

### **Preciso comprar licença do PostgreSQL?**

Não! PostgreSQL é 100% gratuito e open source.

### **E o Inno Setup?**

Também gratuito e open source!

---

## 📞 Suporte Adicional

### **Documentação:**
- `C:\Program Files\PosFaturix\README_INSTALACAO.txt`
- `C:\Program Files\PosFaturix\docs\`

### **Logs de Erro:**
- `C:\Program Files\PosFaturix\logs\`
- PostgreSQL logs: `C:\Program Files\PostgreSQL\15\data\log\`

### **Recursos Online:**
- PostgreSQL: https://www.postgresql.org/docs/
- Inno Setup: https://jrsoftware.org/ishelp/
- Flutter: https://docs.flutter.dev/

---

## ✅ Checklist Final

Antes de distribuir:

- [ ] Build compilado em Release
- [ ] Instalador testado em PC limpo
- [ ] PostgreSQL configurado corretamente
- [ ] Login com usuário admin funciona
- [ ] Vendas funcionando
- [ ] Impressão testada
- [ ] Fecho de caixa OK
- [ ] Rede funcionando (se aplicável)
- [ ] README atualizado
- [ ] Versão correta em installer.iss

---

**Pronto para produção! 🚀**

Boas vendas com o PosFaturix!
