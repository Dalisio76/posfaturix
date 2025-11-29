# Análise de Fragilidades e Vulnerabilidades do Sistema
## POS Faturix - Auditoria de Segurança

---

## 🔴 CRÍTICAS (Prioridade Máxima)

### 1. **Senha Hardcoded no Código**
**Localização:** `lib/core/database/database_config.dart`

```dart
static const String password = 'frentex'; // SENHA EXPOSTA!
```

**Risco:** ⚠️ **CRÍTICO**
- Senha do banco de dados exposta no código-fonte
- Qualquer pessoa com acesso ao código tem acesso total ao banco
- Senha visível no Git/GitHub se repositório for público

**Solução:**
1. Usar variáveis de ambiente
2. Arquivo de configuração `.env` (NÃO commit no Git)
3. Prompt para senha na primeira execução
4. Encryption de credenciais

**Implementação:**
```dart
// Usar dotenv ou flutter_secure_storage
import 'package:flutter_dotenv/flutter_dotenv.dart';

static String get password => dotenv.env['DB_PASSWORD'] ?? '';
```

---

### 2. **Sem Controle de Acesso (Authorization)**
**Problema:** Qualquer usuário logado pode acessar qualquer funcionalidade

**Riscos:**
- Funcionário do bar pode acessar relatórios financeiros
- Caixa pode deletar produtos
- Sem audit trail de quem fez o quê

**Solução Implementada:** Sistema de permissões por usuário
**Falta:** Validação rigorosa em TODAS as operações críticas

**Recomendação:**
```sql
-- Adicionar verificação em cada operação crítica
CREATE OR REPLACE FUNCTION verificar_permissao(
    p_usuario_id INTEGER,
    p_permissao VARCHAR(50)
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM usuarios
        WHERE id = p_usuario_id
          AND permissoes @> ARRAY[p_permissao]::VARCHAR[]
    );
END;
$$ LANGUAGE plpgsql;

-- Usar em triggers:
IF NOT verificar_permissao(current_user_id, 'deletar_produtos') THEN
    RAISE EXCEPTION 'Sem permissão!';
END IF;
```

---

### 3. **SQL Injection Potencial**
**Problema:** Se queries forem construídas com concatenação de strings

**Verificar em:** Todos os repositórios

**Exemplo INSEGURO:**
```dart
// NUNCA FAZER ISSO:
final query = "SELECT * FROM produtos WHERE nome = '${nome}'";
```

**Exemplo SEGURO (atual):**
```dart
// Usando parâmetros (OK):
await _db.query(
  'SELECT * FROM produtos WHERE nome = @nome',
  parameters: {'nome': nome},
);
```

**Status:** ✅ **BOM** - Código atual usa parâmetros
**Ação:** Revisar TODOS os repositórios para garantir

---

### 4. **Alteração de Data do Sistema**
**Status:** ✅ **CORRIGIDO AGORA**
- Implementado `sistema_controle_tempo.sql`
- Trigger que impede vendas retroativas
- Validação de fecho de caixa

**Ainda Falta:**
- Testar exaustivamente
- Adicionar validação no frontend antes de enviar
- Alertas visuais quando detectar problema

---

## 🟠 ALTAS (Prioridade Alta)

### 5. **Sem Backup Automático**
**Problema:** Perda de dados em caso de falha

**Risco:**
- HD queima = Perda total de dados
- Sem histórico de vendas
- Impossível recuperar

**Solução:** Implementar backup automático
- Diário (mínimo)
- Semanal offsite (recomendado)
- Mensal em nuvem (ideal)

**Script fornecido:** Ver `GUIA_INSTALACAO_REDE.md` seção "Backup Automático"

---

### 6. **Sem Auditoria (Audit Trail)**
**Problema:** Não há registro de quem alterou o quê e quando

**Exemplos:**
- Quem deletou o produto X?
- Quem alterou o preço do produto Y?
- Quem deu desconto na venda Z?

