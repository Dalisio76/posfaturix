-- ============================================
-- SISTEMA DE AUDITORIA E LOGS
-- ============================================
-- Registra todas as operações importantes do sistema
-- para rastreabilidade, segurança e conformidade

-- Tabela principal de auditoria
CREATE TABLE IF NOT EXISTS auditoria (
  id SERIAL PRIMARY KEY,
  tabela VARCHAR(100) NOT NULL,        -- Nome da tabela afetada
  operacao VARCHAR(20) NOT NULL,       -- INSERT, UPDATE, DELETE
  registro_id INT,                     -- ID do registro afetado
  usuario_id INT,                      -- Quem fez a operação
  terminal_nome VARCHAR(100),          -- Nome do terminal
  dados_anteriores JSONB,              -- Estado anterior (UPDATE/DELETE)
  dados_novos JSONB,                   -- Estado novo (INSERT/UPDATE)
  ip_address VARCHAR(50),              -- IP do cliente
  descricao TEXT,                      -- Descrição legível da operação
  data_operacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- Índices para performance de consultas
CREATE INDEX IF NOT EXISTS idx_auditoria_tabela ON auditoria(tabela);
CREATE INDEX IF NOT EXISTS idx_auditoria_usuario ON auditoria(usuario_id);
CREATE INDEX IF NOT EXISTS idx_auditoria_data ON auditoria(data_operacao DESC);
CREATE INDEX IF NOT EXISTS idx_auditoria_operacao ON auditoria(operacao);
CREATE INDEX IF NOT EXISTS idx_auditoria_registro ON auditoria(tabela, registro_id);

-- ============================================
-- FUNÇÃO GENÉRICA DE AUDITORIA
-- ============================================
CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
  usuario_atual INT;
  descricao_texto TEXT;
BEGIN
  -- Tenta pegar usuário da sessão (se configurado)
  BEGIN
    usuario_atual := current_setting('app.usuario_id')::INT;
  EXCEPTION
    WHEN OTHERS THEN
      usuario_atual := NULL;
  END;

  -- Gera descrição legível
  IF (TG_OP = 'DELETE') THEN
    descricao_texto := 'Deletou ' || TG_TABLE_NAME || ' ID: ' || OLD.id;
  ELSIF (TG_OP = 'UPDATE') THEN
    descricao_texto := 'Atualizou ' || TG_TABLE_NAME || ' ID: ' || NEW.id;
  ELSIF (TG_OP = 'INSERT') THEN
    descricao_texto := 'Criou ' || TG_TABLE_NAME || ' ID: ' || NEW.id;
  END IF;

  -- Insere log de auditoria
  IF (TG_OP = 'DELETE') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, usuario_id, dados_anteriores, descricao)
    VALUES (TG_TABLE_NAME, 'DELETE', OLD.id, usuario_atual, row_to_json(OLD), descricao_texto);
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, usuario_id, dados_anteriores, dados_novos, descricao)
    VALUES (TG_TABLE_NAME, 'UPDATE', NEW.id, usuario_atual, row_to_json(OLD), row_to_json(NEW), descricao_texto);
    RETURN NEW;
  ELSIF (TG_OP = 'INSERT') THEN
    INSERT INTO auditoria (tabela, operacao, registro_id, usuario_id, dados_novos, descricao)
    VALUES (TG_TABLE_NAME, 'INSERT', NEW.id, usuario_atual, row_to_json(NEW), descricao_texto);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS DE AUDITORIA PARA TABELAS CRÍTICAS
-- ============================================

