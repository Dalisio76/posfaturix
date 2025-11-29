# Plano de Implementação - Funcionalidades Críticas

## 1. Gestão de Caixa - Abertura/Fecho Estruturado

### Problema Atual
Atualmente o sistema não tem controle estruturado de caixa:
- Não há registro de abertura de caixa (valor inicial)
- Não há processo formal de fecho de caixa
- Não há conferência de valores
- Não há registro de quem abriu/fechou
- Não há detecção de quebra de caixa

### O Que Será Implementado

#### 1.1 Abertura de Caixa
**Interface:**
- Tela de abertura quando usuário faz login
- Campos:
  - Valor inicial em dinheiro (obrigatório)
  - Observações (opcional)
  - Data/hora automática
  - Usuário automático

**Validações:**
- Não permitir vendas sem abertura de caixa
- Apenas um caixa aberto por usuário/terminal
- Registrar no banco de dados

#### 1.2 Fecho de Caixa
**Interface:**
- Tela de fecho ao final do expediente
- Campos:
  - Valor em dinheiro contado
  - Valor em cartão (automático do sistema)
  - Valor em transferência (automático)
  - Valor esperado (calculado)
  - Diferença (sobra/falta)
  - Observações sobre diferença

**Relatório Automático:**
- Total de vendas
- Formas de pagamento
- Vendas por categoria
- Quebra de caixa (se houver)
- Assinatura de conferência

**Integração:**
- Integra com `sistema_controle_tempo.sql` (proteção de data)
- Bloqueia vendas após fecho
- Gera impressão automática do relatório

#### 1.3 Banco de Dados
```sql
-- Tabela abertura_caixa
CREATE TABLE abertura_caixa (
  id SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL,
  terminal_id INT,
  valor_inicial DECIMAL(10,2) NOT NULL,
  data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  observacoes TEXT,
  status VARCHAR(20) DEFAULT 'ABERTO', -- ABERTO, FECHADO
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabela fecho_caixa (expande controle_fecho_caixa existente)
ALTER TABLE controle_fecho_caixa ADD COLUMN abertura_caixa_id INT;
ALTER TABLE controle_fecho_caixa ADD COLUMN valor_cartao DECIMAL(10,2);
ALTER TABLE controle_fecho_caixa ADD COLUMN valor_transferencia DECIMAL(10,2);
ALTER TABLE controle_fecho_caixa ADD COLUMN valor_dinheiro_contado DECIMAL(10,2);
ALTER TABLE controle_fecho_caixa ADD COLUMN diferenca DECIMAL(10,2);
ALTER TABLE controle_fecho_caixa ADD COLUMN observacoes TEXT;
```

---

## 2. Configurações Avançadas

### O Que É
Área de configurações do sistema que não são alteradas frequentemente mas são importantes para operação.

### O Que Será Implementado

#### 2.1 Configurações de Restaurante
- **Taxa de serviço (%)**: 10%, 12%, 15% ou customizado
- **Aplicar taxa automaticamente**: Sim/Não
- **Permitir remover taxa**: Sim/Não

#### 2.2 Configurações de Operação
- **Permitir venda com estoque negativo**: Sim/Não
- **Exigir cliente em todas as vendas**: Sim/Não
- **Número mínimo de caracteres para busca**: 2, 3, 4
- **Timeout de sessão (minutos)**: 15, 30, 60, nunca

#### 2.3 Configurações de Impressão
- **Mensagem rodapé recibo**: Texto customizado
- **Imprimir logo**: Sim/Não (caminho para arquivo)
- **Número de vias**: 1, 2, 3
- **Imprimir automaticamente**: Sim/Não

#### 2.4 Configurações Financeiras
- **Moeda**: MT (Metical), USD, EUR
- **Símbolo moeda**: MT, $, €
- **Casas decimais**: 0, 2, 3
- **Arredondamento**: Matemático, Sempre para cima, Sempre para baixo

