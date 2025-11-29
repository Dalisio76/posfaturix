-- ===================================
-- Sistema de Controle de Tempo
-- Proteção contra alteração de data do sistema
-- ===================================

-- 1. Criar tabela de registro de tempo do servidor
CREATE TABLE IF NOT EXISTS servidor_tempo (
    id SERIAL PRIMARY KEY,
    ultima_data_sistema TIMESTAMP NOT NULL,
    ultima_data_servidor TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Criar tabela para armazenar último fecho de caixa
CREATE TABLE IF NOT EXISTS controle_fecho_caixa (
    id SERIAL PRIMARY KEY,
    data_fecho DATE NOT NULL UNIQUE,
    usuario_id INTEGER REFERENCES usuarios(id),
    valor_total DECIMAL(10,2),
    fechado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Função para validar data de venda (não permite retroativas)
CREATE OR REPLACE FUNCTION validar_data_venda()
RETURNS TRIGGER AS $$
DECLARE
    ultima_data_registrada TIMESTAMP;
    data_ultimo_fecho DATE;
BEGIN
    -- Buscar última data registrada no servidor
    SELECT MAX(ultima_data_servidor) INTO ultima_data_registrada
    FROM servidor_tempo;

    -- Se houver registro e a nova data for anterior, REJEITAR
    IF ultima_data_registrada IS NOT NULL THEN
        IF NEW.data_venda < ultima_data_registrada - INTERVAL '1 hour' THEN
            RAISE EXCEPTION 'ERRO: Data da venda (%) é anterior à última operação registrada (%). Possível alteração de data do sistema detectada!',
                NEW.data_venda, ultima_data_registrada
                USING HINT = 'Verifique a data e hora do computador. Não é permitido vender com data retroativa.';
        END IF;
    END IF;

    -- Buscar data do último fecho de caixa
    SELECT MAX(data_fecho) INTO data_ultimo_fecho
    FROM controle_fecho_caixa;

    -- Se já houve fecho, não permitir venda em data anterior
    IF data_ultimo_fecho IS NOT NULL THEN
        IF DATE(NEW.data_venda) <= data_ultimo_fecho THEN
            RAISE EXCEPTION 'ERRO: Não é permitido vender em data (%) igual ou anterior ao último fecho de caixa (%)!',
                DATE(NEW.data_venda), data_ultimo_fecho
                USING HINT = 'O caixa já foi fechado. Ajuste a data do sistema se necessário.';
        END IF;
    END IF;

    -- Registrar timestamp atual do servidor
    INSERT INTO servidor_tempo (ultima_data_sistema, ultima_data_servidor)
    VALUES (NEW.data_venda, CURRENT_TIMESTAMP);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Criar trigger na tabela vendas
DROP TRIGGER IF EXISTS trigger_validar_data_venda ON vendas;
CREATE TRIGGER trigger_validar_data_venda
    BEFORE INSERT ON vendas
    FOR EACH ROW
    EXECUTE FUNCTION validar_data_venda();

-- 5. Função para registrar fecho de caixa
CREATE OR REPLACE FUNCTION registrar_fecho_caixa(
    p_data_fecho DATE,
    p_usuario_id INTEGER,
    p_valor_total DECIMAL(10,2)
)
RETURNS INTEGER AS $$
DECLARE
    ultima_data_registrada TIMESTAMP;
    data_ultimo_fecho DATE;
    fecho_id INTEGER;
BEGIN
    -- Verificar se data do fecho não é retroativa
    SELECT MAX(ultima_data_servidor) INTO ultima_data_registrada
    FROM servidor_tempo;

    IF ultima_data_registrada IS NOT NULL THEN
        IF p_data_fecho::TIMESTAMP < DATE(ultima_data_registrada) THEN
            RAISE EXCEPTION 'ERRO: Data do fecho (%) é anterior à última operação (%). Não é permitido fechar caixa retroativo!',
                p_data_fecho, DATE(ultima_data_registrada)
                USING HINT = 'Verifique a data do sistema.';
        END IF;
    END IF;

    -- Verificar se já existe fecho para esta data
    IF EXISTS (SELECT 1 FROM controle_fecho_caixa WHERE data_fecho = p_data_fecho) THEN
        RAISE EXCEPTION 'ERRO: Já existe fecho de caixa para a data %!', p_data_fecho
            USING HINT = 'Cada dia só pode ter um fecho de caixa.';
    END IF;

    -- Registrar fecho
    INSERT INTO controle_fecho_caixa (data_fecho, usuario_id, valor_total)
    VALUES (p_data_fecho, p_usuario_id, p_valor_total)
    RETURNING id INTO fecho_id;

    RETURN fecho_id;
END;
$$ LANGUAGE plpgsql;

-- 6. Função para verificar se pode vender (data OK)
CREATE OR REPLACE FUNCTION pode_vender_hoje()
RETURNS TABLE (
    pode_vender BOOLEAN,
    mensagem TEXT,
    data_sistema DATE,
    data_ultimo_fecho DATE,
    diferenca_dias INTEGER
) AS $$
DECLARE
    v_data_ultimo_fecho DATE;
    v_data_sistema DATE;
BEGIN
    v_data_sistema := CURRENT_DATE;

    SELECT MAX(data_fecho) INTO v_data_ultimo_fecho
    FROM controle_fecho_caixa;

    -- Se nunca houve fecho, pode vender
    IF v_data_ultimo_fecho IS NULL THEN
        RETURN QUERY SELECT
            true,
            'OK - Nenhum fecho anterior registrado',
            v_data_sistema,
            NULL::DATE,
            NULL::INTEGER;
        RETURN;
    END IF;

    -- Se data do sistema é posterior ao último fecho, OK
    IF v_data_sistema > v_data_ultimo_fecho THEN
        RETURN QUERY SELECT
            true,
            'OK - Data do sistema está correta',
            v_data_sistema,
            v_data_ultimo_fecho,
            (v_data_sistema - v_data_ultimo_fecho)::INTEGER;
        RETURN;
    END IF;

    -- Se data igual ou anterior, ERRO
    RETURN QUERY SELECT
        false,
        'ERRO - Data do sistema (' || v_data_sistema || ') está igual ou anterior ao último fecho (' || v_data_ultimo_fecho || '). Ajuste a data do computador!',
        v_data_sistema,
        v_data_ultimo_fecho,
        (v_data_sistema - v_data_ultimo_fecho)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- 7. View para monitorar anomalias de data
CREATE OR REPLACE VIEW vw_anomalias_data AS
SELECT
    v.id as venda_id,
    v.numero as venda_numero,
    v.data_venda,
    LAG(v.data_venda) OVER (ORDER BY v.id) as venda_anterior,
    v.data_venda - LAG(v.data_venda) OVER (ORDER BY v.id) as diferenca,
    CASE
        WHEN v.data_venda < LAG(v.data_venda) OVER (ORDER BY v.id) THEN 'RETROCESSO DETECTADO'
        WHEN (v.data_venda - LAG(v.data_venda) OVER (ORDER BY v.id)) > INTERVAL '1 day' THEN 'SALTO GRANDE'
        ELSE 'Normal'
    END as status
FROM vendas v
ORDER BY v.id DESC
LIMIT 100;

-- 8. Função para limpar registros antigos de servidor_tempo (manter últimos 7 dias)
CREATE OR REPLACE FUNCTION limpar_servidor_tempo()
RETURNS INTEGER AS $$
DECLARE
    linhas_deletadas INTEGER;
BEGIN
    DELETE FROM servidor_tempo
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '7 days');

    GET DIAGNOSTICS linhas_deletadas = ROW_COUNT;
    RETURN linhas_deletadas;
END;
$$ LANGUAGE plpgsql;

-- 9. Índices para performance
CREATE INDEX IF NOT EXISTS idx_servidor_tempo_data ON servidor_tempo(ultima_data_servidor DESC);
CREATE INDEX IF NOT EXISTS idx_controle_fecho_data ON controle_fecho_caixa(data_fecho DESC);

-- 10. Comentários
COMMENT ON TABLE servidor_tempo IS 'Registro de timestamps do servidor PostgreSQL para detectar alteração de data do sistema';
COMMENT ON TABLE controle_fecho_caixa IS 'Registro de fechos de caixa para impedir vendas retroativas';
COMMENT ON FUNCTION validar_data_venda() IS 'Trigger que impede vendas com data retroativa ou após alteração de data do sistema';
COMMENT ON FUNCTION pode_vender_hoje() IS 'Verifica se a data do sistema está correta para permitir vendas';

-- 11. Verificação
SELECT 'Sistema de controle de tempo instalado com sucesso!' as status;

-- Testar se pode vender hoje
SELECT * FROM pode_vender_hoje();

COMMIT;
