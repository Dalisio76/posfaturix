# Guia: Instalação em Rede - Múltiplos Terminais

## 🎯 Objetivo

Configurar múltiplos computadores (terminais) para usar a mesma base de dados PostgreSQL, permitindo que:
- Vários caixas funcionem simultaneamente
- Todos vejam as mesmas vendas, mesas, produtos em tempo real
- Impressoras compartilhadas funcionem corretamente

## 🏗️ Arquitetura Recomendada

```
┌─────────────────────────────────────────────────────────┐
│                    REDE LOCAL (LAN)                      │
│                  192.168.1.0/24                          │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────┐         ┌──────────────────┐       │
│  │  SERVIDOR       │         │  TERMINAL 1      │       │
│  │  PostgreSQL     │◄────────┤  (Caixa 1)       │       │
│  │  192.168.1.10   │         │  192.168.1.101   │       │
│  │                 │         │  Flutter App     │       │
│  │  - Banco Dados  │         └──────────────────┘       │
│  │  - Backup Auto  │                                     │
│  │  - Impressora   │         ┌──────────────────┐       │
│  │    Cozinha      │◄────────┤  TERMINAL 2      │       │
│  └─────────────────┘         │  (Caixa 2)       │       │
│           ▲                  │  192.168.1.102   │       │
│           │                  │  Flutter App     │       │
│           │                  └──────────────────┘       │
│           │                                             │
│           │                  ┌──────────────────┐       │
│           └──────────────────┤  TERMINAL 3      │       │
│                              │  (Bar)           │       │
│                              │  192.168.1.103   │       │
│                              │  Flutter App     │       │
│                              └──────────────────┘       │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 📋 Requisitos

### Hardware
- **Servidor**: PC dedicado ou PC mais robusto
  - RAM: Mínimo 4GB (recomendado 8GB)
  - HD: SSD recomendado para melhor performance
  - Rede: Conexão cabeada (Ethernet) preferível

- **Terminais**: PCs que vão rodar o aplicativo
  - RAM: Mínimo 4GB
  - Rede: WiFi ou Ethernet

### Rede
- Router/Switch com DHCP ou IPs fixos
- Todos os dispositivos na mesma rede local
- Portas abertas: 5432 (PostgreSQL)

## 🔧 Passo a Passo - Configuração

### PARTE 1: Configurar Servidor PostgreSQL

#### 1.1 - Escolher o Computador Servidor
Escolha o PC que será o servidor (recomendado: o mais potente e estável).

**Exemplo:**
- IP do Servidor: `192.168.1.10`
- Nome do Computador: `SERVIDOR-POS`

#### 1.2 - Configurar IP Fixo (Recomendado)

**Windows:**
1. Painel de Controle > Rede e Internet > Central de Rede
2. Alterar configurações do adaptador
3. Clique direito em sua conexão > Propriedades
4. Selecione "Protocolo IP Versão 4 (TCP/IPv4)" > Propriedades
5. Configure:
   - IP: `192.168.1.10`
   - Máscara: `255.255.255.0`
   - Gateway: `192.168.1.1` (IP do seu router)
   - DNS: `8.8.8.8` e `8.8.4.4`

#### 1.3 - Configurar PostgreSQL para Aceitar Conexões Remotas

**Localizar arquivo de configuração:**
```
Windows: C:\Program Files\PostgreSQL\15\data\postgresql.conf
Linux: /etc/postgresql/15/main/postgresql.conf
```

**Editar postgresql.conf:**
```conf
# Encontre a linha:
#listen_addresses = 'localhost'

# Altere para:
listen_addresses = '*'

# Salve o arquivo
```

#### 1.4 - Configurar Autenticação de Rede

**Localizar arquivo pg_hba.conf:**
```
Windows: C:\Program Files\PostgreSQL\15\data\pg_hba.conf
Linux: /etc/postgresql/15/main/pg_hba.conf
```

**Adicionar ao final do arquivo:**
```conf
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Permitir conexões da rede local
host    all             all             192.168.1.0/24          md5