**Solução:**
```sql
-- Criar tabela de auditoria
CREATE TABLE auditoria (
    id SERIAL PRIMARY KEY,
    tabela VARCHAR(50),
    operacao VARCHAR(10), -- INSERT, UPDATE, DELETE
    registro_id INTEGER,
    usuario_id INTEGER,
    dados_antes JSONB,
    dados_depois JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Trigger genérico de auditoria
CREATE OR REPLACE FUNCTION registrar_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO auditoria (tabela, operacao, registro_id, dados_antes, dados_depois)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        COALESCE(NEW.id, OLD.id),
        row_to_json(OLD),
        row_to_json(NEW)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar em tabelas críticas:
CREATE TRIGGER trigger_auditoria_produtos
    AFTER INSERT OR UPDATE OR DELETE ON produtos
    FOR EACH ROW EXECUTE FUNCTION registrar_auditoria();
```

---

### 7. **Conexão PostgreSQL Sem SSL**
**Problema:** Dados trafegam em texto claro pela rede

**Risco:** Sniffing de rede pode capturar:
- Senhas
- Dados de vendas
- Informações de clientes

**Solução:**
```dart
// Adicionar SSL à connection string:
final connectionString = 'postgresql://$user:$pass@$host:$port/$db?sslmode=require';
```

No servidor PostgreSQL:
```conf
# postgresql.conf
ssl = on
ssl_cert_file = 'server.crt'
ssl_key_file = 'server.key'
```

---

### 8. **Sem Limite de Tentativas de Login**
**Problema:** Brute force attack possível

**Risco:** Testar milhares de senhas até acertar

**Solução:**
```sql
-- Tabela de tentativas de login
CREATE TABLE login_attempts (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    ip_address VARCHAR(45),
    sucesso BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Função para verificar
CREATE OR REPLACE FUNCTION pode_tentar_login(p_username VARCHAR(50))
RETURNS BOOLEAN AS $$
DECLARE
    tentativas INTEGER;
BEGIN
    -- Contar tentativas falhadas nas últimas 15 minutos
    SELECT COUNT(*) INTO tentativas
    FROM login_attempts
    WHERE username = p_username
      AND sucesso = false
      AND created_at > (CURRENT_TIMESTAMP - INTERVAL '15 minutes');

    -- Bloquear após 5 tentativas
    RETURN tentativas < 5;
END;
$$ LANGUAGE plpgsql;
```

---

## 🟡 MÉDIAS (Prioridade Média)

### 9. **Senhas Armazenadas em Texto Claro**
**Problema:** Tabela `usuarios` armazena senhas sem hash

**Risco:** Se banco vazar, todas as senhas são expostas

**Solução:**
```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashSenha(String senha) {
  final bytes = utf8.encode(senha);
  final hash = sha256.convert(bytes);
  return hash.toString();
}

// No registro:
final senhaHash = hashSenha(senhaTextoClaro);

// No login:
final senhaDigitadaHash = hashSenha(senhaDigitada);
// Comparar com hash do banco
```

**Melhor ainda:** Use `bcrypt` ou `argon2`

---

### 10. **Sem Validação de Entrada**
**Problema:** Dados inválidos podem ser inseridos

**Exemplos:**
- Preço negativo
- Quantidade 0 ou negativa
- Nome vazio
- Email inválido

**Solução:** Adicionar constraints no banco
```sql
ALTER TABLE produtos
    ADD CONSTRAINT check_preco_positivo CHECK (preco >= 0),
    ADD CONSTRAINT check_nome_nao_vazio CHECK (LENGTH(TRIM(nome)) > 0);

ALTER TABLE vendas
    ADD CONSTRAINT check_total_positivo CHECK (total > 0);
```

---

### 11. **Sem Rate Limiting**
**Problema:** API pode ser sobrecarregada

**Solução:** Implementar throttling/rate limiting
```dart
// Exemplo simples:
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final int maxRequests = 100;
  final Duration timeWindow = Duration(minutes: 1);

  bool permitir(String userId) {
    final agora = DateTime.now();
    _requests[userId] ??= [];

    // Remover requests antigas
    _requests[userId]!.removeWhere(
      (time) => agora.difference(time) > timeWindow,
    );

    if (_requests[userId]!.length >= maxRequests) {
      return false; // Bloqueado
    }

    _requests[userId]!.add(agora);
    return true;
  }
}
```

---

### 12. **Código de Barras Sem Validação de Checksum**
**Problema:** Código de barras inválido pode ser aceito

**Solução implementada parcial:** Valida apenas tamanho
**Falta:** Validar checksum EAN-13

