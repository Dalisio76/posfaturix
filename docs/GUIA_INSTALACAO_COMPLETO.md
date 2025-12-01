# GUIA COMPLETO DE INSTALAÇÃO
# POSFATURIX - Sistema POS Profissional

**Versão:** 1.0.0
**Última Atualização:** Novembro 2025
**Suporte:** suporte@faturix.com

---

## 📑 ÍNDICE

1. [Requisitos do Sistema](#requisitos)
2. [Instalação PostgreSQL](#postgresql)
3. [Instalação PosFaturix](#instalacao)
4. [Configuração Inicial](#configuracao)
5. [Instalação em Rede](#rede)
6. [Solução de Problemas](#problemas)
7. [Backup e Manutenção](#backup)
8. [Perguntas Frequentes](#faq)

---

<a name="requisitos"></a>
## 1️⃣ REQUISITOS DO SISTEMA

### Requisitos Mínimos

**Hardware:**
- Processador: Intel Core i3 ou equivalente
- RAM: 4 GB
- Disco: 500 MB livres
- Resolução: 1024x768

**Software:**
- Windows 10 (64-bit) ou superior
- PostgreSQL 12 ou superior
- Microsoft Visual C++ 2015-2022 Redistributable
- .NET Framework 4.7.2 ou superior

### Requisitos Recomendados

**Hardware:**
- Processador: Intel Core i5 ou superior
- RAM: 8 GB ou mais
- Disco: SSD com 2 GB livres
- Resolução: 1920x1080

**Periféricos:**
- Impressora térmica 80mm (opcional)
- Leitor de código de barras (opcional)
- Tablet/Touch screen (opcional)

### Rede (Multi-Terminal)

**Servidor:**
- Requisitos recomendados
- IP fixo na rede local
- Porta 5432 liberada no firewall

**Terminais:**
- Requisitos mínimos
- Conexão estável com servidor (LAN)
- Latência < 50ms

---

<a name="postgresql"></a>
## 2️⃣ INSTALAÇÃO DO POSTGRESQL

### Passo 1: Download

1. Acesse: https://www.postgresql.org/download/windows/
2. Clique em "Download the installer"
3. Escolha versão **15** ou **16** (recomendado)
4. Baixe versão **64-bit** (~250 MB)

### Passo 2: Instalação

#### 2.1 Iniciar Instalador
- Execute `postgresql-XX-windows-x64.exe`
- Clique "Next"

#### 2.2 Pasta de Instalação
- Deixe padrão: `C:\Program Files\PostgreSQL\15`
- Clique "Next"

#### 2.3 Componentes
Marque TODOS:
- [x] PostgreSQL Server
- [x] pgAdmin 4
- [x] Stack Builder
- [x] Command Line Tools

Clique "Next"

#### 2.4 Diretório de Dados
- Deixe padrão: `C:\Program Files\PostgreSQL\15\data`
- Clique "Next"

#### 2.5 SENHA (IMPORTANTE!)
```
┌────────────────────────────────────┐
│ Password: ___________              │
│ Retype password: ___________       │
└────────────────────────────────────┘
```

⚠️ **IMPORTANTE:**
- Defina uma senha FORTE
- **ANOTE ESTA SENHA!** Você vai precisar
- Exemplo: `postgres2025!`

Clique "Next"

#### 2.6 Porta
- Deixe: **5432**
- Clique "Next"

#### 2.7 Locale
- Escolha: **Portuguese, Brazil** (ou deixe Default)
- Clique "Next"

#### 2.8 Resumo
- Revise configurações
- Clique "Next"

#### 2.9 Aguarde Instalação
- 5-10 minutos
- ✅ Setup has finished installing

#### 2.10 Finalizar
- Desmarque "Stack Builder" (não necessário agora)
- Clique "Finish"

### Passo 3: Verificar Instalação

**Opção A: Via pgAdmin 4**
1. Abra "pgAdmin 4" (Menu Iniciar)
2. Defina senha master (qualquer uma)
3. Expand "Servers" → "PostgreSQL 15"
4. Digite senha do PostgreSQL
5. ✅ Se conectou: Instalação OK!

**Opção B: Via CMD**
```batch
cd "C:\Program Files\PostgreSQL\15\bin"
psql -U postgres -c "SELECT version();"
```
Digite senha. Se mostrar versão: ✅ OK!

### Passo 4: Configurar Firewall (Opcional)

Se for servidor em rede:

```batch
# Abra CMD como Administrador
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
```

---

<a name="instalacao"></a>
## 3️⃣ INSTALAÇÃO DO POSFATURIX

### Passo 1: Obter Instalador

Você deve ter o arquivo:
```
PosFaturix_Setup_1.0.0.exe (~100-150 MB)
```

Fonte:
- Pen drive
- Google Drive / Dropbox
- Email (se compactado)
- Rede local

### Passo 2: Executar Instalador

1. Localize `PosFaturix_Setup_1.0.0.exe`
2. **Clique DIREITO** → **Executar como Administrador**
3. Se aparecer "Windows protegeu seu computador":
   - Clique "Mais informações"
   - Clique "Executar assim mesmo"

### Passo 3: Assistente de Instalação

#### 3.1 Tela de Boas-Vindas
```
┌──────────────────────────────────────────┐
│ Bem-vindo ao PosFaturix                  │
│                                          │
│ Este assistente irá instalar o           │
│ PosFaturix no seu computador.            │
│                                          │
│ IMPORTANTE: Certifique-se de que o       │
│ PostgreSQL está instalado!               │
└──────────────────────────────────────────┘

[Cancelar]  [Avançar >]
```

Clique **"Avançar"**

#### 3.2 Pasta de Instalação
```
┌──────────────────────────────────────────┐
│ Pasta de destino                         │
│                                          │
│ C:\Program Files\PosFaturix              │
│                         [Procurar...]    │
│                                          │
│ Espaço necessário: 150 MB                │
│ Espaço disponível: 50 GB                 │
└──────────────────────────────────────────┘

[< Voltar]  [Avançar >]  [Cancelar]
```

- Deixe pasta padrão (recomendado)
- Clique **"Avançar"**

#### 3.3 Configuração PostgreSQL ⭐ IMPORTANTE
```
┌──────────────────────────────────────────┐
│ Configuração da Base de Dados            │
│                                          │
│ Servidor PostgreSQL (host):              │
│ ┌──────────────────────────┐             │
│ │ localhost                │             │
│ └──────────────────────────┘             │
│                                          │
│ Porta:                                   │
│ ┌──────────────────────────┐             │
│ │ 5432                     │             │
│ └──────────────────────────┘             │
│                                          │
│ Nome da base de dados:                   │
│ ┌──────────────────────────┐             │
│ │ pdv_system               │             │
│ └──────────────────────────┘             │
│                                          │
│ Usuário PostgreSQL:                      │
│ ┌──────────────────────────┐             │
│ │ postgres                 │             │
│ └──────────────────────────┘             │
│                                          │
│ Senha PostgreSQL:                        │
│ ┌──────────────────────────┐             │
│ │ ●●●●●●●●●●●●             │             │
│ └──────────────────────────┘             │
└──────────────────────────────────────────┘

[< Voltar]  [Avançar >]  [Cancelar]
```

**Preencha:**
- **Servidor:** `localhost` (se instalado localmente)
- **Porta:** `5432` (padrão)
- **Database:** `pdv_system` (não mude!)
- **Usuário:** `postgres` (padrão)
- **Senha:** [senha que você definiu no PostgreSQL]

Clique **"Avançar"**

#### 3.4 Usuário Administrador ⭐ IMPORTANTE
```
┌──────────────────────────────────────────┐
│ Usuário Administrador                    │
│                                          │
│ Crie o usuário super administrador       │
│ do sistema.                              │
│                                          │
│ Nome do administrador:                   │
│ ┌──────────────────────────┐             │
│ │ Admin                    │             │
│ └──────────────────────────┘             │
│                                          │
│ Código de acesso (4 dígitos):           │
│ ┌──────────────────────────┐             │
│ │ 0000                     │             │
│ └──────────────────────────┘             │
│                                          │
│ Este código será usado para fazer        │
│ login no sistema.                        │
└──────────────────────────────────────────┘

[< Voltar]  [Avançar >]  [Cancelar]
```

**Preencha:**
- **Nome:** `Admin` (ou outro de sua escolha)
- **Código:** `0000` (ou escolha 4 dígitos)

⚠️ **ANOTE ESTE CÓDIGO!** É o login do administrador.

Clique **"Avançar"**

#### 3.5 Atalhos e Opções
```
┌──────────────────────────────────────────┐
│ Selecione tarefas adicionais:            │
│                                          │
│ [x] Criar atalho na Área de Trabalho    │
│ [x] Criar atalho na Barra de Tarefas    │
│ [ ] Iniciar com o Windows                │
└──────────────────────────────────────────┘

[< Voltar]  [Instalar]  [Cancelar]
```

Marque conforme preferência.

Clique **"Instalar"**

#### 3.6 Aguarde Instalação
```
Instalando PosFaturix...
████████████████████ 100%

Copiando arquivos...
Criando atalhos...
Registrando aplicação...
```

Tempo: 1-3 minutos

#### 3.7 Concluído!
```
┌──────────────────────────────────────────┐
│ Concluindo o Assistente                  │
│                                          │
│ O PosFaturix foi instalado com sucesso!  │
│                                          │
│ [x] Executar PosFaturix agora            │
│ [x] Ver instruções de configuração       │
└──────────────────────────────────────────┘

[< Voltar]  [Concluir]
```

Marque as opções e clique **"Concluir"**

---

<a name="configuracao"></a>
## 4️⃣ CONFIGURAÇÃO INICIAL

### Passo 1: Configurar Base de Dados

Após instalação, abrirá automaticamente:

```batch
========================================================
   POSFATURIX - CONFIGURADOR DE BASE DE DADOS
========================================================

Diretorio: C:\Program Files\PosFaturix

[INFO] PostgreSQL nao esta no PATH. Procurando...
[OK] PostgreSQL 18 encontrado!
Usando: C:\Program Files\PostgreSQL\18\bin

Configurações:
  Servidor: localhost:5432
  Database: pdv_system
  Usuário: postgres
  Admin: Admin (código: 0000)

Deseja continuar? (S/N): _
```

**Digite:** `S` e pressione **Enter**

O script vai:
1. ✅ Criar database `pdv_system`
2. ✅ Executar script SQL inicial
3. ✅ Criar todas as tabelas
4. ✅ Inserir dados iniciais
5. ✅ Configurar usuário admin

Aguarde... (~30 segundos)

```
========================================================
  CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!
========================================================

Base de dados: pdv_system
Servidor: localhost:5432
Usuário Admin: Admin
Código Admin: 0000

PRÓXIMOS PASSOS:
1. Inicie o PosFaturix
2. Faça login com o código: 0000
3. Configure impressoras em Admin > Configurações
4. Adicione produtos e famílias
```

Pressione qualquer tecla.

### Passo 2: Primeiro Acesso

1. **Iniciar PosFaturix**
   - Clique no ícone da Área de Trabalho
   - OU Menu Iniciar → PosFaturix

2. **Tela de Login**
   ```
   ┌─────────────────────────────────────┐
   │        POSFATURIX - LOGIN           │
   │                                     │
   │     Digite seu código:              │
   │     ┌─────────────────┐             │
   │     │                 │             │
   │     └─────────────────┘             │
   │                                     │
   │         [ ENTRAR ]                  │
   └─────────────────────────────────────┘
   ```

3. **Digite:** `0000` (ou código que você definiu)
4. **Pressione Enter** ou clique "ENTRAR"
5. ✅ **Sistema aberto!**

### Passo 3: Configuração Inicial

#### 3.1 Configurar Empresa
1. Clique em **Admin** (topo)
2. Aba **"Empresa"**
3. Preencha:
   - Nome da empresa
   - NIF/CNPJ
   - Morada
   - Telefone
   - Email
4. Clique **"Salvar"**

#### 3.2 Adicionar Setores
1. Aba **"Setores"**
2. Clique **"+ Novo Setor"**
3. Preencha:
   - Nome: "Bebidas"
   - Cor: Azul
4. Repita para: "Comidas", "Sobremesas"

#### 3.3 Adicionar Famílias
1. Aba **"Famílias"**
2. Clique **"+ Nova Família"**
3. Preencha:
   - Nome: "Refrigerantes"
   - Setor: "Bebidas"
4. Repita para outras categorias

#### 3.4 Adicionar Produtos
1. Aba **"Produtos"**
2. Clique **"+ Novo Produto"**
3. Preencha:
   - Código: "001"
   - Nome: "Coca-Cola 350ml"
   - Família: "Refrigerantes"
   - Preço: 2.50
   - Estoque: 100
4. Salvar
5. Repita para outros produtos

#### 3.5 Configurar Impressora (Opcional)
1. Aba **"Configurações"**
2. Seção **"Impressoras"**
3. Clique **"Ver Impressoras do Windows"**
4. Copie nome EXATO da impressora
5. Cole em **"Impressora Padrão"**
6. Marque **"Perguntar antes de imprimir"** (recomendado)
7. Salvar

---

<a name="rede"></a>
## 5️⃣ INSTALAÇÃO EM REDE (MÚLTIPLOS TERMINAIS)

### Arquitetura

```
┌─────────────────┐
│    SERVIDOR     │
│                 │
│  PostgreSQL     │
│  PosFaturix     │
│                 │
│  IP: 192.168.1.10│
└────────┬────────┘
         │ LAN
    ─────┴─────────────────
    │        │        │
┌───┴──┐ ┌───┴──┐ ┌───┴──┐
│Caixa1│ │Caixa2│ │  Bar │
│      │ │      │ │      │
│→DB   │ │→DB   │ │→DB   │
└──────┘ └──────┘ └──────┘
```

### Configuração do SERVIDOR

#### Passo 1: Descobrir IP
```batch
# Abra CMD
ipconfig
```

Procure:
```
Ethernet adapter:
   IPv4 Address: 192.168.1.10
```

**Anote este IP!**

#### Passo 2: PostgreSQL Aceitar Conexões

**2.1 Editar postgresql.conf**
```batch
# Abra com Notepad++
C:\Program Files\PostgreSQL\15\data\postgresql.conf
```

Encontre (linha ~59):
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

Adicione no FINAL:
```conf
# Rede local
host    all    all    192.168.1.0/24    md5
```

Salve.

**2.3 Reiniciar PostgreSQL**
```batch
# Painel de Controle → Ferramentas Administrativas → Serviços
# Localize: postgresql-x64-15
# Clique direito → Reiniciar
```

OU via CMD (Admin):
```batch
net stop postgresql-x64-15
net start postgresql-x64-15
```

#### Passo 3: Liberar Firewall
```batch
# CMD como Administrador
netsh advfirewall firewall add rule name="PostgreSQL" dir=in action=allow protocol=TCP localport=5432
```

#### Passo 4: Testar de Outro PC
```batch
# Em outro PC na rede
telnet 192.168.1.10 5432
```

Se conectar: ✅ OK!

### Configuração dos TERMINAIS

#### Método 1: Durante Instalação

Na tela "Configuração PostgreSQL":
- **Servidor:** `192.168.1.10` (IP do servidor)
- **Porta:** `5432`
- **Database:** `pdv_system`
- **Usuário:** `postgres`
- **Senha:** [senha do servidor]

Resto normal. ✅

#### Método 2: Após Instalação

1. Abra arquivo de configuração:
   ```
   C:\Program Files\PosFaturix\lib\core\database\database_config.dart
   ```

2. Edite com Notepad++:
   ```dart
   static const String host = '192.168.1.10'; // IP do servidor
   static const String terminalNome = 'Caixa 2'; // Nome deste terminal
   ```

3. Salve

4. Reinicie PosFaturix

---

<a name="problemas"></a>
## 6️⃣ SOLUÇÃO DE PROBLEMAS

### Problema: "VCRUNTIME140.dll não encontrado"

**Causa:** Visual C++ Redistributable não instalado

**Solução:**
1. Baixe: https://aka.ms/vs/17/release/vc_redist.x64.exe
2. Execute e instale
3. Reinicie PosFaturix

### Problema: "Não é possível conectar à base de dados"

**Verificações:**

**1. PostgreSQL está rodando?**
```batch
# Serviços → postgresql-x64-15 → Status: "Em execução"
```

Se não, clique direito → Iniciar

**2. Senha está correta?**
```batch
# Teste via pgAdmin 4
# Se não conseguir conectar, senha está errada
```

**3. Database foi criada?**
```batch
# Menu Iniciar → PosFaturix → Configurar Base de Dados
```

**4. Firewall bloqueando?**
```batch
# Desative temporariamente para testar
```

### Problema: "PostgreSQL não encontrado"

**Solução:**
1. Execute: `C:\Program Files\PosFaturix\encontrar_postgresql.bat`
2. Ver onde PostgreSQL está instalado
3. Informar caminho manualmente quando pedido

### Problema: "Impressora não imprime"

**Verificações:**

1. **Impressora configurada?**
   - Admin → Configurações → Impressoras
   - Nome EXATO da impressora

2. **Teste de impressão Windows?**
   - Painel Controle → Dispositivos → Impressoras
   - Clique direito → Imprimir página de teste

3. **Impressora térmica?**
   - Pode ter limite de buffer
   - Teste com menos itens

---

<a name="backup"></a>
## 7️⃣ BACKUP E MANUTENÇÃO

### Backup Manual

**Via pgAdmin 4:**
1. Abra pgAdmin 4
2. Conecte ao servidor
3. Clique direito em `pdv_system`
4. **Backup...**
5. Filename: `C:\Backups\pdv_backup_2025-11-30.sql`
6. Format: **Plain**
7. Click **Backup**

**Via Linha de Comando:**
```batch
cd "C:\Program Files\PostgreSQL\15\bin"
pg_dump -U postgres -d pdv_system > C:\Backups\backup.sql
```

### Backup Automático (Recomendado)

Crie script `.bat`:
```batch
@echo off
set DATA=%date:~-4%-%date:~3,2%-%date:~0,2%
set PASTA=C:\Backups\PosFaturix
mkdir %PASTA% 2>nul

cd "C:\Program Files\PostgreSQL\15\bin"
pg_dump -U postgres -d pdv_system > "%PASTA%\pdv_%DATA%.sql"

echo Backup criado: %PASTA%\pdv_%DATA%.sql
```

**Agendar no Windows:**
1. Tarefe agendador → Criar tarefa
2. Nome: "Backup PosFaturix"
3. Gatilho: Diário, 23:00
4. Ação: Executar script acima

### Restaurar Backup

**Via pgAdmin:**
1. Clique direito em `pdv_system`
2. **Restore...**
3. Filename: Escolha arquivo `.sql`
4. Click **Restore**

**Via CMD:**
```batch
cd "C:\Program Files\PostgreSQL\15\bin"
psql -U postgres -d pdv_system < C:\Backups\backup.sql
```

---

<a name="faq"></a>
## 8️⃣ PERGUNTAS FREQUENTES

**Q: Preciso pagar licença do PostgreSQL?**
R: Não! PostgreSQL é 100% gratuito e open source.

**Q: Posso instalar em Windows 11?**
R: Sim! Funciona perfeitamente.

**Q: Quantos terminais posso ter?**
R: Ilimitado, desde que o servidor suporte a carga.

**Q: Preciso de internet?**
R: Não para uso local. Apenas rede local para multi-terminal.

**Q: Como atualizar para nova versão?**
R: Execute novo instalador. Database não será afetada.

**Q: Posso mudar a senha do admin depois?**
R: Sim, em Admin → Usuários → Editar.

**Q: E se esquecer a senha do PostgreSQL?**
R: Precisa reinstalar PostgreSQL ou resetar senha (avançado).

**Q: Funciona offline?**
R: Sim! Não precisa internet.

**Q: Posso usar em tablet Windows?**
R: Sim! Interface é touch-optimized.

**Q: Emite nota fiscal?**
R: Atualmente não. Funcionalidade futura.

---

## 📞 SUPORTE

**Documentação:**
- Memória Descritiva: `docs/MEMORIA_DESCRITIVA_POSFATURIX.md`
- Este guia: `docs/GUIA_INSTALACAO_COMPLETO.md`

**Contato:**
- Email: suporte@faturix.com
- GitHub: github.com/faturix/posfaturix

---

## ✅ CHECKLIST DE INSTALAÇÃO

Marque conforme completa:

### Pré-Instalação
- [ ] Windows 10+ (64-bit)
- [ ] 4GB RAM
- [ ] 500MB disco livre
- [ ] PostgreSQL baixado

### Instalação PostgreSQL
- [ ] PostgreSQL instalado
- [ ] Senha definida e anotada
- [ ] Porta 5432
- [ ] pgAdmin funciona

### Instalação PosFaturix
- [ ] Instalador executado como Admin
- [ ] Configuração PostgreSQL correta
- [ ] Usuário admin criado e anotado
- [ ] Atalhos criados

### Configuração
- [ ] Configurador de database executado
- [ ] Login funciona (código admin)
- [ ] Empresa configurada
- [ ] Produtos adicionados
- [ ] Impressora configurada (se aplicável)

### Testes
- [ ] Venda direta funciona
- [ ] Impressão funciona
- [ ] Fecho de caixa funciona
- [ ] Mesa funciona (se usar)

### Produção
- [ ] Backup configurado
- [ ] Usuários adicionados
- [ ] Permissões configuradas
- [ ] Rede funcionando (se aplicável)

---

**Sistema pronto para uso! 🚀**

_Boas vendas com PosFaturix!_