#### 2.5 Configurações de Backup
- **Backup automático**: Sim/Não
- **Horário do backup**: HH:MM
- **Diretório de backup**: Caminho
- **Manter backups por (dias)**: 7, 15, 30, 60

#### 2.6 Banco de Dados
```sql
CREATE TABLE configuracoes_sistema (
  id SERIAL PRIMARY KEY,
  chave VARCHAR(100) UNIQUE NOT NULL,
  valor TEXT,
  tipo VARCHAR(20), -- STRING, INTEGER, DECIMAL, BOOLEAN
  categoria VARCHAR(50), -- RESTAURANTE, OPERACAO, IMPRESSAO, FINANCEIRO, BACKUP
  descricao TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Exemplos de configurações
INSERT INTO configuracoes_sistema (chave, valor, tipo, categoria, descricao) VALUES
('taxa_servico_percentual', '10', 'DECIMAL', 'RESTAURANTE', 'Percentual de taxa de serviço'),
('aplicar_taxa_automaticamente', 'true', 'BOOLEAN', 'RESTAURANTE', 'Aplicar taxa automaticamente'),
('permitir_venda_estoque_negativo', 'false', 'BOOLEAN', 'OPERACAO', 'Permitir venda com estoque negativo'),
('timeout_sessao_minutos', '30', 'INTEGER', 'OPERACAO', 'Timeout de sessão em minutos'),
('moeda', 'MT', 'STRING', 'FINANCEIRO', 'Moeda padrão'),
('casas_decimais', '2', 'INTEGER', 'FINANCEIRO', 'Número de casas decimais'),
('backup_automatico', 'true', 'BOOLEAN', 'BACKUP', 'Ativar backup automático'),
('horario_backup', '02:00', 'STRING', 'BACKUP', 'Horário do backup diário');
```

---

## 3. Auditoria e Logs

### Objetivo
Registrar todas as operações importantes do sistema para:
- Rastreabilidade de ações
- Detecção de fraudes
- Resolução de problemas
- Conformidade legal

### O Que Será Registrado

#### 3.1 Operações de Vendas
- Criação de venda
- Cancelamento de venda
- Alteração de venda
- Aplicação de desconto
- Remoção de item

#### 3.2 Operações de Estoque
- Entrada de produtos
- Saída de produtos
- Ajuste de estoque
- Transferência entre locais

#### 3.3 Operações de Caixa
- Abertura de caixa
- Fecho de caixa
- Sangria (retirada de dinheiro)
- Reforço (adição de dinheiro)

#### 3.4 Operações Administrativas
- Criação/edição de usuário
- Alteração de permissões
- Alteração de preços
- Alteração de configurações

#### 3.5 Operações de Acesso
- Login
- Logout
- Tentativas de login falhadas
- Alteração de senha

### Banco de Dados
```sql
CREATE TABLE auditoria (
  id SERIAL PRIMARY KEY,
  tabela VARCHAR(100), -- vendas, produtos, usuarios, etc
  operacao VARCHAR(20), -- INSERT, UPDATE, DELETE
  registro_id INT, -- ID do registro afetado
  usuario_id INT,
  terminal_id INT,
  dados_anteriores JSONB, -- Estado anterior (para UPDATE/DELETE)
  dados_novos JSONB, -- Estado novo (para INSERT/UPDATE)
  ip_address VARCHAR(50),
  data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Índices para performance
CREATE INDEX idx_auditoria_tabela ON auditoria(tabela);
CREATE INDEX idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX idx_auditoria_data ON auditoria(data_operacao);

-- Trigger genérico para auditoria
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, dados_anteriores)
    VALUES (TG_TABLE_NAME, 'DELETE', OLD.id, row_to_json(OLD));
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, dados_anteriores, dados_novos)
    VALUES (TG_TABLE_NAME, 'UPDATE', NEW.id, row_to_json(OLD), row_to_json(NEW));
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, dados_novos)
    VALUES (TG_TABLE_NAME, 'INSERT', NEW.id, row_to_json(NEW));
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;
```