```dart
bool validarEAN13(String codigo) {
  if (codigo.length != 13) return false;

  int soma = 0;
  for (int i = 0; i < 12; i++) {
    final digito = int.parse(codigo[i]);
    soma += (i % 2 == 0) ? digito : digito * 3;
  }

  final checksum = (10 - (soma % 10)) % 10;
  return checksum == int.parse(codigo[12]);
}
```

---

## 🟢 BAIXAS (Melhorias Recomendadas)

### 13. **Sem Criptografia de Dados Sensíveis**
**Exemplos:** Informações de clientes, cartões (se armazenar)

**Solução:** Usar `flutter_secure_storage` ou criptografia AES

---

### 14. **Logs Inadequados**
**Problema:** Apenas `print()` statements

**Solução:** Sistema de logging estruturado
```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.i('Venda criada: $vendaId');
logger.w('Estoque baixo: $produtoId');
logger.e('Erro ao conectar: $erro');
```

---

### 15. **Sem Monitoramento de Performance**
**Problema:** Queries lentas não são detectadas

**Solução:**
```sql
-- Habilitar log de queries lentas
ALTER DATABASE pdv_system SET log_min_duration_statement = 1000; -- 1 segundo

-- Ver queries lentas
SELECT * FROM pg_stat_statements
ORDER BY total_time DESC LIMIT 10;
```

---

### 16. **Sem Testes Automatizados**
**Problema:** Mudanças podem quebrar funcionalidades

**Solução:** Adicionar testes unitários e de integração
```dart
// test/models/produto_model_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Produto deve calcular margem corretamente', () {
    final produto = ProdutoModel(
      nome: 'Teste',
      precoCompra: 100,
      preco: 150,
      // ...
    );

    expect(produto.margemLucroPercentual, 50);
  });
}
```

---

### 17. **Sem Disaster Recovery Plan**
**Problema:** Sem plano para recuperação de desastres

**Recomendações:**
- Documentar procedimentos de backup/restore
- Treinar equipe
- Testar restore periodicamente
- Ter servidor de backup (failover)

---

### 18. **Configurações Expostas no Git**
**Problema:** Arquivos de configuração com senhas no repositório

**Solução:** `.gitignore`
```
# .gitignore
lib/core/database/database_config.dart
.env
*.log
*.db
```

Criar template:
```dart
// database_config.example.dart
static const String host = 'localhost'; // ALTERAR
static const String password = 'SUA_SENHA_AQUI'; // ALTERAR
```

---

## 📊 Resumo de Prioridades

| Prioridade | Quantidade | Ação Imediata |
|------------|------------|---------------|
| 🔴 Crítica | 4 | Corrigir AGORA |
| 🟠 Alta | 4 | Corrigir esta semana |
| 🟡 Média | 4 | Corrigir este mês |
| 🟢 Baixa | 6 | Melhorias contínuas |

---

## ✅ Checklist de Segurança

### Imediato (Esta Semana)
- [ ] Remover senha hardcoded do código
- [ ] Adicionar arquivo .env
- [ ] Configurar backup automático diário
- [ ] Implementar audit trail básico
- [ ] Hash de senhas de usuários

### Curto Prazo (Este Mês)
- [ ] SSL na conexão PostgreSQL
- [ ] Limite de tentativas de login
- [ ] Validação de checksum em códigos de barras
- [ ] Constraints de validação no banco
- [ ] Sistema de logging estruturado

### Médio Prazo (3 Meses)
- [ ] Testes automatizados (cobertura 50%+)
- [ ] Monitoramento de performance
- [ ] Criptografia de dados sensíveis
- [ ] Disaster recovery plan documentado
- [ ] Revisão de segurança completa

---

## 🛡️ Boas Práticas Implementadas

✅ **Proteção contra alteração de data** (NOVO)
✅ **Código de barras** com validação básica (NOVO)
✅ **Uso de parâmetros em queries** (evita SQL injection)
✅ **Separação de impressões por tipo** (NOVO)
✅ **Sistema de permissões** (parcial)
✅ **Triggers para integridade** de dados
✅ **Views para relatórios** seguros

---

## 📞 Contato para Dúvidas

Para implementar estas correções ou discutir segurança:
- Revise cada item marcado como Crítico
- Teste em ambiente de desenvolvimento primeiro
- Faça backup antes de qualquer mudança
- Documente todas as alterações

---

**Última atualização:** 29/11/2025
**Versão do sistema:** POS Faturix v1.0
**Auditoria realizada por:** Claude Code Analysis
