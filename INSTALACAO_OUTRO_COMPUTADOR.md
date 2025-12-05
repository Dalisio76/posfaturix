# 📦 Guia de Instalação em Outro Computador

**Data:** 04/12/2025

---

## 🚨 PROBLEMA COMUM

Quando você instala a aplicação em outro computador, ela pode não abrir ou ficar travada na tela de carregamento.

**Motivo:** A aplicação precisa conectar ao PostgreSQL, que pode não estar instalado ou configurado corretamente no outro computador.

---

## 📋 PRÉ-REQUISITOS

### Opção 1: Terminal Cliente (Conectar a Servidor Remoto)
- **NÃO** precisa instalar PostgreSQL
- Precisa ter acesso de rede ao servidor que tem o PostgreSQL
- Precisa saber o IP do servidor (ex: 192.168.1.10)

### Opção 2: Servidor Principal (Com PostgreSQL Local)
- **PRECISA** instalar PostgreSQL
- Vai ser o servidor que outros terminais conectam

---

## 🔧 INSTALAÇÃO - SERVIDOR PRINCIPAL

Se este computador vai ser o **servidor principal** (onde o banco de dados fica):

### 1. Instalar PostgreSQL

**Download:**
- Windows: https://www.postgresql.org/download/windows/
- Escolha versão 15 ou 16 (64-bit)

**Durante instalação:**
- Porta: `5432` (padrão)
- Senha do usuário `postgres`: Defina uma senha forte (ex: `frentex`)
- Componentes: Marque todos
- Locale: Portuguese, Mozambique (ou o que preferir)

**Testar instalação:**
```cmd
psql --version
```

### 2. Criar o Banco de Dados

Abra **pgAdmin 4** ou **SQL Shell (psql)** e execute:

```sql
CREATE DATABASE pdv_system;
```

### 3. Executar Migrations

Execute TODOS os arquivos SQL da pasta `database/migrations/` na ordem:

```bash
cd database/migrations
psql -U postgres -d pdv_system -f 001_criar_tabelas.sql
psql -U postgres -d pdv_system -f 002_adicionar_indices.sql
# ... execute todos os arquivos na ordem
psql -U postgres -d pdv_system -f add_estoque_minimo.sql
psql -U postgres -d pdv_system -f simplificar_numeracao_vendas.sql
psql -U postgres -d pdv_system -f fix_permissoes_admin.sql
```

### 4. Configurar Firewall (Para Permitir Terminais Clientes)

**Windows Firewall:**
```cmd
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
```

**PostgreSQL pg_hba.conf:**
Edite o arquivo (geralmente em `C:\Program Files\PostgreSQL\15\data\pg_hba.conf`):

Adicione esta linha:
```
host    all             all             192.168.1.0/24          md5
```
(Ajuste o IP da sua rede)

**Reinicie PostgreSQL:**
```cmd
net stop postgresql-x64-15
net start postgresql-x64-15
```

### 5. Descobrir IP do Servidor

```cmd
ipconfig
```

Procure por "IPv4 Address" na placa de rede ativa (ex: `192.168.1.10`)

### 6. Instalar e Configurar Aplicação

1. Copie a pasta `build/windows/runner/Release` para `C:\PosFaturix\`
2. Execute `posfaturix.exe`
3. Na tela de configuração:
   - **Host:** `localhost`
   - **Porta:** `5432`
   - **Banco:** `pdv_system`
   - **Usuário:** `postgres`
   - **Senha:** (a senha que você definiu)
4. Clique em **Testar Conexão**
5. Se conectar, clique em **Salvar e Continuar**

---

## 💻 INSTALAÇÃO - TERMINAL CLIENTE

Se este computador é um **terminal cliente** (vai conectar ao servidor):

### 1. NÃO Precisa Instalar PostgreSQL

Terminais clientes se conectam ao servidor remoto.

### 2. Instalar Aplicação

1. Copie a pasta `build/windows/runner/Release` para `C:\PosFaturix\`
2. Execute `posfaturix.exe`

### 3. Configurar Conexão

Na tela de configuração que aparece:

- **Host:** `IP DO SERVIDOR` (ex: `192.168.1.10`)
- **Porta:** `5432`
- **Banco:** `pdv_system`
- **Usuário:** `postgres`
- **Senha:** (a senha do servidor)

**⚠️ IMPORTANTE:** Use o **IP do servidor**, NÃO use `localhost`!

### 4. Testar Conexão

1. Clique em **Testar Conexão**
2. Se aparecer erro:
   - Verifique se o IP está correto
   - Verifique se o servidor está ligado
   - Verifique se o firewall do servidor permite conexões
   - Faça ping no servidor: `ping 192.168.1.10`

3. Se conectar com sucesso, clique em **Salvar e Continuar**

---

## 🔄 CRIAR INSTALADOR MSIX (Opcional)

Para criar um instalador mais profissional:

### 1. Adicionar configuração MSIX no pubspec.yaml

```yaml
msix_config:
  display_name: Frentex POS
  publisher_display_name: Frentex Software
  identity_name: com.frentex.posfaturix
  msix_version: 1.0.0.0
  logo_path: assets/logo.png
  capabilities: internetClient, privateNetworkClientServer
  certificate_path: C:/certificate.pfx
  certificate_password: 'senha_do_certificado'