### Interface de Consulta
- Filtros: Data, Usuário, Tabela, Operação
- Visualização de antes/depois
- Exportar para Excel/PDF
- Busca por ID de registro

---

## 4. Monitoramento de Terminais

### Objetivo
Visualizar e gerenciar todos os terminais conectados ao sistema em tempo real.

### O Que Será Implementado

#### 4.1 Dashboard de Terminais
**Informações exibidas:**
- Nome do terminal
- IP do terminal
- Status: Online/Offline
- Usuário logado atualmente
- Última atividade
- Vendas do dia
- Caixa aberto/fechado
- Versão do aplicativo

#### 4.2 Ações Disponíveis
- Ver detalhes do terminal
- Forçar logout remoto
- Bloquear terminal
- Ver histórico de vendas do terminal
- Ver logs de conexão

#### 4.3 Alertas
- Terminal offline há mais de X minutos
- Versão do app desatualizada
- Tentativas de login falhadas
- Caixa aberto há muito tempo

#### 4.4 Banco de Dados (já existe em sistema_terminais.sql)
Vamos expandir com:
```sql
-- Adicionar à tabela terminais
ALTER TABLE terminais ADD COLUMN status VARCHAR(20) DEFAULT 'OFFLINE';
ALTER TABLE terminais ADD COLUMN usuario_logado_id INT;
ALTER TABLE terminais ADD COLUMN ultima_atividade TIMESTAMP;
ALTER TABLE terminais ADD COLUMN versao_app VARCHAR(20);
ALTER TABLE terminais ADD COLUMN bloqueado BOOLEAN DEFAULT false;
ALTER TABLE terminais ADD COLUMN motivo_bloqueio TEXT;

-- Heartbeat (batimento cardíaco) para detectar terminais online
CREATE TABLE terminal_heartbeat (
  id SERIAL PRIMARY KEY,
  terminal_id INT NOT NULL,
  timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (terminal_id) REFERENCES terminais(id)
);

-- View de status atual
CREATE OR REPLACE VIEW vw_status_terminais AS
SELECT
  t.id,
  t.nome,
  t.ip_address,
  t.status,
  t.usuario_logado_id,
  u.nome as usuario_nome,
  t.ultima_atividade,
  CASE
    WHEN t.ultima_atividade > NOW() - INTERVAL '5 minutes' THEN 'ONLINE'
    ELSE 'OFFLINE'
  END as status_real,
  t.versao_app,
  t.bloqueado,
  (SELECT COUNT(*) FROM vendas v WHERE DATE(v.data_venda) = CURRENT_DATE AND v.terminal_id = t.id) as vendas_hoje,
  ac.id as caixa_aberto_id
FROM terminais t
LEFT JOIN usuarios u ON u.id = t.usuario_logado_id
LEFT JOIN abertura_caixa ac ON ac.terminal_id = t.id AND ac.status = 'ABERTO';
```

---

## 5. Gestão de Promoções/Descontos

### O Que Será Implementado

#### 5.1 Tipos de Promoções
1. **Desconto Percentual**: 10%, 20%, 50% off
2. **Desconto Fixo**: -100 MT, -50 MT
3. **Leve X Pague Y**: Leve 3 pague 2
4. **Combo**: Pizza + Refrigerante = preço especial
5. **Happy Hour**: Descontos em horários específicos

#### 5.2 Condições de Aplicação
- **Período**: Data início e fim
- **Dias da semana**: Segunda a sexta, fins de semana
- **Horário**: 18h às 20h (happy hour)
- **Produtos**: Produtos específicos ou categorias
- **Quantidade mínima**: Mínimo 2 unidades
- **Valor mínimo da compra**: Acima de 500 MT