# Se usar outra faixa de IP, ajuste (ex: 192.168.0.0/24)
```

**Explicação:**
- `192.168.1.0/24` = permite IPs de 192.168.1.1 até 192.168.1.254
- `md5` = exige senha para conectar

#### 1.5 - Reiniciar PostgreSQL

**Windows (como Administrador):**
```cmd
net stop postgresql-x64-15
net start postgresql-x64-15
```

**Linux:**
```bash
sudo systemctl restart postgresql
```

#### 1.6 - Abrir Firewall

**Windows:**
1. Painel de Controle > Firewall do Windows
2. Configurações Avançadas
3. Regras de Entrada > Nova Regra
4. Tipo: Porta
5. TCP, Porta: 5432
6. Permitir conexão
7. Nome: "PostgreSQL Remoto"

**Comando rápido (PowerShell como Admin):**
```powershell
New-NetFirewallRule -DisplayName "PostgreSQL" -Direction Inbound -LocalPort 5432 -Protocol TCP -Action Allow
```

**Linux (Ubuntu/Debian):**
```bash
sudo ufw allow 5432/tcp
```

### PARTE 2: Testar Conexão do Servidor

#### 2.1 - Descobrir o IP do Servidor

**Windows:**
```cmd
ipconfig
```
Procure por "Endereço IPv4" - exemplo: `192.168.1.10`

**Linux:**
```bash
ip addr show
# ou
ifconfig
```

#### 2.2 - Testar Conexão Local

No próprio servidor, teste:
```bash
psql -h 192.168.1.10 -U postgres -d posfaturix
```

Se conectar com sucesso ✅, continue.

### PARTE 3: Configurar Terminais (Clientes)

#### 3.1 - Instalar Aplicação Flutter

Em cada terminal (Caixa 1, Caixa 2, Bar, etc.):

1. **Clone ou copie o projeto:**
   ```bash
   git clone <seu-repositorio>
   # ou copie a pasta do projeto
   ```

2. **NÃO instale PostgreSQL nos terminais!**
   - Apenas o servidor precisa do PostgreSQL instalado
   - Os terminais só precisam do Flutter e da aplicação

#### 3.2 - Configurar String de Conexão

Localize o arquivo de configuração da conexão com o banco:

**Arquivo:** `lib/core/services/database_service.dart` (ou similar)

**Procure por algo como:**
```dart
final connectionString = 'postgresql://usuario:senha@localhost:5432/posfaturix';
```

**Altere para o IP do SERVIDOR:**
```dart
final connectionString = 'postgresql://usuario:senha@192.168.1.10:5432/posfaturix';
```

**Exemplo completo:**
```dart
class DatabaseService {
  static String getConnectionString() {
    // IP do servidor PostgreSQL
    const servidor = '192.168.1.10';
    const porta = 5432;
    const database = 'posfaturix';
    const usuario = 'postgres';
    const senha = 'sua_senha_aqui';

    return 'postgresql://$usuario:$senha@$servidor:$porta/$database';
  }
}
```

#### 3.3 - Criar Arquivo de Configuração (Recomendado)

Crie um arquivo `.env` ou `config.json` para não expor senhas no código:

**Opção 1: Criar `assets/config.json`**
```json
{
  "database": {
    "host": "192.168.1.10",
    "port": 5432,
    "database": "posfaturix",
    "username": "postgres",
    "password": "sua_senha"
  },
  "terminal": {
    "nome": "Caixa 1",
    "id": 1
  }
}
```

**No código, carregue:**
```dart
import 'dart:convert';
import 'package:flutter/services.dart';

