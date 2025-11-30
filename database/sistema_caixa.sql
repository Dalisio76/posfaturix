-- ============================================
-- SISTEMA DE GESTÃO DE CAIXA
-- ============================================
-- Controle de abertura e fecho de caixa
-- SEM valor inicial - apenas registra abertura e fecho

-- ============================================
-- TABELA: Abertura de Caixa
-- ============================================
CREATE TABLE IF NOT EXISTS abertura_caixa (
  id SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL,
  terminal_nome VARCHAR(100),
  data_abertura TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  data_fecho TIMESTAMP,
  status VARCHAR(20) DEFAULT 'ABERTO', -- ABERTO, FECHADO
  observacoes_abertura TEXT,
  observacoes_fecho TEXT,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_abertura_caixa_usuario ON abertura_caixa(usuario_id);
CREATE INDEX IF NOT EXISTS idx_abertura_caixa_status ON abertura_caixa(status);
CREATE INDEX IF NOT EXISTS idx_abertura_caixa_data ON abertura_caixa(data_abertura DESC);

-- ============================================
-- TABELA: Resumo de Fecho de Caixa
-- ============================================
CREATE TABLE IF NOT EXISTS fecho_caixa (
  id SERIAL PRIMARY KEY,
  abertura_caixa_id INT NOT NULL,
  usuario_id INT NOT NULL,
  data_fecho TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Totais de vendas
  total_vendas INT DEFAULT 0,
  valor_total_vendas DECIMAL(10,2) DEFAULT 0,

  -- Formas de pagamento
  valor_dinheiro DECIMAL(10,2) DEFAULT 0,
  valor_cartao DECIMAL(10,2) DEFAULT 0,
  valor_transferencia DECIMAL(10,2) DEFAULT 0,
  valor_outros DECIMAL(10,2) DEFAULT 0,

  -- Conferência (dinheiro contado)
  valor_dinheiro_contado DECIMAL(10,2),
  diferenca_dinheiro DECIMAL(10,2),

  -- Observações
  observacoes TEXT,

  FOREIGN KEY (abertura_caixa_id) REFERENCES abertura_caixa(id) ON DELETE RESTRICT,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_fecho_caixa_abertura ON fecho_caixa(abertura_caixa_id);
CREATE INDEX IF NOT EXISTS idx_fecho_caixa_data ON fecho_caixa(data_fecho DESC);

-- ============================================
-- FUNÇÕES: Gestão de Caixa
-- ============================================

-- Função: Abrir caixa
CREATE OR REPLACE FUNCTION abrir_caixa(
  p_usuario_id INT,
  p_terminal_nome VARCHAR(100) DEFAULT NULL,
  p_observacoes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  v_caixa_aberto_id INT;
  v_abertura_id INT;
BEGIN
  -- Verifica se já existe caixa aberto para este usuário
  SELECT id INTO v_caixa_aberto_id
  FROM abertura_caixa
  WHERE usuario_id = p_usuario_id
    AND status = 'ABERTO'
  LIMIT 1;

  IF v_caixa_aberto_id IS NOT NULL THEN
    RAISE EXCEPTION 'Já existe um caixa aberto para este usuário (ID: %)', v_caixa_aberto_id
      USING HINT = 'Feche o caixa atual antes de abrir um novo';
  END IF;

  -- Cria novo registro de abertura
  INSERT INTO abertura_caixa (usuario_id, terminal_nome, observacoes_abertura, status)
  VALUES (p_usuario_id, p_terminal_nome, p_observacoes, 'ABERTO')
  RETURNING id INTO v_abertura_id;

  RETURN v_abertura_id;
END;
$$ LANGUAGE plpgsql;

-- Função: Verificar se usuário tem caixa aberto
CREATE OR REPLACE FUNCTION tem_caixa_aberto(p_usuario_id INT)
RETURNS BOOLEAN AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM abertura_caixa
  WHERE usuario_id = p_usuario_id
    AND status = 'ABERTO';

  RETURN v_count > 0;
END;
$$ LANGUAGE plpgsql;

-- Função: Obter caixa aberto do usuário
CREATE OR REPLACE FUNCTION obter_caixa_aberto(p_usuario_id INT)
RETURNS TABLE (
  id INT,
  data_abertura TIMESTAMP,
  terminal_nome VARCHAR(100),
  observacoes_abertura TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ac.id,
    ac.data_abertura,
    ac.terminal_nome,
    ac.observacoes_abertura
  FROM abertura_caixa ac
  WHERE ac.usuario_id = p_usuario_id
    AND ac.status = 'ABERTO'
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Função: Fechar caixa
CREATE OR REPLACE FUNCTION fechar_caixa(
  p_usuario_id INT,
  p_valor_dinheiro_contado DECIMAL(10,2),
  p_observacoes TEXT DEFAULT NULL
)
RETURNS INT AS $$
DECLARE
  v_abertura_id INT;
  v_fecho_id INT;
  v_total_vendas INT;
  v_valor_total DECIMAL(10,2);
  v_valor_dinheiro DECIMAL(10,2);
  v_valor_cartao DECIMAL(10,2);
  v_valor_transferencia DECIMAL(10,2);
  v_valor_outros DECIMAL(10,2);
  v_diferenca DECIMAL(10,2);
  v_data_abertura TIMESTAMP;
BEGIN
  -- Busca caixa aberto do usuário
  SELECT id, data_abertura INTO v_abertura_id, v_data_abertura
  FROM abertura_caixa
  WHERE usuario_id = p_usuario_id
    AND status = 'ABERTO'
  LIMIT 1;

  IF v_abertura_id IS NULL THEN
    RAISE EXCEPTION 'Não há caixa aberto para este usuário'
      USING HINT = 'Abra o caixa antes de tentar fechar';
  END IF;

  -- Calcula totais de vendas desde a abertura
  SELECT
    COUNT(*),
    COALESCE(SUM(valor_total), 0),
    COALESCE(SUM(CASE WHEN forma_pagamento = 'DINHEIRO' THEN valor_total ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN forma_pagamento = 'CARTÃO' OR forma_pagamento = 'CARTAO' THEN valor_total ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN forma_pagamento = 'TRANSFERÊNCIA' OR forma_pagamento = 'TRANSFERENCIA' THEN valor_total ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN forma_pagamento NOT IN ('DINHEIRO', 'CARTÃO', 'CARTAO', 'TRANSFERÊNCIA', 'TRANSFERENCIA') THEN valor_total ELSE 0 END), 0)
  INTO
    v_total_vendas,
    v_valor_total,
    v_valor_dinheiro,
    v_valor_cartao,
    v_valor_transferencia,
    v_valor_outros
  FROM vendas
  WHERE data_venda >= v_data_abertura
    AND status != 'CANCELADA';

  -- Calcula diferença (dinheiro contado vs dinheiro das vendas)
  v_diferenca := p_valor_dinheiro_contado - v_valor_dinheiro;

  -- Registra fecho
  INSERT INTO fecho_caixa (
    abertura_caixa_id,
    usuario_id,
    total_vendas,
    valor_total_vendas,
    valor_dinheiro,
    valor_cartao,
    valor_transferencia,
    valor_outros,
    valor_dinheiro_contado,
    diferenca_dinheiro,
    observacoes
  ) VALUES (
    v_abertura_id,
    p_usuario_id,
    v_total_vendas,
    v_valor_total,
    v_valor_dinheiro,
    v_valor_cartao,
    v_valor_transferencia,
    v_valor_outros,
    p_valor_dinheiro_contado,
    v_diferenca,
    p_observacoes
  ) RETURNING id INTO v_fecho_id;

  -- Atualiza status da abertura
  UPDATE abertura_caixa
  SET status = 'FECHADO',
      data_fecho = CURRENT_TIMESTAMP,
      observacoes_fecho = p_observacoes
  WHERE id = v_abertura_id;

  -- Registra no controle de tempo (se existir)
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'controle_fecho_caixa') THEN
    INSERT INTO controle_fecho_caixa (data_fecho, usuario_id, valor_total)
    VALUES (CURRENT_DATE, p_usuario_id, v_valor_total)
    ON CONFLICT (data_fecho) DO UPDATE
    SET usuario_id = EXCLUDED.usuario_id,
        valor_total = EXCLUDED.valor_total;
  END IF;

  RETURN v_fecho_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- VIEWS: Consultas úteis
-- ============================================

-- View: Caixas abertos atualmente
CREATE OR REPLACE VIEW vw_caixas_abertos AS
SELECT
  ac.id,
  ac.usuario_id,
  u.nome as usuario_nome,
  ac.terminal_nome,
  ac.data_abertura,
  EXTRACT(EPOCH FROM (NOW() - ac.data_abertura)) / 3600 as horas_aberto,
  COUNT(v.id) as total_vendas,
  COALESCE(SUM(v.valor_total), 0) as valor_total_vendas
FROM abertura_caixa ac
INNER JOIN usuarios u ON u.id = ac.usuario_id
LEFT JOIN vendas v ON v.data_venda >= ac.data_abertura
  AND v.status != 'CANCELADA'
WHERE ac.status = 'ABERTO'
GROUP BY ac.id, ac.usuario_id, u.nome, ac.terminal_nome, ac.data_abertura;

-- View: Histórico de fechos
CREATE OR REPLACE VIEW vw_historico_fechos AS
SELECT
  fc.id,
  fc.data_fecho,
  u.nome as usuario_nome,
  ac.terminal_nome,
  ac.data_abertura,
  fc.total_vendas,
  fc.valor_total_vendas,
  fc.valor_dinheiro,
  fc.valor_cartao,
  fc.valor_transferencia,
  fc.valor_dinheiro_contado,
  fc.diferenca_dinheiro,
  CASE
    WHEN fc.diferenca_dinheiro > 0 THEN 'SOBRA'
    WHEN fc.diferenca_dinheiro < 0 THEN 'FALTA'
    ELSE 'OK'
  END as status_diferenca,
  fc.observacoes
FROM fecho_caixa fc
INNER JOIN abertura_caixa ac ON ac.id = fc.abertura_caixa_id
INNER JOIN usuarios u ON u.id = fc.usuario_id
ORDER BY fc.data_fecho DESC;

-- View: Resumo de quebras de caixa
CREATE OR REPLACE VIEW vw_quebras_caixa AS
SELECT
  u.nome as usuario_nome,
  DATE(fc.data_fecho) as data,
  COUNT(*) as total_fechos,
  COUNT(CASE WHEN fc.diferenca_dinheiro != 0 THEN 1 END) as fechos_com_diferenca,
  SUM(CASE WHEN fc.diferenca_dinheiro > 0 THEN fc.diferenca_dinheiro ELSE 0 END) as total_sobras,
  SUM(CASE WHEN fc.diferenca_dinheiro < 0 THEN ABS(fc.diferenca_dinheiro) ELSE 0 END) as total_faltas,
  SUM(fc.diferenca_dinheiro) as diferenca_liquida
FROM fecho_caixa fc
INNER JOIN usuarios u ON u.id = fc.usuario_id
GROUP BY u.nome, DATE(fc.data_fecho)
HAVING SUM(ABS(fc.diferenca_dinheiro)) > 0
ORDER BY DATE(fc.data_fecho) DESC;

-- ============================================
-- TRIGGER: Validar venda com caixa aberto
-- ============================================
CREATE OR REPLACE FUNCTION validar_caixa_aberto_venda()
RETURNS TRIGGER AS $$
DECLARE
  v_tem_caixa BOOLEAN;
BEGIN
  -- Verifica se o usuário tem caixa aberto (se usuario_id estiver definido)
  IF NEW.usuario_id IS NOT NULL THEN
    v_tem_caixa := tem_caixa_aberto(NEW.usuario_id);

    IF NOT v_tem_caixa THEN
      RAISE EXCEPTION 'O caixa deve estar aberto para realizar vendas'
        USING HINT = 'Abra o caixa antes de iniciar as vendas';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Comentar o trigger por enquanto (será ativado quando o sistema estiver pronto)
-- DROP TRIGGER IF EXISTS trigger_validar_caixa_venda ON vendas;
-- CREATE TRIGGER trigger_validar_caixa_venda
-- BEFORE INSERT ON vendas
-- FOR EACH ROW
-- EXECUTE FUNCTION validar_caixa_aberto_venda();

-- ============================================
-- COMENTÁRIOS
-- ============================================
COMMENT ON TABLE abertura_caixa IS 'Registro de abertura e fecho de caixa por usuário';
COMMENT ON TABLE fecho_caixa IS 'Resumo detalhado do fecho de caixa com conferência';
COMMENT ON COLUMN fecho_caixa.diferenca_dinheiro IS 'Diferença entre dinheiro contado e vendas em dinheiro (positivo = sobra, negativo = falta)';

-- ============================================
-- MENSAGEM DE CONCLUSÃO
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Sistema de Gestão de Caixa instalado com sucesso!';
  RAISE NOTICE '   - Abertura de caixa SEM valor inicial';
  RAISE NOTICE '   - Fecho com conferência de dinheiro';
  RAISE NOTICE '   - Detecção de quebra de caixa';
  RAISE NOTICE '   - Validação de caixa aberto antes de vender (trigger comentado)';
  RAISE NOTICE '';
  RAISE NOTICE 'Funções disponíveis:';
  RAISE NOTICE '   ✓ abrir_caixa(usuario_id, terminal_nome, observacoes)';
  RAISE NOTICE '   ✓ tem_caixa_aberto(usuario_id)';
  RAISE NOTICE '   ✓ obter_caixa_aberto(usuario_id)';
  RAISE NOTICE '   ✓ fechar_caixa(usuario_id, valor_dinheiro_contado, observacoes)';
END $$;