#### 5.3 Banco de Dados
```sql
CREATE TABLE promocoes (
  id SERIAL PRIMARY KEY,
  nome VARCHAR(200) NOT NULL,
  descricao TEXT,
  tipo VARCHAR(50), -- PERCENTUAL, FIXO, LEVE_X_PAGUE_Y, COMBO, HAPPY_HOUR
  valor_desconto DECIMAL(10,2), -- Valor ou percentual
  data_inicio DATE,
  data_fim DATE,
  hora_inicio TIME,
  hora_fim TIME,
  dias_semana VARCHAR(50), -- 0,1,2,3,4,5,6 (Dom-Sab)
  valor_minimo_compra DECIMAL(10,2),
  quantidade_minima INT,
  ativo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Produtos incluídos na promoção
CREATE TABLE promocao_produtos (
  id SERIAL PRIMARY KEY,
  promocao_id INT NOT NULL,
  produto_id INT NOT NULL,
  FOREIGN KEY (promocao_id) REFERENCES promocoes(id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id) ON DELETE CASCADE
);

-- Combos (ex: Pizza + Refrigerante)
CREATE TABLE promocao_combos (
  id SERIAL PRIMARY KEY,
  promocao_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade INT DEFAULT 1,
  FOREIGN KEY (promocao_id) REFERENCES promocoes(id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id)
);

-- Histórico de aplicação
CREATE TABLE promocoes_aplicadas (
  id SERIAL PRIMARY KEY,
  venda_id INT NOT NULL,
  promocao_id INT NOT NULL,
  valor_desconto DECIMAL(10,2),
  data_aplicacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (promocao_id) REFERENCES promocoes(id)
);

-- Função para verificar se promoção é válida agora
CREATE OR REPLACE FUNCTION promocao_valida(p_promocao_id INT)
RETURNS BOOLEAN AS $$
DECLARE
  promo RECORD;
  dia_atual INT;
BEGIN
  SELECT * INTO promo FROM promocoes WHERE id = p_promocao_id AND ativo = true;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Verificar data
  IF promo.data_inicio IS NOT NULL AND CURRENT_DATE < promo.data_inicio THEN
    RETURN false;
  END IF;

  IF promo.data_fim IS NOT NULL AND CURRENT_DATE > promo.data_fim THEN
    RETURN false;
  END IF;

  -- Verificar hora
  IF promo.hora_inicio IS NOT NULL AND CURRENT_TIME < promo.hora_inicio THEN
    RETURN false;
  END IF;

  IF promo.hora_fim IS NOT NULL AND CURRENT_TIME > promo.hora_fim THEN
    RETURN false;
  END IF;

  -- Verificar dia da semana
  IF promo.dias_semana IS NOT NULL THEN
    dia_atual = EXTRACT(DOW FROM CURRENT_DATE); -- 0=Dom, 6=Sab
    IF promo.dias_semana NOT LIKE '%' || dia_atual || '%' THEN
      RETURN false;
    END IF;
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql;
```

#### 5.4 Interface
- Lista de promoções ativas/inativas
- Criar/editar promoção
- Testar promoção (simulação)
- Relatório de promoções mais usadas
- Relatório de economia gerada para clientes

---

## 6. Notificações e Alertas

### Objetivo
Sistema de notificações para informar usuários sobre eventos importantes.

### Tipos de Notificações

#### 6.1 Alertas de Estoque
- Produto com estoque baixo (< 10 unidades)
- Produto sem estoque
- Produto próximo do vencimento

#### 6.2 Alertas de Operação
- Caixa aberto há mais de 12 horas
- Tentativas de login falhadas
- Terminal offline
- Falta de sincronização entre terminais

#### 6.3 Alertas Financeiros
- Quebra de caixa detectada
- Vendas do dia abaixo da meta
- Valor em caixa acima do limite (risco)

