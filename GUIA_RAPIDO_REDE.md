# Guia Rápido: Instalação em Rede

## 🚀 Configuração em 5 Passos

### 📍 PASSO 1: Preparar o Servidor (PC com PostgreSQL)

**1.1 - Descobrir o IP do servidor**
```cmd
ipconfig
```
Anote o "Endereço IPv4" (exemplo: `192.168.1.10`)

**1.2 - Editar postgresql.conf**
```
Arquivo: C:\Program Files\PostgreSQL\15\data\postgresql.conf

Encontre e altere:
listen_addresses = '*'
```

**1.3 - Editar pg_hba.conf**
```
Arquivo: C:\Program Files\PostgreSQL\15\data\pg_hba.conf

Adicione no final:
host    all    all    192.168.1.0/24    md5
```

**1.4 - Abrir firewall**
```powershell
# Execute PowerShell como Administrador:
New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
```

**1.5 - Reiniciar PostgreSQL**
```cmd
# Execute cmd como Administrador:
net stop postgresql-x64-15
net start postgresql-x64-15
```

---

### 📍 PASSO 2: Executar Scripts SQL no Servidor

Execute no PostgreSQL (pgAdmin ou psql):

```bash
# 1. Sistema de impressoras de rede
\i database/add_impressora_rede.sql

# 2. Sistema de terminais
\i database/sistema_terminais.sql
```

---

### 📍 PASSO 3: Configurar Terminais (Outros PCs)

**3.1 - Copiar projeto para cada terminal**
- Clone ou copie a pasta do projeto
- NÃO instale PostgreSQL nos terminais!

**3.2 - Editar arquivo de configuração**

Arquivo: `lib/core/database/database_config.dart`

```dart
class DatabaseConfig {
  // ALTERE APENAS ESTA LINHA:
  static const String host = '192.168.1.10'; // IP do servidor!

  // Identifique o terminal:
  static const String terminalNome = 'Caixa 1'; // ou 'Caixa 2', 'Bar', etc.
  static const int? terminalId = 1; // ID do terminal

  // Resto mantém igual ao servidor:
  static const String database = 'pdv_system';
  static const String username = 'postgres';
  static const String password = 'frentex';
}
```

**Exemplo para cada terminal:**

**Terminal 1 (Caixa 1):**
```dart
static const String host = '192.168.1.10';
static const String terminalNome = 'Caixa 1';
static const int? terminalId = 1;
```

**Terminal 2 (Caixa 2):**
```dart
static const String host = '192.168.1.10';
static const String terminalNome = 'Caixa 2';
static const int? terminalId = 2;
```

**Terminal 3 (Bar):**
```dart
static const String host = '192.168.1.10';
static const String terminalNome = 'Bar';
static const int? terminalId = 4;
```

---

### 📍 PASSO 4: Testar Conexão

**4.1 - Do terminal, fazer ping:**
```cmd
ping 192.168.1.10
```
✅ Deve receber respostas

**4.2 - Executar aplicação:**
```bash
flutter run
```
✅ Deve conectar no banco de dados do servidor

---

### 📍 PASSO 5: Configurar Impressoras de Rede

**5.1 - No servidor, compartilhar impressora:**
1. Painel de Controle > Dispositivos e Impressoras
2. Clique direito na impressora > Propriedades > Compartilhamento
3. Marque "Compartilhar esta impressora"
4. Nome: `Cozinha` (por exemplo)

**5.2 - Na aplicação (qualquer terminal):**
1. Admin > Impressoras > ADICIONAR
2. Nome: "Impressora Cozinha"
3. **Caminho de Rede**: `\\192.168.1.10\Cozinha`
4. Salvar

**5.3 - Mapear documentos:**
1. Admin > Mapeamento Impressão
2. Aba "Por Impressora"
3. Selecione a impressora
4. Marque os documentos (ex: Pedido Cozinha, Pedido Bar)

---

## ✅ Checklist Rápido

### No Servidor (PC com PostgreSQL)
- [ ] IP anotado (ex: 192.168.1.10)
- [ ] `postgresql.conf` editado: `listen_addresses = '*'`
- [ ] `pg_hba.conf` editado: linha com `192.168.1.0/24`
- [ ] Firewall: porta 5432 aberta
- [ ] PostgreSQL reiniciado
- [ ] Scripts SQL executados

### Em Cada Terminal
- [ ] Projeto copiado
- [ ] `database_config.dart` editado com IP do servidor
- [ ] Terminal identificado (nome e ID)
- [ ] Ping no servidor funcionando
- [ ] Aplicação conecta e funciona

---

## 🆘 Problemas Comuns

### ❌ Erro: "Could not connect to server"

**Solução:**
```bash
# 1. Verifique se PostgreSQL está rodando no servidor:
netstat -an | findstr 5432

# 2. Teste ping do terminal para servidor:
ping 192.168.1.10

# 3. Verifique firewall do servidor
# Windows Defender > Permitir aplicativo > PostgreSQL
```

### ❌ Erro: "Authentication failed"

**Solução:**
- Verifique senha no `database_config.dart`
- Verifique se `pg_hba.conf` tem linha com `md5`
- Reinicie PostgreSQL

### ❌ Terminal não encontra servidor

**Solução:**
- Todos os PCs devem estar na mesma rede
- Use cabo de rede se WiFi estiver instável
- Verifique se IP está correto com `ipconfig`

---

## 📊 Resumo da Arquitetura

```
SERVIDOR (192.168.1.10)
  └─ PostgreSQL rodando
  └─ Aplicação Flutter
  └─ Impressoras compartilhadas

TERMINAL 1 (192.168.1.101) "Caixa 1"
  └─ Aplicação Flutter
  └─ Conecta em: 192.168.1.10:5432

TERMINAL 2 (192.168.1.102) "Caixa 2"
  └─ Aplicação Flutter
  └─ Conecta em: 192.168.1.10:5432

TERMINAL 3 (192.168.1.103) "Bar"
  └─ Aplicação Flutter
  └─ Conecta em: 192.168.1.10:5432
```

---

## 🎯 Teste Final

1. **No Terminal 1:** Adicione um produto
2. **No Terminal 2:** Verifique se vê o produto
3. **No Terminal 1:** Crie uma mesa
4. **No Terminal 2:** Verifique se vê a mesa

✅ Se funcionar, está tudo configurado!

---

## 📞 Próximos Passos

- Configure backup automático (ver GUIA_INSTALACAO_REDE.md)
- Configure IPs fixos nos terminais
- Teste impressoras compartilhadas
- Monitore performance

**Documentação completa:** Ver arquivo `GUIA_INSTALACAO_REDE.md`