Future<Map<String, dynamic>> loadConfig() async {
  final configString = await rootBundle.loadString('assets/config.json');
  return json.decode(configString);
}
```

#### 3.4 - Testar Conexão do Terminal

1. Execute a aplicação no terminal
2. Observe os logs para erros de conexão
3. Se conectar ✅, o terminal está configurado!

### PARTE 4: Configuração Avançada

#### 4.1 - Identificar Cada Terminal

Para saber qual terminal fez cada venda/operação:

**Adicionar na tabela de usuários ou criar tabela de terminais:**
```sql
-- Criar tabela de terminais
CREATE TABLE terminais (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL,
    ip_address VARCHAR(15),
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Inserir terminais
INSERT INTO terminais (nome, ip_address) VALUES
    ('Caixa 1', '192.168.1.101'),
    ('Caixa 2', '192.168.1.102'),
    ('Bar', '192.168.1.103');
```

**No Flutter, salvar terminal_id nas vendas:**
```dart
// Detectar IP do terminal
import 'dart:io';

Future<String> getLocalIP() async {
  for (var interface in await NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return 'unknown';
}
```

#### 4.2 - Backup Automático

No servidor, configure backup automático:

**Windows - Criar arquivo `backup_pos.bat`:**
```batch
@echo off
set PGPASSWORD=sua_senha
set DATA=%date:~-4,4%%date:~-10,2%%date:~-7,2%
"C:\Program Files\PostgreSQL\15\bin\pg_dump" -U postgres -h localhost posfaturix > "C:\Backups\posfaturix_%DATA%.sql"
```

**Agendar no Windows:**
1. Abra "Agendador de Tarefas"
2. Criar Tarefa Básica
3. Nome: "Backup POS"
4. Gatilho: Diariamente às 23:00
5. Ação: Executar `backup_pos.bat`

**Linux - Criar script `backup_pos.sh`:**
```bash
#!/bin/bash
DATA=$(date +%Y%m%d)
pg_dump -U postgres posfaturix > /backup/posfaturix_$DATA.sql
```

**Agendar com cron:**
```bash
crontab -e
# Adicionar linha:
0 23 * * * /home/user/backup_pos.sh
```

## 🧪 Teste Completo de Rede

### Teste 1: Conectividade Básica

**Do terminal, fazer ping no servidor:**
```cmd
ping 192.168.1.10
```
Deve receber respostas ✅

### Teste 2: Porta PostgreSQL

**Testar se porta 5432 está aberta:**
```cmd
telnet 192.168.1.10 5432
```
Deve conectar ✅

### Teste 3: Conexão PostgreSQL

**Do terminal, conectar via psql (se tiver instalado):**
```bash
psql -h 192.168.1.10 -U postgres -d posfaturix
```
Pede senha e conecta ✅

### Teste 4: Aplicação Flutter

1. Execute app no Terminal 1
2. Adicione um produto
3. Execute app no Terminal 2
4. Verifique se vê o produto adicionado ✅

### Teste 5: Concorrência

1. Abra a mesma mesa em 2 terminais
2. Adicione produtos em ambos
3. Verifique se ambos atualizam corretamente ✅

## ⚠️ Problemas Comuns

### Erro: "Could not connect to server"

**Causas:**
- Firewall bloqueando porta 5432
- PostgreSQL não está escutando em todas as interfaces
- IP do servidor errado

**Soluções:**
1. Verifique `postgresql.conf`: `listen_addresses = '*'`
2. Verifique firewall (Windows Defender ou outro)
3. Ping no servidor para testar conectividade
4. Verifique se PostgreSQL está rodando: `netstat -an | findstr 5432`

### Erro: "Authentication failed"

**Causas:**
- Senha incorreta
- pg_hba.conf não permite conexões da rede

**Soluções:**
1. Verifique usuário e senha
2. Verifique `pg_hba.conf` tem linha: `host all all 192.168.1.0/24 md5`
3. Reinicie PostgreSQL após mudanças

### Performance Lenta

**Causas:**
- WiFi fraco
- Servidor sem recursos
- Muitas conexões abertas

**Soluções:**
1. Use cabo de rede (Ethernet) ao invés de WiFi
2. Aumente RAM do servidor
3. Configure connection pooling no PostgreSQL
4. Otimize queries com índices

### Conflitos de Dados

**Problema:** Dois terminais editam mesma mesa simultaneamente

**Solução - Implementar bloqueio otimista:**
```sql
-- Adicionar coluna version nas tabelas críticas
ALTER TABLE mesas ADD COLUMN version INTEGER DEFAULT 0;

-- No UPDATE, verificar version
UPDATE mesas
SET status = @status, version = version + 1
WHERE id = @id AND version = @expected_version;

-- Se affected_rows = 0, alguém já modificou
```

## 🔒 Segurança

### Recomendações Básicas

1. **Senha Forte:** Use senha complexa para PostgreSQL
2. **Firewall:** Bloqueie porta 5432 para Internet (apenas LAN)
3. **Usuários Separados:** Crie usuário específico para a aplicação
4. **Backup:** Configure backup automático diário
5. **VPN:** Se precisar acesso remoto, use VPN

### Criar Usuário Específico

```sql
-- Criar usuário para aplicação
CREATE USER pos_app WITH PASSWORD 'senha_forte_aqui';

-- Dar permissões apenas no banco posfaturix
GRANT CONNECT ON DATABASE posfaturix TO pos_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pos_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pos_app;

-- Usar na connection string:
-- postgresql://pos_app:senha_forte@192.168.1.10:5432/posfaturix
```

## 📊 Monitoramento

### Ver Conexões Ativas

```sql
SELECT
    pid,
    usename,
    application_name,
    client_addr,
    state,
    query_start
FROM pg_stat_activity
WHERE datname = 'posfaturix';
```

### Ver Queries Lentas

```sql
SELECT
    pid,
    now() - query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;
```

## 📝 Checklist Final

### No Servidor
- [ ] PostgreSQL instalado e rodando
- [ ] IP fixo configurado (ex: 192.168.1.10)
- [ ] `postgresql.conf`: `listen_addresses = '*'`
- [ ] `pg_hba.conf`: linha com `192.168.1.0/24`
- [ ] Firewall permite porta 5432
- [ ] PostgreSQL reiniciado
- [ ] Backup automático configurado

### Em Cada Terminal
- [ ] Flutter SDK instalado
- [ ] Aplicação copiada
- [ ] Connection string aponta para IP do servidor
- [ ] Consegue pingar o servidor
- [ ] Aplicação conecta e funciona
- [ ] Identificação do terminal configurada

### Testes
- [ ] Ping entre servidor e terminais
- [ ] Conexão PostgreSQL funcionando
- [ ] Múltiplos terminais veem mesmos dados
- [ ] Impressoras compartilhadas funcionam
- [ ] Performance aceitável

## 🎯 Próximos Passos

1. Configure primeiro em 2 PCs (servidor + 1 terminal) para testar
2. Adicione mais terminais gradualmente
3. Monitore performance
4. Ajuste configurações conforme necessário

---

**Dúvidas?** Teste cada passo e verifique os logs para identificar problemas!