#### 6.4 Alertas de Sistema
- Backup falhou
- Espaço em disco baixo
- Atualização disponível
- Licença próxima do vencimento

### Banco de Dados
```sql
CREATE TABLE notificacoes (
  id SERIAL PRIMARY KEY,
  tipo VARCHAR(50), -- ESTOQUE, OPERACAO, FINANCEIRO, SISTEMA
  nivel VARCHAR(20), -- INFO, AVISO, CRITICO
  titulo VARCHAR(200),
  mensagem TEXT,
  lida BOOLEAN DEFAULT false,
  usuario_id INT, -- NULL = todos os admins
  data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  data_leitura TIMESTAMP,
  acao_url VARCHAR(500), -- Link para ação relacionada
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Configuração de alertas
CREATE TABLE configuracao_alertas (
  id SERIAL PRIMARY KEY,
  tipo_alerta VARCHAR(50),
  habilitado BOOLEAN DEFAULT true,
  valor_limite DECIMAL(10,2), -- Ex: estoque mínimo = 10
  usuarios_notificar TEXT, -- IDs separados por vírgula ou "TODOS"
  enviar_email BOOLEAN DEFAULT false,
  email_destino VARCHAR(200)
);

-- Inserir configurações padrão
INSERT INTO configuracao_alertas (tipo_alerta, habilitado, valor_limite, usuarios_notificar) VALUES
('ESTOQUE_BAIXO', true, 10, 'TODOS'),
('ESTOQUE_ZERADO', true, 0, 'TODOS'),
('CAIXA_ABERTO_12H', true, 12, 'TODOS'),
('QUEBRA_CAIXA', true, 50, 'TODOS'),
('TERMINAL_OFFLINE', true, 15, 'TODOS'),
('BACKUP_FALHOU', true, NULL, 'TODOS');

-- Trigger para criar notificação quando estoque baixo
CREATE OR REPLACE FUNCTION notificar_estoque_baixo()
RETURNS TRIGGER AS $$
DECLARE
  limite_estoque INT;
BEGIN
  SELECT valor_limite INTO limite_estoque
  FROM configuracao_alertas
  WHERE tipo_alerta = 'ESTOQUE_BAIXO' AND habilitado = true;

  IF NEW.estoque <= limite_estoque THEN
    INSERT INTO notificacoes (tipo, nivel, titulo, mensagem)
    VALUES (
      'ESTOQUE',
      CASE WHEN NEW.estoque = 0 THEN 'CRITICO' ELSE 'AVISO' END,
      'Estoque Baixo',
      'Produto "' || NEW.nome || '" está com estoque de ' || NEW.estoque || ' unidades'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notificar_estoque
AFTER UPDATE ON produtos
FOR EACH ROW
WHEN (OLD.estoque IS DISTINCT FROM NEW.estoque)
EXECUTE FUNCTION notificar_estoque_baixo();
```

### Interface
- Badge com número de notificações não lidas
- Painel de notificações (dropdown)
- Filtros: Tipo, Nível, Lidas/Não lidas
- Marcar como lida
- Marcar todas como lidas
- Configuração de alertas (quais receber)

---

## Ordem de Implementação Sugerida

1. **Auditoria e Logs** (Base para segurança)
2. **Configurações Avançadas** (Necessário para outras features)
3. **Gestão de Caixa** (Crítico para operação)
4. **Monitoramento de Terminais** (Importante para multi-terminal)
5. **Notificações e Alertas** (Depende de auditoria)
6. **Gestão de Promoções** (Funcionalidade comercial)

---

## Estimativa de Tempo

- Auditoria e Logs: 4-6 horas
- Configurações Avançadas: 3-4 horas
- Gestão de Caixa: 6-8 horas
- Monitoramento de Terminais: 4-5 horas
- Notificações e Alertas: 5-6 horas
- Gestão de Promoções: 8-10 horas

**Total**: 30-39 horas de desenvolvimento