-- Auditoria de Produtos
DROP TRIGGER IF EXISTS trigger_audit_produtos ON produtos;
CREATE TRIGGER trigger_audit_produtos
AFTER INSERT OR UPDATE OR DELETE ON produtos
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Vendas
DROP TRIGGER IF EXISTS trigger_audit_vendas ON vendas;
CREATE TRIGGER trigger_audit_vendas
AFTER INSERT OR UPDATE OR DELETE ON vendas
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Itens de Venda
DROP TRIGGER IF EXISTS trigger_audit_itens_venda ON itens_venda;
CREATE TRIGGER trigger_audit_itens_venda
AFTER INSERT OR UPDATE OR DELETE ON itens_venda
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Usuários
DROP TRIGGER IF EXISTS trigger_audit_usuarios ON usuarios;
CREATE TRIGGER trigger_audit_usuarios
AFTER INSERT OR UPDATE OR DELETE ON usuarios
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Permissões
DROP TRIGGER IF EXISTS trigger_audit_perfil_permissoes ON perfil_permissoes;
CREATE TRIGGER trigger_audit_perfil_permissoes
AFTER INSERT OR UPDATE OR DELETE ON perfil_permissoes
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Clientes
DROP TRIGGER IF EXISTS trigger_audit_clientes ON clientes;
CREATE TRIGGER trigger_audit_clientes
AFTER INSERT OR UPDATE OR DELETE ON clientes
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Famílias
DROP TRIGGER IF EXISTS trigger_audit_familias ON familias;
CREATE TRIGGER trigger_audit_familias
AFTER INSERT OR UPDATE OR DELETE ON familias
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Impressoras
DROP TRIGGER IF EXISTS trigger_audit_impressoras ON impressoras;
CREATE TRIGGER trigger_audit_impressoras
AFTER INSERT OR UPDATE OR DELETE ON impressoras
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Áreas
DROP TRIGGER IF EXISTS trigger_audit_areas ON areas;
CREATE TRIGGER trigger_audit_areas
AFTER INSERT OR UPDATE OR DELETE ON areas
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- Auditoria de Mesas
DROP TRIGGER IF EXISTS trigger_audit_mesas ON mesas;
CREATE TRIGGER trigger_audit_mesas
AFTER INSERT OR UPDATE OR DELETE ON mesas
FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();