```

### 2. Gerar MSIX

```bash
flutter pub run msix:create
```

O instalador será criado em `build/windows/x64/runner/Release/posfaturix.msix`

### 3. Instalar em outros computadores

Basta executar o arquivo `.msix` e seguir o assistente.

**⚠️ Aviso:** Precisa de certificado digital para não aparecer aviso de "Publisher desconhecido".

---

## 🛠️ TROUBLESHOOTING

### Problema: Aplicação não abre

**Possíveis causas:**

1. **Faltam DLLs do Visual C++ Runtime**
   - **Solução:** Instale [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe)

2. **Aplicação está esperando conexão com banco**
   - **Solução:** Configure a conexão na tela que aparece

3. **Firewall bloqueando**
   - **Solução:** Adicione exceção para `posfaturix.exe`

### Problema: Erro "Connection refused"

**Causas:**
- PostgreSQL não está rodando no servidor
- IP do servidor está errado
- Firewall bloqueando porta 5432

**Soluções:**
1. No servidor, verifique se PostgreSQL está rodando:
   ```cmd
   sc query postgresql-x64-15
   ```

2. Teste ping:
   ```cmd
   ping 192.168.1.10
   ```

3. Teste porta PostgreSQL:
   ```cmd
   telnet 192.168.1.10 5432
   ```
   (Se não funcionar, instale telnet: `dism /online /Enable-Feature /FeatureName:TelnetClient`)

### Problema: Erro "password authentication failed"

**Causa:** Senha incorreta

**Solução:**
- Verifique a senha do usuário `postgres`
- No pgAdmin, pode resetar a senha se necessário

### Problema: Erro "database does not exist"

**Causa:** Banco `pdv_system` não foi criado

**Solução:**
```sql
CREATE DATABASE pdv_system;
```

### Problema: Tela branca ou travada

**Causas:**
- Aplicação tentando conectar sem sucesso
- Erro no código

**Soluções:**
1. Feche completamente a aplicação (Task Manager)
2. Delete o arquivo de cache:
   ```
   C:\Users\SeuUsuario\AppData\Local\posfaturix\
   ```
3. Execute novamente

---

## 📞 CHECKLIST DE INSTALAÇÃO

### Servidor Principal:
- [ ] PostgreSQL instalado
- [ ] Banco `pdv_system` criado
- [ ] Migrations executadas
- [ ] Firewall configurado
- [ ] IP do servidor anotado
- [ ] Aplicação instalada
- [ ] Conexão testada com `localhost`
- [ ] Login funcionando

### Terminal Cliente:
- [ ] IP do servidor obtido
- [ ] Ping no servidor funciona
- [ ] Aplicação instalada
- [ ] Conexão configurada com IP do servidor
- [ ] Conexão testada
- [ ] Login funcionando

---

## 🌐 EXEMPLO DE REDE

```
SERVIDOR (192.168.1.10)
├── PostgreSQL rodando
├── Banco: pdv_system
└── Aplicação configurada: host = localhost

TERMINAL 1 (192.168.1.11)
└── Aplicação configurada: host = 192.168.1.10

TERMINAL 2 (192.168.1.12)
└── Aplicação configurada: host = 192.168.1.10

TERMINAL 3 (192.168.1.13)
└── Aplicação configurada: host = 192.168.1.10
```

---

## 📝 CONFIGURAÇÃO RÁPIDA

### Servidor:
```
Host: localhost
Porta: 5432
Banco: pdv_system
Usuário: postgres
Senha: (sua senha)
```

### Terminais:
```
Host: (IP do servidor, ex: 192.168.1.10)
Porta: 5432
Banco: pdv_system
Usuário: postgres
Senha: (senha do servidor)
```

---

## ✅ TESTE FINAL

Após configurar, teste:

1. **Login** - Consegue fazer login?
2. **Vendas** - Consegue registrar uma venda?
3. **Produtos** - Consegue ver lista de produtos?
4. **Sincronização** - Se múltiplos terminais, faça venda em um e veja se aparece no outro

Se tudo funcionar, a instalação está completa! 🎉

---

**Para suporte técnico:**
- Verifique logs no console (se abrir com `cmd posfaturix.exe`)
- Screenshot de erros
- Versão do Windows e PostgreSQL