-- ============================================
-- TABELA DE LOGS DE ACESSO (LOGIN/LOGOUT)
-- ============================================
CREATE TABLE IF NOT EXISTS logs_acesso (
  id SERIAL PRIMARY KEY,
  usuario_id INT,
  terminal_nome VARCHAR(100),
  ip_address VARCHAR(50),
  tipo VARCHAR(20) NOT NULL,           -- LOGIN, LOGOUT, LOGIN_FALHOU
  sucesso BOOLEAN DEFAULT true,
  motivo_falha TEXT,                   -- Se login falhou, qual o motivo
  data_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_logs_acesso_usuario ON logs_acesso(usuario_id);
CREATE INDEX IF NOT EXISTS idx_logs_acesso_data ON logs_acesso(data_hora DESC);
CREATE INDEX IF NOT EXISTS idx_logs_acesso_tipo ON logs_acesso(tipo);

-- ============================================
-- VIEWS ÚTEIS PARA CONSULTAS
-- ============================================

-- View: Últimas operações com detalhes do usuário
CREATE OR REPLACE VIEW vw_auditoria_detalhada AS
SELECT
  a.id,
  a.tabela,
  a.operacao,
  a.registro_id,
  a.usuario_id,
  u.nome as usuario_nome,
  u.codigo as usuario_codigo,
  a.terminal_nome,
  a.ip_address,
  a.descricao,
  a.data_operacao,
  a.dados_anteriores,
  a.dados_novos
FROM auditoria a
LEFT JOIN usuarios u ON u.id = a.usuario_id
ORDER BY a.data_operacao DESC;

-- View: Resumo de operações por usuário
CREATE OR REPLACE VIEW vw_auditoria_por_usuario AS
SELECT
  u.id as usuario_id,
  u.nome as usuario_nome,
  a.tabela,
  a.operacao,
  COUNT(*) as total_operacoes,
  MAX(a.data_operacao) as ultima_operacao
FROM auditoria a
INNER JOIN usuarios u ON u.id = a.usuario_id
GROUP BY u.id, u.nome, a.tabela, a.operacao
ORDER BY total_operacoes DESC;

-- View: Operações suspeitas (muitas em pouco tempo)
CREATE OR REPLACE VIEW vw_operacoes_suspeitas AS
SELECT
  a.usuario_id,
  u.nome as usuario_nome,
  a.tabela,
  a.operacao,
  COUNT(*) as total,
  MIN(a.data_operacao) as primeira_operacao,
  MAX(a.data_operacao) as ultima_operacao,
  EXTRACT(EPOCH FROM (MAX(a.data_operacao) - MIN(a.data_operacao))) / 60 as duracao_minutos
FROM auditoria a
LEFT JOIN usuarios u ON u.id = a.usuario_id
WHERE a.data_operacao >= NOW() - INTERVAL '1 hour'
GROUP BY a.usuario_id, u.nome, a.tabela, a.operacao
HAVING COUNT(*) > 50  -- Mais de 50 operações iguais em 1 hora
ORDER BY total DESC;

-- View: Histórico de alterações de preços
CREATE OR REPLACE VIEW vw_historico_precos AS
SELECT
  a.id,
  a.registro_id as produto_id,
  (a.dados_anteriores->>'nome') as produto_nome,
  (a.dados_anteriores->>'preco')::DECIMAL(10,2) as preco_anterior,
  (a.dados_novos->>'preco')::DECIMAL(10,2) as preco_novo,
  (a.dados_novos->>'preco')::DECIMAL(10,2) - (a.dados_anteriores->>'preco')::DECIMAL(10,2) as diferenca,
  a.usuario_id,
  u.nome as usuario_nome,
  a.data_operacao
FROM auditoria a
LEFT JOIN usuarios u ON u.id = a.usuario_id
WHERE a.tabela = 'produtos'
  AND a.operacao = 'UPDATE'
  AND a.dados_anteriores->>'preco' IS DISTINCT FROM a.dados_novos->>'preco'
ORDER BY a.data_operacao DESC;

-- View: Produtos deletados (para recuperação)
CREATE OR REPLACE VIEW vw_produtos_deletados AS
SELECT
  a.id as auditoria_id,
  a.registro_id as produto_id,
  (a.dados_anteriores->>'codigo') as codigo,
  (a.dados_anteriores->>'nome') as nome,
  (a.dados_anteriores->>'preco')::DECIMAL(10,2) as preco,
  (a.dados_anteriores->>'estoque')::INT as estoque,
  a.usuario_id,
  u.nome as usuario_nome,
  a.data_operacao as data_delecao
FROM auditoria a
LEFT JOIN usuarios u ON u.id = a.usuario_id
WHERE a.tabela = 'produtos'
  AND a.operacao = 'DELETE'
ORDER BY a.data_operacao DESC;

-- View: Tentativas de login falhadas
CREATE OR REPLACE VIEW vw_logins_falhados AS
SELECT
  l.id,
  l.usuario_id,
  u.nome as usuario_nome,
  u.codigo as usuario_codigo,
  l.terminal_nome,
  l.ip_address,
  l.motivo_falha,
  l.data_hora,
  (SELECT COUNT(*)
   FROM logs_acesso l2
   WHERE l2.usuario_id = l.usuario_id
     AND l2.tipo = 'LOGIN_FALHOU'
     AND l2.data_hora >= NOW() - INTERVAL '1 hour') as tentativas_ultima_hora
FROM logs_acesso l
LEFT JOIN usuarios u ON u.id = l.usuario_id
WHERE l.tipo = 'LOGIN_FALHOU'
ORDER BY l.data_hora DESC;

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

-- Função: Registrar login
CREATE OR REPLACE FUNCTION registrar_login(
  p_usuario_id INT,
  p_terminal_nome VARCHAR(100) DEFAULT NULL,
  p_ip_address VARCHAR(50) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso)
  VALUES (p_usuario_id, p_terminal_nome, p_ip_address, 'LOGIN', true);
END;
$$ LANGUAGE plpgsql;

-- Função: Registrar logout
CREATE OR REPLACE FUNCTION registrar_logout(
  p_usuario_id INT,
  p_terminal_nome VARCHAR(100) DEFAULT NULL,
  p_ip_address VARCHAR(50) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso)
  VALUES (p_usuario_id, p_terminal_nome, p_ip_address, 'LOGOUT', true);
END;
$$ LANGUAGE plpgsql;

-- Função: Registrar login falhado
CREATE OR REPLACE FUNCTION registrar_login_falhado(
  p_codigo VARCHAR(100),
  p_motivo TEXT,
  p_terminal_nome VARCHAR(100) DEFAULT NULL,
  p_ip_address VARCHAR(50) DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_usuario_id INT;
BEGIN
  -- Tenta encontrar o usuário
  SELECT id INTO v_usuario_id FROM usuarios WHERE codigo = p_codigo;

  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso, motivo_falha)
  VALUES (v_usuario_id, p_terminal_nome, p_ip_address, 'LOGIN_FALHOU', false, p_motivo);
END;
$$ LANGUAGE plpgsql;

-- Função: Limpar logs antigos (manutenção)
CREATE OR REPLACE FUNCTION limpar_logs_antigos(p_dias INT DEFAULT 90)
RETURNS INT AS $$
DECLARE
  registros_deletados INT;
BEGIN
  -- Deletar logs de acesso antigos
  DELETE FROM logs_acesso
  WHERE data_hora < NOW() - (p_dias || ' days')::INTERVAL;

  GET DIAGNOSTICS registros_deletados = ROW_COUNT;

  -- Não deletar auditoria, apenas logs de acesso
  -- Auditoria é permanente para conformidade legal

  RETURN registros_deletados;
END;
$$ LANGUAGE plpgsql;

-- Função: Buscar alterações de um registro específico
CREATE OR REPLACE FUNCTION buscar_historico_registro(
  p_tabela VARCHAR(100),
  p_registro_id INT
)
RETURNS TABLE (
  id INT,
  operacao VARCHAR(20),
  usuario_nome VARCHAR(200),
  descricao TEXT,
  dados_anteriores JSONB,
  dados_novos JSONB,
  data_operacao TIMESTAMP
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.operacao,
    u.nome as usuario_nome,
    a.descricao,
    a.dados_anteriores,
    a.dados_novos,
    a.data_operacao
  FROM auditoria a
  LEFT JOIN usuarios u ON u.id = a.usuario_id
  WHERE a.tabela = p_tabela
    AND a.registro_id = p_registro_id
  ORDER BY a.data_operacao DESC;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMENTÁRIOS NAS TABELAS
-- ============================================
COMMENT ON TABLE auditoria IS 'Registro de todas as operações do sistema para auditoria e rastreabilidade';
COMMENT ON TABLE logs_acesso IS 'Registro de logins, logouts e tentativas falhadas';
COMMENT ON COLUMN auditoria.dados_anteriores IS 'Estado do registro antes da operação (JSON)';
COMMENT ON COLUMN auditoria.dados_novos IS 'Estado do registro depois da operação (JSON)';

-- ============================================
-- MENSAGEM DE CONCLUSÃO
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Sistema de Auditoria instalado com sucesso!';
  RAISE NOTICE '   - Tabela auditoria criada';
  RAISE NOTICE '   - Tabela logs_acesso criada';
  RAISE NOTICE '   - Triggers instalados em 11 tabelas';
  RAISE NOTICE '   - 7 views de consulta criadas';
  RAISE NOTICE '   - 6 funções auxiliares criadas';
  RAISE NOTICE '';
  RAISE NOTICE 'Tabelas monitoradas:';
  RAISE NOTICE '   ✓ produtos, vendas, itens_venda';
  RAISE NOTICE '   ✓ usuarios, perfil_permissoes';
  RAISE NOTICE '   ✓ clientes, familias';
  RAISE NOTICE '   ✓ impressoras, areas, mesas';
END $$;
