-- =====================================================
-- POSFATURIX - BASE DE DADOS LIMPA E COMPLETA
-- =====================================================
-- Extraído da base de dados em produção
-- Data de Extração: 06/12/2025
-- Versão: 2.5.0
--
-- INSTRUÇÕES:
-- 1. Conectar à base de dados já criada
-- 2. Executar este script completo
--
-- NOTA: Collation será a padrão do sistema (funciona em qualquer país)
-- =====================================================

CREATE FUNCTION public.abater_estoque_produto(p_produto_id integer, p_quantidade integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_contavel BOOLEAN;
    v_componente RECORD;
    v_quantidade_abater DECIMAL;
BEGIN
    -- Buscar se produto é contável
    SELECT contavel INTO v_contavel
    FROM produtos
    WHERE id = p_produto_id;

    -- Se produto é contável, abater estoque direto
    IF v_contavel THEN
        UPDATE produtos
        SET estoque = estoque - p_quantidade,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_produto_id;
        RETURN;
    END IF;

    -- Produto não-contável: abater estoque dos componentes
    FOR v_componente IN
        SELECT produto_componente_id, quantidade
        FROM produto_composicao
        WHERE produto_id = p_produto_id
    LOOP
        v_quantidade_abater := v_componente.quantidade * p_quantidade;

        UPDATE produtos
        SET estoque = estoque - v_quantidade_abater,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = v_componente.produto_componente_id;
    END LOOP;
END;
$$;


--
-- Name: abrir_caixa(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.abrir_caixa(p_terminal character varying DEFAULT 'TERMINAL-01'::character varying, p_usuario character varying DEFAULT 'Sistema'::character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_caixa_aberto_id INTEGER;
    v_novo_caixa_id INTEGER;
    v_numero VARCHAR(50);
BEGIN
    -- Verificar se já existe caixa aberto
    SELECT id INTO v_caixa_aberto_id
    FROM caixas
    WHERE status = 'ABERTO'
    LIMIT 1;

    IF v_caixa_aberto_id IS NOT NULL THEN
        RAISE EXCEPTION 'Já existe um caixa aberto (ID: %). Feche o caixa antes de abrir um novo.', v_caixa_aberto_id;
    END IF;

    -- Gerar número único do caixa
    v_numero := 'CX' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS');

    -- Inserir novo caixa
    INSERT INTO caixas (numero, terminal, usuario, data_abertura, status)
    VALUES (v_numero, p_terminal, p_usuario, NOW(), 'ABERTO')
    RETURNING id INTO v_novo_caixa_id;

    RAISE NOTICE 'Caixa % aberto com sucesso! ID: %', v_numero, v_novo_caixa_id;

    RETURN v_novo_caixa_id;
END;
$$;


--
-- Dependencies: 377
-- Name: FUNCTION abrir_caixa(p_terminal character varying, p_usuario character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.abrir_caixa(p_terminal character varying, p_usuario character varying) IS 'Abre um novo caixa. Impede abertura se já houver caixa aberto.';


--
-- Name: atualizar_data_configuracao(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_data_configuracao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.data_atualizacao = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: atualizar_estoque_produto(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_estoque_produto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualizar o estoque do produto com o novo valor
    UPDATE produtos
    SET estoque = NEW.estoque_novo,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.produto_id;

    RETURN NEW;
END;
$$;


--
-- Name: atualizar_total_pedido(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_total_pedido() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE pedidos
    SET total = calcular_total_pedido(
        CASE
            WHEN TG_OP = 'DELETE' THEN OLD.pedido_id
            ELSE NEW.pedido_id
        END
    )
    WHERE id = CASE
        WHEN TG_OP = 'DELETE' THEN OLD.pedido_id
        ELSE NEW.pedido_id
    END;

    RETURN CASE
        WHEN TG_OP = 'DELETE' THEN OLD
        ELSE NEW
    END;
END;
$$;


--
-- Name: atualizar_updated_at_impressoras(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_updated_at_impressoras() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: atualizar_updated_at_terminais(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_updated_at_terminais() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: atualizar_valor_restante(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.atualizar_valor_restante() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualizar valor_restante
    NEW.valor_restante := NEW.valor_total - NEW.valor_pago;
    
    -- Atualizar status
    IF NEW.valor_pago = 0 THEN
        NEW.status := 'PENDENTE';
    ELSIF NEW.valor_pago >= NEW.valor_total THEN
        NEW.status := 'PAGO';
    ELSE
        NEW.status := 'PARCIAL';
    END IF;
    
    RETURN NEW;
END;
$$;


--
-- Name: audit_trigger_func(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.audit_trigger_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: buscar_acertos_por_periodo(timestamp without time zone, timestamp without time zone, character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.buscar_acertos_por_periodo(p_data_inicio timestamp without time zone, p_data_fim timestamp without time zone, p_produto_nome character varying DEFAULT NULL::character varying, p_setor_id integer DEFAULT NULL::integer, p_area_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, produto_codigo character varying, produto_nome character varying, estoque_anterior integer, estoque_novo integer, diferenca integer, motivo character varying, setor_nome character varying, area_nome character varying, familia_nome character varying, usuario character varying, data timestamp without time zone, valor_diferenca numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        a.id,
        a.produto_codigo,
        a.produto_nome,
        a.estoque_anterior,
        a.estoque_novo,
        a.diferenca,
        a.motivo,
        a.setor_nome,
        a.area_nome,
        a.familia_nome,
        a.usuario,
        a.data,
        a.valor_diferenca
    FROM v_acertos_completo a
    WHERE a.data >= p_data_inicio
    AND a.data <= p_data_fim
    AND (p_produto_nome IS NULL OR a.produto_nome ILIKE '%' || p_produto_nome || '%')
    AND (p_setor_id IS NULL OR a.setor_id = p_setor_id)
    AND (p_area_id IS NULL OR a.area_id = p_area_id)
    ORDER BY a.data DESC;
END;
$$;


--
-- Name: buscar_historico_registro(character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.buscar_historico_registro(p_tabela character varying, p_registro_id integer) RETURNS TABLE(id integer, operacao character varying, usuario_nome character varying, descricao text, dados_anteriores jsonb, dados_novos jsonb, data_operacao timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: buscar_produto_por_codigo_barras(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.buscar_produto_por_codigo_barras(p_codigo_barras character varying) RETURNS TABLE(id integer, codigo character varying, nome character varying, codigo_barras character varying, familia_id integer, familia_nome character varying, preco numeric, estoque integer, ativo boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id,
        p.codigo,
        p.nome,
        p.codigo_barras,
        p.familia_id,
        f.nome as familia_nome,
        p.preco,
        p.estoque,
        p.ativo
    FROM produtos p
    LEFT JOIN familias f ON f.id = p.familia_id
    WHERE LOWER(p.codigo_barras) = LOWER(p_codigo_barras)
      AND p.ativo = true
    LIMIT 1;
END;
$$;


--
-- Dependencies: 391
-- Name: FUNCTION buscar_produto_por_codigo_barras(p_codigo_barras character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.buscar_produto_por_codigo_barras(p_codigo_barras character varying) IS 'Busca produto por código de barras escaneado';


--
-- Name: calcular_totais_caixa(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_totais_caixa(p_caixa_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_data_abertura TIMESTAMP;
    v_data_fechamento TIMESTAMP;
    v_total_cash DECIMAL(10,2);
    v_total_emola DECIMAL(10,2);
    v_total_mpesa DECIMAL(10,2);
    v_total_pos DECIMAL(10,2);
BEGIN
    -- Buscar datas do caixa
    SELECT data_abertura, COALESCE(data_fechamento, NOW())
    INTO v_data_abertura, v_data_fechamento
    FROM caixas
    WHERE id = p_caixa_id;

    IF v_data_abertura IS NULL THEN
        RAISE EXCEPTION 'Caixa não encontrado: %', p_caixa_id;
    END IF;

    -- ===================================
    -- 1. VENDAS PAGAS (tipo_venda = 'NORMAL')
    -- ===================================
    UPDATE caixas SET
        total_vendas_pagas = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
        ), 0),
        qtd_vendas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 2. VENDAS A CRÉDITO (tipo_venda = 'DIVIDA')
    -- ===================================
    UPDATE caixas SET
        total_vendas_credito = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'DIVIDA'
        ), 0),
        qtd_vendas_credito = COALESCE((
            SELECT COUNT(*)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'DIVIDA'
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 3. TOTAIS POR FORMA DE PAGAMENTO
    -- (Vendas pagas + Pagamentos de dívidas)
    -- ===================================

    -- 3.1. CASH
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_cash, v_total_pos -- usando v_total_pos temporariamente como contador
    FROM (
        -- Pagamentos de vendas em CASH
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'CASH'

        UNION ALL

        -- Pagamentos de dívidas em CASH
        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'CASH'
    ) AS todos_cash;

    UPDATE caixas SET
        total_cash = v_total_cash,
        qtd_transacoes_cash = v_total_pos -- contador temporário
    WHERE id = p_caixa_id;

    -- 3.2. EMOLA
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_emola, v_total_pos
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'EMOLA'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'EMOLA'
    ) AS todos_emola;

    UPDATE caixas SET
        total_emola = v_total_emola,
        qtd_transacoes_emola = v_total_pos
    WHERE id = p_caixa_id;

    -- 3.3. MPESA
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_mpesa, v_total_pos
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'MPESA'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'MPESA'
    ) AS todos_mpesa;

    UPDATE caixas SET
        total_mpesa = v_total_mpesa,
        qtd_transacoes_mpesa = v_total_pos
    WHERE id = p_caixa_id;

    -- 3.4. POS
    SELECT
        COALESCE(SUM(valor), 0),
        COALESCE(COUNT(*), 0)
    INTO v_total_pos, v_total_cash -- reutilizando variável
    FROM (
        SELECT pv.valor
        FROM pagamentos_venda pv
        INNER JOIN vendas v ON pv.venda_id = v.id
        INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
        WHERE v.data_venda >= v_data_abertura
          AND v.data_venda <= v_data_fechamento
          AND UPPER(fp.nome) = 'POS'

        UNION ALL

        SELECT pd.valor
        FROM pagamentos_divida pd
        INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
        WHERE pd.data_pagamento >= v_data_abertura
          AND pd.data_pagamento <= v_data_fechamento
          AND UPPER(fp.nome) = 'POS'
    ) AS todos_pos;

    UPDATE caixas SET
        total_pos = v_total_pos,
        qtd_transacoes_pos = v_total_cash -- contador temporário
    WHERE id = p_caixa_id;

    -- ===================================
    -- 4. PAGAMENTOS DE DÍVIDAS (TOTAL GERAL)
    -- ===================================
    UPDATE caixas SET
        total_dividas_pagas = COALESCE((
            SELECT SUM(pd.valor)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0),
        qtd_dividas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 5. DESPESAS
    -- ===================================
    UPDATE caixas SET
        total_despesas = COALESCE((
            SELECT SUM(valor)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0),
        qtd_despesas = COALESCE((
            SELECT COUNT(*)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0)
    WHERE id = p_caixa_id;

    -- ===================================
    -- 6. CALCULAR SALDO FINAL
    -- ===================================
    UPDATE caixas SET
        total_entradas = total_vendas_pagas + total_dividas_pagas,
        total_saidas = total_despesas,
        saldo_final = (total_vendas_pagas + total_dividas_pagas) - total_despesas
    WHERE id = p_caixa_id;

    -- ===================================
    -- 7. VALIDAÇÃO (a soma deve bater!)
    -- ===================================
    SELECT
        total_cash + total_emola + total_mpesa + total_pos
    INTO v_total_cash -- reutilizando para validação
    FROM caixas WHERE id = p_caixa_id;

    -- A soma das formas DEVE ser igual ao total de entradas
    -- Se não bater, algo está errado!
    IF ABS(v_total_cash - (SELECT total_entradas FROM caixas WHERE id = p_caixa_id)) > 0.01 THEN
        RAISE WARNING 'ATENÇÃO: Soma das formas (%) diferente do total de entradas (%). Verificar!',
            v_total_cash,
            (SELECT total_entradas FROM caixas WHERE id = p_caixa_id);
    END IF;

END;
$$;


--
-- Dependencies: 384
-- Name: FUNCTION calcular_totais_caixa(p_caixa_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.calcular_totais_caixa(p_caixa_id integer) IS 'Calcula todos os totais do caixa considerando múltiplas formas de pagamento por venda';


--
-- Name: calcular_total_pedido(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calcular_total_pedido(p_pedido_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total DECIMAL(10,2);
BEGIN
    SELECT COALESCE(SUM(subtotal), 0)
    INTO v_total
    FROM itens_pedido
    WHERE pedido_id = p_pedido_id;

    RETURN v_total;
END;
$$;


--
-- Name: familia_pertence_setor(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.familia_pertence_setor(p_familia_id integer, p_setor_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM familia_setores
        WHERE familia_id = p_familia_id
        AND setor_id = p_setor_id
    );
END;
$$;


--
-- Name: fechar_caixa(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fechar_caixa(p_caixa_id integer, p_observacoes text DEFAULT NULL::text) RETURNS TABLE(sucesso boolean, numero_caixa character varying, saldo_final_retorno numeric, total_entradas_retorno numeric, total_saidas_retorno numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_status VARCHAR(20);
    v_numero VARCHAR(50);
BEGIN
    -- Verificar se caixa existe
    SELECT status, numero INTO v_status, v_numero
    FROM caixas
    WHERE id = p_caixa_id;

    IF v_numero IS NULL THEN
        RAISE EXCEPTION 'Caixa % não encontrado', p_caixa_id;
    END IF;

    IF v_status = 'FECHADO' THEN
        RAISE EXCEPTION 'Caixa % já está fechado', v_numero;
    END IF;

    -- Calcular todos os totais
    PERFORM calcular_totais_caixa(p_caixa_id);

    -- Fechar o caixa
    UPDATE caixas
    SET status = 'FECHADO',
        data_fechamento = NOW(),
        observacoes = p_observacoes
    WHERE id = p_caixa_id;

    RAISE NOTICE 'Caixa % fechado com sucesso!', v_numero;

    -- Retornar informações do fechamento
    RETURN QUERY
    SELECT
        TRUE,
        c.numero,
        c.saldo_final,
        c.total_entradas,
        c.total_saidas
    FROM caixas c
    WHERE c.id = p_caixa_id;
END;
$$;


--
-- Dependencies: 378
-- Name: FUNCTION fechar_caixa(p_caixa_id integer, p_observacoes text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fechar_caixa(p_caixa_id integer, p_observacoes text) IS 'Fecha o caixa, calcula totais e retorna resumo do fechamento';


--
-- Name: get_composicao_produto(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_composicao_produto(p_produto_id integer) RETURNS TABLE(componente_id integer, componente_codigo character varying, componente_nome character varying, quantidade numeric, estoque_disponivel integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        pc.produto_componente_id,
        comp.codigo,
        comp.nome,
        pc.quantidade,
        comp.estoque
    FROM produto_composicao pc
    INNER JOIN produtos comp ON pc.produto_componente_id = comp.id
    WHERE pc.produto_id = p_produto_id
    AND comp.ativo = true
    ORDER BY comp.nome;
END;
$$;


--
-- Name: get_familia_setores(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_familia_setores(p_familia_id integer) RETURNS TABLE(setor_id integer, setor_nome character varying, setor_descricao text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT s.id, s.nome, s.descricao
    FROM setores s
    INNER JOIN familia_setores fs ON s.id = fs.setor_id
    WHERE fs.familia_id = p_familia_id
    AND s.ativo = true
    ORDER BY s.nome;
END;
$$;


--
-- Name: get_produtos_por_area(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_produtos_por_area(p_area_id integer) RETURNS TABLE(id integer, codigo character varying, nome character varying, preco numeric, estoque integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.area_id = p_area_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$;


--
-- Name: get_produtos_por_setor(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_produtos_por_setor(p_setor_id integer) RETURNS TABLE(id integer, codigo character varying, nome character varying, preco numeric, estoque integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.setor_id = p_setor_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$;


--
-- Name: get_produtos_por_setor_e_area(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_produtos_por_setor_e_area(p_setor_id integer, p_area_id integer) RETURNS TABLE(id integer, codigo character varying, nome character varying, preco numeric, estoque integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.codigo, p.nome, p.preco, p.estoque
    FROM produtos p
    WHERE p.setor_id = p_setor_id
    AND p.area_id = p_area_id
    AND p.ativo = true
    ORDER BY p.nome;
END;
$$;


--
-- Name: get_proximo_codigo_produto(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_proximo_codigo_produto() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN nextval('produtos_codigo_seq')::TEXT;
END;
$$;


--
-- Name: limpar_logs_antigos(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.limpar_logs_antigos(p_dias integer DEFAULT 90) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: limpar_logs_terminais(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.limpar_logs_terminais() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    linhas_deletadas INTEGER;
BEGIN
    DELETE FROM terminal_logs
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '30 days');

    GET DIAGNOSTICS linhas_deletadas = ROW_COUNT;
    RETURN linhas_deletadas;
END;
$$;


--
-- Name: limpar_servidor_tempo(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.limpar_servidor_tempo() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    linhas_deletadas INTEGER;
BEGIN
    DELETE FROM servidor_tempo
    WHERE created_at < (CURRENT_TIMESTAMP - INTERVAL '7 days');

    GET DIAGNOSTICS linhas_deletadas = ROW_COUNT;
    RETURN linhas_deletadas;
END;
$$;


--
-- Name: pode_vender_hoje(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.pode_vender_hoje() RETURNS TABLE(pode_vender boolean, mensagem text, data_sistema date, data_ultimo_fecho date, diferenca_dias integer)
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Dependencies: 403
-- Name: FUNCTION pode_vender_hoje(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.pode_vender_hoje() IS 'Verifica se a data do sistema está correta para permitir vendas';


--
-- Name: registrar_acerto_stock(integer, integer, character varying, text, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_acerto_stock(p_produto_id integer, p_estoque_novo integer, p_motivo character varying, p_observacao text DEFAULT NULL::text, p_usuario character varying DEFAULT 'Sistema'::character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estoque_anterior INTEGER;
    v_acerto_id INTEGER;
    v_setor_id INTEGER;
    v_area_id INTEGER;
BEGIN
    -- Obter estoque anterior e setor/área do produto
    SELECT estoque, setor_id, area_id
    INTO v_estoque_anterior, v_setor_id, v_area_id
    FROM produtos
    WHERE id = p_produto_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Produto com ID % não encontrado', p_produto_id;
    END IF;

    -- Inserir acerto
    INSERT INTO acertos_stock (
        produto_id,
        estoque_anterior,
        estoque_novo,
        motivo,
        observacao,
        setor_id,
        area_id,
        usuario
    ) VALUES (
        p_produto_id,
        v_estoque_anterior,
        p_estoque_novo,
        p_motivo,
        p_observacao,
        v_setor_id,
        v_area_id,
        p_usuario
    )
    RETURNING id INTO v_acerto_id;

    RETURN v_acerto_id;
END;
$$;


--
-- Name: registrar_conexao_terminal(integer, integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_conexao_terminal(p_terminal_id integer, p_usuario_id integer DEFAULT NULL::integer, p_ip_address character varying DEFAULT NULL::character varying, p_acao character varying DEFAULT 'heartbeat'::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Atualizar última conexão
    UPDATE terminais
    SET ultima_conexao = CURRENT_TIMESTAMP,
        ip_address = COALESCE(p_ip_address, ip_address)
    WHERE id = p_terminal_id;

    -- Inserir log
    INSERT INTO terminal_logs (terminal_id, usuario_id, ip_address, acao)
    VALUES (p_terminal_id, p_usuario_id, p_ip_address, p_acao);
END;
$$;


--
-- Name: registrar_conferencia_caixa(integer, numeric, numeric, numeric, numeric, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_conferencia_caixa(p_caixa_id integer, p_contado_cash numeric DEFAULT 0, p_contado_emola numeric DEFAULT 0, p_contado_mpesa numeric DEFAULT 0, p_contado_pos numeric DEFAULT 0, p_observacoes text DEFAULT NULL::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_sistema_cash DECIMAL(10,2);
    v_sistema_emola DECIMAL(10,2);
    v_sistema_mpesa DECIMAL(10,2);
    v_sistema_pos DECIMAL(10,2);
    v_conferencia_id INTEGER;
BEGIN
    -- Buscar valores do sistema
    SELECT
        total_cash,
        total_emola,
        total_mpesa,
        total_pos
    INTO
        v_sistema_cash,
        v_sistema_emola,
        v_sistema_mpesa,
        v_sistema_pos
    FROM caixas
    WHERE id = p_caixa_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Caixa não encontrado: %', p_caixa_id;
    END IF;

    -- Inserir conferência
    INSERT INTO conferencias_caixa (
        caixa_id,
        sistema_cash,
        sistema_emola,
        sistema_mpesa,
        sistema_pos,
        sistema_total,
        contado_cash,
        contado_emola,
        contado_mpesa,
        contado_pos,
        contado_total,
        diferenca_cash,
        diferenca_emola,
        diferenca_mpesa,
        diferenca_pos,
        diferenca_total,
        conferencia_ok,
        observacoes
    ) VALUES (
        p_caixa_id,
        v_sistema_cash,
        v_sistema_emola,
        v_sistema_mpesa,
        v_sistema_pos,
        v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos,
        p_contado_cash,
        p_contado_emola,
        p_contado_mpesa,
        p_contado_pos,
        p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos,
        p_contado_cash - v_sistema_cash,
        p_contado_emola - v_sistema_emola,
        p_contado_mpesa - v_sistema_mpesa,
        p_contado_pos - v_sistema_pos,
        (p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos) -
        (v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos),
        (p_contado_cash + p_contado_emola + p_contado_mpesa + p_contado_pos) =
        (v_sistema_cash + v_sistema_emola + v_sistema_mpesa + v_sistema_pos),
        p_observacoes
    )
    RETURNING id INTO v_conferencia_id;

    RETURN v_conferencia_id;
END;
$$;


--
-- Dependencies: 385
-- Name: FUNCTION registrar_conferencia_caixa(p_caixa_id integer, p_contado_cash numeric, p_contado_emola numeric, p_contado_mpesa numeric, p_contado_pos numeric, p_observacoes text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.registrar_conferencia_caixa(p_caixa_id integer, p_contado_cash numeric, p_contado_emola numeric, p_contado_mpesa numeric, p_contado_pos numeric, p_observacoes text) IS 'Registra a conferência manual dos valores do caixa';


--
-- Name: registrar_fecho_caixa(date, integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_fecho_caixa(p_data_fecho date, p_usuario_id integer, p_valor_total numeric) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Name: registrar_login(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_login(p_usuario_id integer, p_terminal_nome character varying DEFAULT NULL::character varying, p_ip_address character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso)
  VALUES (p_usuario_id, p_terminal_nome, p_ip_address, 'LOGIN', true);
END;
$$;


--
-- Name: registrar_login_falhado(character varying, text, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_login_falhado(p_codigo character varying, p_motivo text, p_terminal_nome character varying DEFAULT NULL::character varying, p_ip_address character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_usuario_id INT;
BEGIN
  -- Tenta encontrar o usuário
  SELECT id INTO v_usuario_id FROM usuarios WHERE codigo = p_codigo;

  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso, motivo_falha)
  VALUES (v_usuario_id, p_terminal_nome, p_ip_address, 'LOGIN_FALHOU', false, p_motivo);
END;
$$;


--
-- Name: registrar_logout(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_logout(p_usuario_id integer, p_terminal_nome character varying DEFAULT NULL::character varying, p_ip_address character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO logs_acesso (usuario_id, terminal_nome, ip_address, tipo, sucesso)
  VALUES (p_usuario_id, p_terminal_nome, p_ip_address, 'LOGOUT', true);
END;
$$;


--
-- Name: registrar_pagamento_divida(integer, numeric, integer, text, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.registrar_pagamento_divida(p_divida_id integer, p_valor numeric, p_forma_pagamento_id integer, p_observacoes text DEFAULT NULL::text, p_usuario character varying DEFAULT NULL::character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_valor_restante DECIMAL(10,2);
BEGIN
    -- Buscar valor restante
    SELECT valor_restante INTO v_valor_restante
    FROM dividas
    WHERE id = p_divida_id;
    
    -- Validar se dívida existe
    IF v_valor_restante IS NULL THEN
        RAISE EXCEPTION 'Dívida não encontrada';
    END IF;
    
    -- Validar se valor não excede restante
    IF p_valor > v_valor_restante THEN
        RAISE EXCEPTION 'Valor excede o restante da dívida';
    END IF;
    
    -- Inserir pagamento
    INSERT INTO pagamentos_divida (divida_id, valor, forma_pagamento_id, observacoes, usuario)
    VALUES (p_divida_id, p_valor, p_forma_pagamento_id, p_observacoes, p_usuario);
    
    -- Atualizar valor_pago na dívida
    UPDATE dividas
    SET valor_pago = valor_pago + p_valor
    WHERE id = p_divida_id;
    
    RETURN TRUE;
END;
$$;


--
-- Name: trigger_gerar_codigo_produto(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_gerar_codigo_produto() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Se código não foi fornecido ou está vazio, gerar automaticamente
    IF NEW.codigo IS NULL OR NEW.codigo = '' THEN
        NEW.codigo := get_proximo_codigo_produto();
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: trigger_validar_codigo_barras(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_validar_codigo_barras() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.codigo_barras IS NOT NULL THEN
        -- Remove espaços em branco
        NEW.codigo_barras := TRIM(NEW.codigo_barras);

        -- Se ficou vazio, transforma em NULL
        IF NEW.codigo_barras = '' THEN
            NEW.codigo_barras := NULL;
            RETURN NEW;
        END IF;

        -- Valida formato
        IF NOT validar_codigo_barras(NEW.codigo_barras) THEN
            RAISE EXCEPTION 'Código de barras inválido: %. Use apenas números com 6, 8, 12 ou 13 dígitos (EAN/UPC).',
                NEW.codigo_barras
                USING HINT = 'Formatos válidos: EAN-13 (13 dígitos), EAN-8 (8 dígitos), UPC-A (12 dígitos), UPC-E (6 dígitos)';
        END IF;

        -- Verifica duplicidade
        IF EXISTS (
            SELECT 1 FROM produtos
            WHERE codigo_barras = NEW.codigo_barras
              AND id != COALESCE(NEW.id, -1)
        ) THEN
            RAISE EXCEPTION 'Código de barras % já existe em outro produto!', NEW.codigo_barras
                USING HINT = 'Cada código de barras deve ser único.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: usuario_tem_permissao(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.usuario_tem_permissao(p_usuario_id integer, p_codigo_permissao character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tem_permissao BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM usuarios u
        INNER JOIN perfil_permissoes pp ON pp.perfil_id = u.perfil_id
        INNER JOIN permissoes perm ON perm.id = pp.permissao_id
        WHERE u.id = p_usuario_id
        AND perm.codigo = p_codigo_permissao
        AND u.ativo = true
        AND perm.ativo = true
    ) INTO v_tem_permissao;

    RETURN v_tem_permissao;
END;
$$;


--
-- Name: validar_codigo_barras(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validar_codigo_barras(p_codigo character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
DECLARE
    tamanho INTEGER;
BEGIN
    -- Remove espaços e verifica se está vazio
    p_codigo := TRIM(p_codigo);
    IF p_codigo IS NULL OR p_codigo = '' THEN
        RETURN true; -- NULL é válido (opcional)
    END IF;

    -- Verifica se contém apenas dígitos
    IF p_codigo !~ '^[0-9]+$' THEN
        RETURN false;
    END IF;

    tamanho := LENGTH(p_codigo);

    -- Tamanhos válidos: EAN-13 (13), EAN-8 (8), UPC-A (12), UPC-E (6)
    IF tamanho NOT IN (6, 8, 12, 13) THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$_$;


--
-- Dependencies: 392
-- Name: FUNCTION validar_codigo_barras(p_codigo character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.validar_codigo_barras(p_codigo character varying) IS 'Valida formato de código de barras (EAN/UPC)';


--
-- Name: validar_data_venda(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validar_data_venda() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- Dependencies: 401
-- Name: FUNCTION validar_data_venda(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.validar_data_venda() IS 'Trigger que impede vendas com data retroativa ou após alteração de data do sistema';


--
-- Name: verificar_estoque_disponivel(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verificar_estoque_disponivel(p_produto_id integer, p_quantidade_desejada integer) RETURNS TABLE(disponivel boolean, mensagem text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_contavel BOOLEAN;
    v_estoque INTEGER;
    v_tem_composicao BOOLEAN;
    v_componente RECORD;
    v_quantidade_necessaria DECIMAL;
    v_estoque_componente INTEGER;
BEGIN
    -- Buscar informações do produto
    SELECT contavel, estoque INTO v_contavel, v_estoque
    FROM produtos
    WHERE id = p_produto_id;

    -- Se produto é contável, verificar estoque direto
    IF v_contavel THEN
        IF v_estoque >= p_quantidade_desejada THEN
            RETURN QUERY SELECT true, 'Estoque disponível'::TEXT;
        ELSE
            RETURN QUERY SELECT false, format('Estoque insuficiente. Disponível: %s, Necessário: %s', v_estoque, p_quantidade_desejada)::TEXT;
        END IF;
        RETURN;
    END IF;

    -- Produto não-contável: verificar composição
    SELECT EXISTS(SELECT 1 FROM produto_composicao WHERE produto_id = p_produto_id) INTO v_tem_composicao;

    IF NOT v_tem_composicao THEN
        RETURN QUERY SELECT true, 'Produto não-contável sem composição'::TEXT;
        RETURN;
    END IF;

    -- Verificar estoque de cada componente
    FOR v_componente IN
        SELECT pc.produto_componente_id, pc.quantidade, comp.nome, comp.estoque
        FROM produto_composicao pc
        INNER JOIN produtos comp ON pc.produto_componente_id = comp.id
        WHERE pc.produto_id = p_produto_id
    LOOP
        v_quantidade_necessaria := v_componente.quantidade * p_quantidade_desejada;

        IF v_componente.estoque < v_quantidade_necessaria THEN
            RETURN QUERY SELECT
                false,
                format('Estoque insuficiente de "%s". Disponível: %s, Necessário: %s',
                    v_componente.nome,
                    v_componente.estoque,
                    v_quantidade_necessaria)::TEXT;
            RETURN;
        END IF;
    END LOOP;

    -- Todos os componentes têm estoque
    RETURN QUERY SELECT true, 'Estoque disponível (componentes)'::TEXT;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acertos_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acertos_stock (
    id integer NOT NULL,
    produto_id integer NOT NULL,
    estoque_anterior integer NOT NULL,
    estoque_novo integer NOT NULL,
    diferenca integer GENERATED ALWAYS AS ((estoque_novo - estoque_anterior)) STORED,
    motivo character varying(100) NOT NULL,
    observacao text,
    setor_id integer,
    area_id integer,
    usuario character varying(100),
    data timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: acertos_stock_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.acertos_stock_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 277
-- Name: acertos_stock_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.acertos_stock_id_seq OWNED BY public.acertos_stock.id;


--
-- Name: areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.areas (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    impressora_id integer
);


--
-- Dependencies: 235
-- Name: COLUMN areas.impressora_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.areas.impressora_id IS 'Impressora padrão para esta área';


--
-- Name: areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 234
-- Name: areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.areas_id_seq OWNED BY public.areas.id;


--
-- Name: auditoria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auditoria (
    id integer NOT NULL,
    tabela character varying(100) NOT NULL,
    operacao character varying(20) NOT NULL,
    registro_id integer,
    usuario_id integer,
    terminal_nome character varying(100),
    dados_anteriores jsonb,
    dados_novos jsonb,
    ip_address character varying(50),
    descricao text,
    data_operacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 344
-- Name: TABLE auditoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.auditoria IS 'Registro de todas as operações do sistema para auditoria e rastreabilidade';


--
-- Dependencies: 344
-- Name: COLUMN auditoria.dados_anteriores; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.auditoria.dados_anteriores IS 'Estado do registro antes da operação (JSON)';


--
-- Dependencies: 344
-- Name: COLUMN auditoria.dados_novos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.auditoria.dados_novos IS 'Estado do registro depois da operação (JSON)';


--
-- Name: auditoria_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auditoria_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 343
-- Name: auditoria_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auditoria_id_seq OWNED BY public.auditoria.id;


--
-- Name: caixas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.caixas (
    id integer NOT NULL,
    numero character varying(50) NOT NULL,
    terminal character varying(50),
    usuario character varying(100),
    data_abertura timestamp without time zone NOT NULL,
    data_fechamento timestamp without time zone,
    status character varying(20) DEFAULT 'ABERTO'::character varying,
    total_vendas_pagas numeric(10,2) DEFAULT 0,
    qtd_vendas_pagas integer DEFAULT 0,
    total_cash numeric(10,2) DEFAULT 0,
    qtd_transacoes_cash integer DEFAULT 0,
    total_emola numeric(10,2) DEFAULT 0,
    qtd_transacoes_emola integer DEFAULT 0,
    total_mpesa numeric(10,2) DEFAULT 0,
    qtd_transacoes_mpesa integer DEFAULT 0,
    total_pos numeric(10,2) DEFAULT 0,
    qtd_transacoes_pos integer DEFAULT 0,
    total_vendas_credito numeric(10,2) DEFAULT 0,
    qtd_vendas_credito integer DEFAULT 0,
    total_dividas_pagas numeric(10,2) DEFAULT 0,
    qtd_dividas_pagas integer DEFAULT 0,
    total_despesas numeric(10,2) DEFAULT 0,
    qtd_despesas integer DEFAULT 0,
    total_entradas numeric(10,2) DEFAULT 0,
    total_saidas numeric(10,2) DEFAULT 0,
    saldo_final numeric(10,2) DEFAULT 0,
    observacoes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 255
-- Name: TABLE caixas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.caixas IS 'Controle de abertura e fechamento de caixa com totais detalhados';


--
-- Dependencies: 255
-- Name: COLUMN caixas.total_vendas_pagas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.caixas.total_vendas_pagas IS 'Soma de vendas pagas (tipo_venda = NORMAL)';


--
-- Dependencies: 255
-- Name: COLUMN caixas.total_cash; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.caixas.total_cash IS 'Soma de TODAS transações em CASH (vendas + pagamentos de dívidas)';


--
-- Dependencies: 255
-- Name: COLUMN caixas.total_vendas_credito; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.caixas.total_vendas_credito IS 'Soma de vendas a crédito (tipo_venda = DIVIDA) - não entra no saldo';


--
-- Dependencies: 255
-- Name: COLUMN caixas.saldo_final; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.caixas.saldo_final IS 'Dinheiro real em caixa = (vendas_pagas + dividas_pagas) - despesas';


--
-- Name: caixas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.caixas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 254
-- Name: caixas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.caixas_id_seq OWNED BY public.caixas.id;


--
-- Name: cancelamentos_item_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.cancelamentos_item_pedido (
    id integer NOT NULL,
    item_pedido_id integer NOT NULL,
    pedido_id integer NOT NULL,
    produto_id integer NOT NULL,
    produto_nome character varying(200) NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    usuario_id integer NOT NULL,
    usuario_nome character varying(200),
    justificativa text NOT NULL,
    data_cancelamento timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 319
-- Name: TABLE cancelamentos_item_pedido; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.cancelamentos_item_pedido IS 'Log de itens cancelados de pedidos com justificativa';


--
-- Dependencies: 319
-- Name: COLUMN cancelamentos_item_pedido.justificativa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.cancelamentos_item_pedido.justificativa IS 'Motivo do cancelamento do item';


--
-- Name: cancelamentos_item_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.cancelamentos_item_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 318
-- Name: cancelamentos_item_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.cancelamentos_item_pedido_id_seq OWNED BY public.cancelamentos_item_pedido.id;


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    contacto character varying(50),
    contacto2 character varying(50),
    email character varying(100),
    endereco text,
    bairro character varying(100),
    cidade character varying(100),
    nuit character varying(50),
    observacoes text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 243
-- Name: TABLE clientes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.clientes IS 'Cadastro de clientes';


--
-- Name: clientes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.clientes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 242
-- Name: clientes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.clientes_id_seq OWNED BY public.clientes.id;


--
-- Name: conferencias_caixa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conferencias_caixa (
    id integer NOT NULL,
    caixa_id integer NOT NULL,
    sistema_cash numeric(10,2) DEFAULT 0,
    sistema_emola numeric(10,2) DEFAULT 0,
    sistema_mpesa numeric(10,2) DEFAULT 0,
    sistema_pos numeric(10,2) DEFAULT 0,
    sistema_total numeric(10,2) DEFAULT 0,
    contado_cash numeric(10,2) DEFAULT 0,
    contado_emola numeric(10,2) DEFAULT 0,
    contado_mpesa numeric(10,2) DEFAULT 0,
    contado_pos numeric(10,2) DEFAULT 0,
    contado_total numeric(10,2) DEFAULT 0,
    diferenca_cash numeric(10,2) DEFAULT 0,
    diferenca_emola numeric(10,2) DEFAULT 0,
    diferenca_mpesa numeric(10,2) DEFAULT 0,
    diferenca_pos numeric(10,2) DEFAULT 0,
    diferenca_total numeric(10,2) DEFAULT 0,
    conferencia_ok boolean DEFAULT false,
    observacoes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 257
-- Name: TABLE conferencias_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.conferencias_caixa IS 'Registra a conferência manual dos valores ao fechar o caixa (FASE 1)';


--
-- Name: conferencias_caixa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conferencias_caixa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 256
-- Name: conferencias_caixa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conferencias_caixa_id_seq OWNED BY public.conferencias_caixa.id;


--
-- Name: configuracoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configuracoes (
    id integer NOT NULL,
    chave character varying(100) NOT NULL,
    valor text,
    tipo character varying(20) DEFAULT 'string'::character varying NOT NULL,
    descricao text,
    categoria character varying(50),
    data_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 322
-- Name: TABLE configuracoes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.configuracoes IS 'Armazena configurações globais do sistema';


--
-- Dependencies: 322
-- Name: COLUMN configuracoes.chave; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.configuracoes.chave IS 'Chave única da configuração';


--
-- Dependencies: 322
-- Name: COLUMN configuracoes.valor; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.configuracoes.valor IS 'Valor da configuração (armazenado como texto)';


--
-- Dependencies: 322
-- Name: COLUMN configuracoes.tipo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.configuracoes.tipo IS 'Tipo do valor: string, boolean, integer, decimal';


--
-- Dependencies: 322
-- Name: COLUMN configuracoes.descricao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.configuracoes.descricao IS 'Descrição da configuração';


--
-- Dependencies: 322
-- Name: COLUMN configuracoes.categoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.configuracoes.categoria IS 'Categoria da configuração: vendas, seguranca, sistema, etc';


--
-- Name: configuracoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configuracoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 321
-- Name: configuracoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configuracoes_id_seq OWNED BY public.configuracoes.id;


--
-- Name: controle_fecho_caixa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.controle_fecho_caixa (
    id integer NOT NULL,
    data_fecho date NOT NULL,
    usuario_id integer,
    valor_total numeric(10,2),
    fechado_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 341
-- Name: TABLE controle_fecho_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.controle_fecho_caixa IS 'Registro de fechos de caixa para impedir vendas retroativas';


--
-- Name: controle_fecho_caixa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.controle_fecho_caixa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 340
-- Name: controle_fecho_caixa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.controle_fecho_caixa_id_seq OWNED BY public.controle_fecho_caixa.id;


--
-- Name: despesas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.despesas (
    id integer NOT NULL,
    descricao text NOT NULL,
    valor numeric(10,2) NOT NULL,
    categoria character varying(100),
    data_despesa timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento_id integer,
    observacoes text,
    usuario character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 249
-- Name: TABLE despesas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.despesas IS 'Registro de despesas do estabelecimento';


--
-- Name: despesas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.despesas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 248
-- Name: despesas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.despesas_id_seq OWNED BY public.despesas.id;


--
-- Name: dividas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.dividas (
    id integer NOT NULL,
    cliente_id integer NOT NULL,
    venda_id integer,
    valor_total numeric(10,2) NOT NULL,
    valor_pago numeric(10,2) DEFAULT 0,
    valor_restante numeric(10,2) NOT NULL,
    status character varying(20) DEFAULT 'PENDENTE'::character varying,
    observacoes text,
    data_divida timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_vencimento timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 245
-- Name: TABLE dividas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.dividas IS 'Registro de dívidas de clientes';


--
-- Dependencies: 245
-- Name: COLUMN dividas.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.dividas.status IS 'PENDENTE: Não pagou nada, PARCIAL: Pagou parte, PAGO: Quitado';


--
-- Name: dividas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dividas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 244
-- Name: dividas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dividas_id_seq OWNED BY public.dividas.id;


--
-- Name: documento_impressora; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documento_impressora (
    id integer NOT NULL,
    tipo_documento_id integer NOT NULL,
    impressora_id integer NOT NULL,
    prioridade integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 328
-- Name: TABLE documento_impressora; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.documento_impressora IS 'Mapeamento de documentos para impressoras';


--
-- Name: documento_impressora_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documento_impressora_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 327
-- Name: documento_impressora_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.documento_impressora_id_seq OWNED BY public.documento_impressora.id;


--
-- Name: empresa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.empresa (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    nuit character varying(50),
    endereco text,
    cidade character varying(100),
    email character varying(100),
    contacto character varying(50),
    logo_url text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: empresa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.empresa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 228
-- Name: empresa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.empresa_id_seq OWNED BY public.empresa.id;


--
-- Name: familia_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.familia_areas (
    id integer NOT NULL,
    familia_id integer NOT NULL,
    area_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 304
-- Name: TABLE familia_areas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.familia_areas IS 'Relacionamento many-to-many entre famílias e áreas';


--
-- Dependencies: 304
-- Name: COLUMN familia_areas.familia_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.familia_areas.familia_id IS 'ID da família';


--
-- Dependencies: 304
-- Name: COLUMN familia_areas.area_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.familia_areas.area_id IS 'ID da área';


--
-- Name: familia_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.familia_areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 303
-- Name: familia_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.familia_areas_id_seq OWNED BY public.familia_areas.id;


--
-- Name: familia_setores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.familia_setores (
    id integer NOT NULL,
    familia_id integer NOT NULL,
    setor_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: familia_setores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.familia_setores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 259
-- Name: familia_setores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.familia_setores_id_seq OWNED BY public.familia_setores.id;


--
-- Name: familias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.familias (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: familias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.familias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 219
-- Name: familias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.familias_id_seq OWNED BY public.familias.id;


--
-- Name: faturas_entrada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.faturas_entrada (
    id integer NOT NULL,
    fornecedor_id integer NOT NULL,
    numero_fatura character varying(50) NOT NULL,
    data_fatura date NOT NULL,
    total numeric(10,2) NOT NULL,
    observacoes text,
    usuario character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 286
-- Name: TABLE faturas_entrada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.faturas_entrada IS 'Registro de faturas de compra de fornecedores';


--
-- Dependencies: 286
-- Name: COLUMN faturas_entrada.fornecedor_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas_entrada.fornecedor_id IS 'Fornecedor da fatura';


--
-- Dependencies: 286
-- Name: COLUMN faturas_entrada.numero_fatura; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas_entrada.numero_fatura IS 'Número da fatura do fornecedor';


--
-- Dependencies: 286
-- Name: COLUMN faturas_entrada.data_fatura; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas_entrada.data_fatura IS 'Data de emissão da fatura';


--
-- Dependencies: 286
-- Name: COLUMN faturas_entrada.total; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.faturas_entrada.total IS 'Valor total da fatura';


--
-- Name: faturas_entrada_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.faturas_entrada_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 285
-- Name: faturas_entrada_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.faturas_entrada_id_seq OWNED BY public.faturas_entrada.id;


--
-- Name: formas_pagamento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.formas_pagamento (
    id integer NOT NULL,
    nome character varying(50) NOT NULL,
    descricao character varying(200),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: formas_pagamento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.formas_pagamento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 230
-- Name: formas_pagamento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.formas_pagamento_id_seq OWNED BY public.formas_pagamento.id;


--
-- Name: fornecedores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fornecedores (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    nif character varying(20),
    email character varying(100),
    telefone character varying(20),
    morada text,
    cidade character varying(100),
    codigo_postal character varying(20),
    pais character varying(100) DEFAULT 'Portugal'::character varying,
    contacto character varying(200),
    observacoes text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 284
-- Name: TABLE fornecedores; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.fornecedores IS 'Cadastro de fornecedores';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.nome IS 'Nome do fornecedor';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.nif; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.nif IS 'Número de Identificação Fiscal';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.email; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.email IS 'Email de contacto';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.telefone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.telefone IS 'Telefone de contacto';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.morada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.morada IS 'Morada completa';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.cidade; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.cidade IS 'Cidade';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.codigo_postal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.codigo_postal IS 'Código postal';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.pais; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.pais IS 'País';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.contacto; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.contacto IS 'Nome da pessoa de contacto';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.observacoes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.observacoes IS 'Observações gerais';


--
-- Dependencies: 284
-- Name: COLUMN fornecedores.ativo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.fornecedores.ativo IS 'Indica se o fornecedor está ativo';


--
-- Name: fornecedores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fornecedores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 283
-- Name: fornecedores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fornecedores_id_seq OWNED BY public.fornecedores.id;


--
-- Name: impressoras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impressoras (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    tipo character varying(50) DEFAULT 'termica'::character varying,
    descricao text,
    largura_papel integer DEFAULT 80,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    caminho_rede character varying(255)
);


--
-- Dependencies: 324
-- Name: TABLE impressoras; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.impressoras IS 'Cadastro de impressoras do sistema';


--
-- Dependencies: 324
-- Name: COLUMN impressoras.caminho_rede; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.impressoras.caminho_rede IS 'Caminho de rede para impressora compartilhada (ex: \\ComputadorX\ImpressoraCozinha)';


--
-- Name: impressoras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impressoras_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 323
-- Name: impressoras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impressoras_id_seq OWNED BY public.impressoras.id;


--
-- Name: itens_fatura_entrada; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itens_fatura_entrada (
    id integer NOT NULL,
    fatura_id integer NOT NULL,
    produto_id integer NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT itens_fatura_entrada_preco_unitario_check CHECK ((preco_unitario >= (0)::numeric)),
    CONSTRAINT itens_fatura_entrada_quantidade_check CHECK ((quantidade > 0)),
    CONSTRAINT itens_fatura_entrada_subtotal_check CHECK ((subtotal >= (0)::numeric))
);


--
-- Dependencies: 288
-- Name: TABLE itens_fatura_entrada; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.itens_fatura_entrada IS 'Itens de cada fatura de compra';


--
-- Dependencies: 288
-- Name: COLUMN itens_fatura_entrada.quantidade; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.itens_fatura_entrada.quantidade IS 'Quantidade comprada';


--
-- Dependencies: 288
-- Name: COLUMN itens_fatura_entrada.preco_unitario; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.itens_fatura_entrada.preco_unitario IS 'Preço de compra unitário';


--
-- Dependencies: 288
-- Name: COLUMN itens_fatura_entrada.subtotal; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.itens_fatura_entrada.subtotal IS 'Subtotal do item (quantidade × preço)';


--
-- Name: itens_fatura_entrada_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.itens_fatura_entrada_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 287
-- Name: itens_fatura_entrada_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.itens_fatura_entrada_id_seq OWNED BY public.itens_fatura_entrada.id;


--
-- Name: itens_pedido; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itens_pedido (
    id integer NOT NULL,
    pedido_id integer NOT NULL,
    produto_id integer NOT NULL,
    produto_nome character varying(200) NOT NULL,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    observacoes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 314
-- Name: TABLE itens_pedido; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.itens_pedido IS 'Itens de cada pedido';


--
-- Name: itens_pedido_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.itens_pedido_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 313
-- Name: itens_pedido_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.itens_pedido_id_seq OWNED BY public.itens_pedido.id;


--
-- Name: itens_venda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.itens_venda (
    id integer NOT NULL,
    venda_id integer,
    produto_id integer,
    quantidade integer NOT NULL,
    preco_unitario numeric(10,2) NOT NULL,
    subtotal numeric(10,2) NOT NULL
);


--
-- Name: itens_venda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.itens_venda_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 225
-- Name: itens_venda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.itens_venda_id_seq OWNED BY public.itens_venda.id;


--
-- Name: locais_mesa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.locais_mesa (
    id integer NOT NULL,
    nome character varying(50) NOT NULL,
    descricao text,
    ordem integer DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 308
-- Name: TABLE locais_mesa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.locais_mesa IS 'Locais onde as mesas estão localizadas (BALCAO, SALA, ESPLANADA)';


--
-- Name: locais_mesa_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.locais_mesa_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 307
-- Name: locais_mesa_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.locais_mesa_id_seq OWNED BY public.locais_mesa.id;


--
-- Name: logs_acesso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs_acesso (
    id integer NOT NULL,
    usuario_id integer,
    terminal_nome character varying(100),
    ip_address character varying(50),
    tipo character varying(20) NOT NULL,
    sucesso boolean DEFAULT true,
    motivo_falha text,
    data_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 346
-- Name: TABLE logs_acesso; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.logs_acesso IS 'Registro de logins, logouts e tentativas falhadas';


--
-- Name: logs_acesso_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_acesso_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 345
-- Name: logs_acesso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_acesso_id_seq OWNED BY public.logs_acesso.id;


--
-- Name: mesas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mesas (
    id integer NOT NULL,
    numero integer NOT NULL,
    local_id integer NOT NULL,
    capacidade integer DEFAULT 4,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 310
-- Name: TABLE mesas; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.mesas IS 'Mesas do restaurante';


--
-- Name: mesas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mesas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 309
-- Name: mesas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mesas_id_seq OWNED BY public.mesas.id;


--
-- Name: pagamentos_divida; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagamentos_divida (
    id integer NOT NULL,
    divida_id integer NOT NULL,
    valor numeric(10,2) NOT NULL,
    forma_pagamento_id integer,
    data_pagamento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    observacoes text,
    usuario character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 247
-- Name: TABLE pagamentos_divida; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pagamentos_divida IS 'Histórico de pagamentos de dívidas';


--
-- Name: pagamentos_divida_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagamentos_divida_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 246
-- Name: pagamentos_divida_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagamentos_divida_id_seq OWNED BY public.pagamentos_divida.id;


--
-- Name: pagamentos_venda; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pagamentos_venda (
    id integer NOT NULL,
    venda_id integer NOT NULL,
    forma_pagamento_id integer NOT NULL,
    valor numeric(10,2) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pagamentos_venda_valor_positivo CHECK ((valor > (0)::numeric))
);


--
-- Dependencies: 240
-- Name: TABLE pagamentos_venda; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pagamentos_venda IS 'Armazena os pagamentos de cada venda (permite múltiplas formas de pagamento)';


--
-- Dependencies: 240
-- Name: COLUMN pagamentos_venda.venda_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagamentos_venda.venda_id IS 'ID da venda';


--
-- Dependencies: 240
-- Name: COLUMN pagamentos_venda.forma_pagamento_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagamentos_venda.forma_pagamento_id IS 'ID da forma de pagamento utilizada';


--
-- Dependencies: 240
-- Name: COLUMN pagamentos_venda.valor; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pagamentos_venda.valor IS 'Valor pago com esta forma de pagamento';


--
-- Name: pagamentos_venda_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pagamentos_venda_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 239
-- Name: pagamentos_venda_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pagamentos_venda_id_seq OWNED BY public.pagamentos_venda.id;


--
-- Name: pedidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pedidos (
    id integer NOT NULL,
    numero character varying(50) NOT NULL,
    mesa_id integer NOT NULL,
    usuario_id integer NOT NULL,
    status character varying(20) DEFAULT 'aberto'::character varying,
    total numeric(10,2) DEFAULT 0,
    data_abertura timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_fechamento timestamp without time zone,
    observacoes text,
    CONSTRAINT check_status CHECK (((status)::text = ANY ((ARRAY['aberto'::character varying, 'fechado'::character varying, 'cancelado'::character varying])::text[])))
);


--
-- Dependencies: 312
-- Name: TABLE pedidos; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.pedidos IS 'Pedidos realizados nas mesas';


--
-- Dependencies: 312
-- Name: COLUMN pedidos.usuario_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pedidos.usuario_id IS 'Usuário responsável pelo pedido';


--
-- Dependencies: 312
-- Name: COLUMN pedidos.status; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.pedidos.status IS 'Status: aberto, fechado, cancelado';


--
-- Name: pedidos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pedidos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 311
-- Name: pedidos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pedidos_id_seq OWNED BY public.pedidos.id;


--
-- Name: perfil_permissoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfil_permissoes (
    id integer NOT NULL,
    perfil_id integer NOT NULL,
    permissao_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 301
-- Name: TABLE perfil_permissoes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.perfil_permissoes IS 'Permissões atribuídas a cada perfil de usuário';


--
-- Name: perfil_permissoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfil_permissoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 300
-- Name: perfil_permissoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfil_permissoes_id_seq OWNED BY public.perfil_permissoes.id;


--
-- Name: perfis_usuario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.perfis_usuario (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 294
-- Name: TABLE perfis_usuario; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.perfis_usuario IS 'Perfis/categorias de usuários do sistema';


--
-- Name: perfis_usuario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.perfis_usuario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 293
-- Name: perfis_usuario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.perfis_usuario_id_seq OWNED BY public.perfis_usuario.id;


--
-- Name: permissoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissoes (
    id integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(200) NOT NULL,
    descricao text,
    categoria character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 299
-- Name: TABLE permissoes; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.permissoes IS 'Operações/permissões disponíveis no sistema';


--
-- Dependencies: 299
-- Name: COLUMN permissoes.codigo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.permissoes.codigo IS 'Código único da permissão usado no código';


--
-- Dependencies: 299
-- Name: COLUMN permissoes.categoria; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.permissoes.categoria IS 'Categoria da permissão (VENDAS, STOCK, ADMIN, etc)';


--
-- Name: permissoes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 298
-- Name: permissoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissoes_id_seq OWNED BY public.permissoes.id;


--
-- Name: produto_composicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produto_composicao (
    id integer NOT NULL,
    produto_id integer NOT NULL,
    produto_componente_id integer NOT NULL,
    quantidade numeric(10,2) DEFAULT 1 NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT produto_composicao_check CHECK ((produto_id <> produto_componente_id))
);


--
-- Dependencies: 267
-- Name: TABLE produto_composicao; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.produto_composicao IS 'Composição de produtos - produtos que são formados por outros produtos';


--
-- Dependencies: 267
-- Name: COLUMN produto_composicao.produto_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.produto_composicao.produto_id IS 'Produto principal (ex: CAIXA)';


--
-- Dependencies: 267
-- Name: COLUMN produto_composicao.produto_componente_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.produto_composicao.produto_componente_id IS 'Produto componente (ex: MEIA CAIXA)';


--
-- Dependencies: 267
-- Name: COLUMN produto_composicao.quantidade; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.produto_composicao.quantidade IS 'Quantidade do componente necessária (ex: 2)';


--
-- Name: produto_composicao_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produto_composicao_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 266
-- Name: produto_composicao_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.produto_composicao_id_seq OWNED BY public.produto_composicao.id;


--
-- Name: produtos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.produtos (
    id integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(200) NOT NULL,
    familia_id integer,
    preco numeric(10,2) NOT NULL,
    estoque integer DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    setor_id integer,
    area_id integer,
    preco_compra numeric(10,2) DEFAULT 0 NOT NULL,
    contavel boolean DEFAULT true NOT NULL,
    iva character varying(20) DEFAULT 'Incluso'::character varying NOT NULL,
    codigo_barras character varying(50),
    estoque_minimo integer DEFAULT 0
);


--
-- Dependencies: 222
-- Name: COLUMN produtos.codigo_barras; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.produtos.codigo_barras IS 'Código de barras do produto (EAN-13, EAN-8, UPC-A, UPC-E)';


--
-- Dependencies: 222
-- Name: COLUMN produtos.estoque_minimo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.produtos.estoque_minimo IS 'Quantidade mínima de estoque antes de alertar';


--
-- Name: produtos_codigo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produtos_codigo_seq
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: produtos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.produtos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 221
-- Name: produtos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.produtos_id_seq OWNED BY public.produtos.id;


--
-- Name: servidor_tempo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servidor_tempo (
    id integer NOT NULL,
    ultima_data_sistema timestamp without time zone NOT NULL,
    ultima_data_servidor timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 339
-- Name: TABLE servidor_tempo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.servidor_tempo IS 'Registro de timestamps do servidor PostgreSQL para detectar alteração de data do sistema';


--
-- Name: servidor_tempo_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.servidor_tempo_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 338
-- Name: servidor_tempo_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.servidor_tempo_id_seq OWNED BY public.servidor_tempo.id;


--
-- Name: setores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.setores (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: setores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.setores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 232
-- Name: setores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.setores_id_seq OWNED BY public.setores.id;


--
-- Name: terminais; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terminais (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    ip_address character varying(45),
    descricao text,
    tipo character varying(50) DEFAULT 'caixa'::character varying,
    ativo boolean DEFAULT true,
    ultima_conexao timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: terminais_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terminais_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 331
-- Name: terminais_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terminais_id_seq OWNED BY public.terminais.id;


--
-- Name: terminal_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.terminal_logs (
    id integer NOT NULL,
    terminal_id integer,
    usuario_id integer,
    ip_address character varying(45),
    acao character varying(50),
    detalhes text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: terminal_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.terminal_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 333
-- Name: terminal_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.terminal_logs_id_seq OWNED BY public.terminal_logs.id;


--
-- Name: tipos_documento; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_documento (
    id integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Dependencies: 326
-- Name: TABLE tipos_documento; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.tipos_documento IS 'Tipos de documentos que podem ser impressos';


--
-- Name: tipos_documento_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_documento_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 325
-- Name: tipos_documento_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_documento_id_seq OWNED BY public.tipos_documento.id;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    perfil_id integer NOT NULL,
    codigo character varying(8) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    terminal_id_atual integer
);


--
-- Dependencies: 296
-- Name: TABLE usuarios; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.usuarios IS 'Usuários do sistema';


--
-- Dependencies: 296
-- Name: COLUMN usuarios.nome; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usuarios.nome IS 'Nome do usuário (deve ser único)';


--
-- Dependencies: 296
-- Name: COLUMN usuarios.perfil_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usuarios.perfil_id IS 'Perfil/categoria do usuário';


--
-- Dependencies: 296
-- Name: COLUMN usuarios.codigo; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.usuarios.codigo IS 'Código numérico de 1 a 8 dígitos para login (pode ser repetido entre usuários)';


--
-- Name: usuarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.usuarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 295
-- Name: usuarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.usuarios_id_seq OWNED BY public.usuarios.id;


--
-- Name: v_acertos_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acertos_completo AS
 SELECT a.id,
    a.produto_id,
    p.codigo AS produto_codigo,
    p.nome AS produto_nome,
    p.preco AS produto_preco,
    a.estoque_anterior,
    a.estoque_novo,
    a.diferenca,
    a.motivo,
    a.observacao,
    a.setor_id,
    s.nome AS setor_nome,
    a.area_id,
    ar.nome AS area_nome,
    f.id AS familia_id,
    f.nome AS familia_nome,
    a.usuario,
    a.data,
    a.created_at,
    a.updated_at,
    ((a.diferenca)::numeric * p.preco) AS valor_diferenca
   FROM ((((public.acertos_stock a
     JOIN public.produtos p ON ((a.produto_id = p.id)))
     LEFT JOIN public.setores s ON ((a.setor_id = s.id)))
     LEFT JOIN public.areas ar ON ((a.area_id = ar.id)))
     LEFT JOIN public.familias f ON ((p.familia_id = f.id)))
  ORDER BY a.data DESC;


--
-- Name: v_acertos_por_motivo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acertos_por_motivo AS
 SELECT a.motivo,
    count(*) AS total_acertos,
    sum(abs(a.diferenca)) AS total_diferencas,
    sum(((a.diferenca)::numeric * p.preco)) AS valor_total_diferenca
   FROM (public.acertos_stock a
     JOIN public.produtos p ON ((a.produto_id = p.id)))
  GROUP BY a.motivo
  ORDER BY (count(*)) DESC;


--
-- Name: v_acertos_por_setor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acertos_por_setor AS
 SELECT s.id AS setor_id,
    s.nome AS setor_nome,
    count(a.id) AS total_acertos,
    sum(abs(a.diferenca)) AS total_diferencas,
    sum(((a.diferenca)::numeric * p.preco)) AS valor_total_diferenca
   FROM ((public.setores s
     LEFT JOIN public.acertos_stock a ON ((s.id = a.setor_id)))
     LEFT JOIN public.produtos p ON ((a.produto_id = p.id)))
  GROUP BY s.id, s.nome
  ORDER BY s.nome;


--
-- Name: v_acertos_resumo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acertos_resumo AS
 SELECT date(a.data) AS data_acerto,
    count(*) AS total_acertos,
    sum(
        CASE
            WHEN (a.diferenca > 0) THEN 1
            ELSE 0
        END) AS acertos_positivos,
    sum(
        CASE
            WHEN (a.diferenca < 0) THEN 1
            ELSE 0
        END) AS acertos_negativos,
    sum(abs(a.diferenca)) AS total_diferencas,
    sum(((a.diferenca)::numeric * p.preco)) AS valor_total_diferenca
   FROM (public.acertos_stock a
     JOIN public.produtos p ON ((a.produto_id = p.id)))
  GROUP BY (date(a.data))
  ORDER BY (date(a.data)) DESC;


--
-- Name: v_areas_ativas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_areas_ativas AS
 SELECT id,
    nome,
    descricao,
    ativo,
    created_at
   FROM public.areas
  WHERE (ativo = true)
  ORDER BY nome;


--
-- Name: v_caixa_atual; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_caixa_atual AS
 SELECT id,
    numero,
    terminal,
    usuario,
    data_abertura,
    data_fechamento,
    status,
    total_vendas_pagas,
    qtd_vendas_pagas,
    total_cash,
    qtd_transacoes_cash,
    total_emola,
    qtd_transacoes_emola,
    total_mpesa,
    qtd_transacoes_mpesa,
    total_pos,
    qtd_transacoes_pos,
    total_vendas_credito,
    qtd_vendas_credito,
    total_dividas_pagas,
    qtd_dividas_pagas,
    total_despesas,
    qtd_despesas,
    total_entradas,
    total_saidas,
    saldo_final,
    observacoes,
    created_at,
    (((total_cash + total_emola) + total_mpesa) + total_pos) AS soma_formas_validacao,
        CASE
            WHEN (abs(((((total_cash + total_emola) + total_mpesa) + total_pos) - total_entradas)) < 0.01) THEN 'OK'::text
            ELSE 'ERRO: Totais não batem!'::text
        END AS status_validacao,
        CASE
            WHEN (abs(((((total_cash + total_emola) + total_mpesa) + total_pos) - total_entradas)) < 0.01) THEN true
            ELSE false
        END AS totais_corretos
   FROM public.caixas c
  WHERE ((status)::text = 'ABERTO'::text)
  ORDER BY data_abertura DESC
 LIMIT 1;


--
-- Dependencies: 275
-- Name: VIEW v_caixa_atual; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_caixa_atual IS 'Retorna o caixa atualmente aberto com validação de totais';


--
-- Name: v_cancelamentos_pedido; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_cancelamentos_pedido AS
 SELECT c.id,
    c.pedido_id,
    p.numero AS pedido_numero,
    p.mesa_id,
    m.numero AS mesa_numero,
    c.produto_nome,
    c.quantidade,
    c.preco_unitario,
    c.subtotal,
    c.usuario_nome,
    c.justificativa,
    c.data_cancelamento
   FROM ((public.cancelamentos_item_pedido c
     JOIN public.pedidos p ON ((c.pedido_id = p.id)))
     JOIN public.mesas m ON ((p.mesa_id = m.id)))
  ORDER BY c.data_cancelamento DESC;


--
-- Name: v_clientes_dividas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_clientes_dividas AS
 SELECT c.id,
    c.nome,
    c.contacto,
    c.email,
    count(d.id) AS total_dividas,
    sum(d.valor_restante) AS total_devendo,
    max(d.data_divida) AS ultima_divida
   FROM (public.clientes c
     LEFT JOIN public.dividas d ON (((c.id = d.cliente_id) AND ((d.status)::text <> 'PAGO'::text))))
  GROUP BY c.id, c.nome, c.contacto, c.email;


--
-- Name: v_conferencias_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_conferencias_caixa AS
 SELECT cc.id,
    cc.caixa_id,
    cc.sistema_cash,
    cc.sistema_emola,
    cc.sistema_mpesa,
    cc.sistema_pos,
    cc.sistema_total,
    cc.contado_cash,
    cc.contado_emola,
    cc.contado_mpesa,
    cc.contado_pos,
    cc.contado_total,
    cc.diferenca_cash,
    cc.diferenca_emola,
    cc.diferenca_mpesa,
    cc.diferenca_pos,
    cc.diferenca_total,
    cc.conferencia_ok,
    cc.observacoes,
    cc.created_at,
    c.numero AS caixa_numero,
    c.status AS caixa_status,
    c.data_abertura,
    c.data_fechamento
   FROM (public.conferencias_caixa cc
     JOIN public.caixas c ON ((cc.caixa_id = c.id)))
  ORDER BY cc.created_at DESC;


--
-- Dependencies: 258
-- Name: VIEW v_conferencias_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_conferencias_caixa IS 'Lista de conferências com dados do caixa';


--
-- Name: v_despesas_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_despesas_caixa AS
 SELECT c.id AS caixa_id,
    c.numero AS caixa_numero,
    d.id AS despesa_id,
    d.descricao,
    d.valor,
    d.categoria,
    d.data_despesa,
    d.observacoes,
    d.usuario
   FROM (public.caixas c
     CROSS JOIN public.despesas d)
  WHERE ((d.data_despesa >= c.data_abertura) AND (d.data_despesa <= COALESCE((c.data_fechamento)::timestamp with time zone, now())))
  ORDER BY d.data_despesa DESC;


--
-- Dependencies: 271
-- Name: VIEW v_despesas_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_despesas_caixa IS 'Lista detalhada de despesas por caixa com categoria';


--
-- Name: v_despesas_resumo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_despesas_resumo AS
 SELECT categoria,
    count(*) AS total_despesas,
    sum(valor) AS total_valor,
    date(data_despesa) AS data
   FROM public.despesas
  GROUP BY categoria, (date(data_despesa))
  ORDER BY (date(data_despesa)) DESC;


--
-- Name: v_devedores; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_devedores AS
 SELECT c.id,
    c.nome,
    c.contacto,
    c.email,
    count(DISTINCT d.id) AS qtd_dividas,
    sum(d.valor_restante) AS total_devendo,
    min(d.data_divida) AS divida_mais_antiga,
    max(d.data_divida) AS divida_mais_recente
   FROM (public.clientes c
     JOIN public.dividas d ON ((c.id = d.cliente_id)))
  WHERE ((d.status)::text <> 'PAGO'::text)
  GROUP BY c.id, c.nome, c.contacto, c.email
 HAVING (sum(d.valor_restante) > (0)::numeric)
  ORDER BY (sum(d.valor_restante)) DESC;


--
-- Name: vendas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vendas (
    id integer NOT NULL,
    numero character varying(50) NOT NULL,
    total numeric(10,2) NOT NULL,
    data_venda timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    terminal character varying(50),
    forma_pagamento_id integer,
    cliente_id integer,
    tipo_venda character varying(20) DEFAULT 'NORMAL'::character varying,
    terminal_id integer,
    status character varying(20) DEFAULT 'finalizada'::character varying,
    usuario_id integer,
    observacoes text,
    CONSTRAINT chk_vendas_status CHECK (((status)::text = ANY ((ARRAY['finalizada'::character varying, 'cancelada'::character varying])::text[])))
);


--
-- Dependencies: 224
-- Name: COLUMN vendas.tipo_venda; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.vendas.tipo_venda IS 'NORMAL: Venda comum, DIVIDA: Venda a crédito';


--
-- Name: v_dividas_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_dividas_completo AS
 SELECT d.id,
    d.cliente_id,
    d.venda_id,
    d.valor_total,
    d.valor_pago,
    d.valor_restante,
    d.status,
    d.observacoes,
    d.data_divida,
    d.data_vencimento,
    d.created_at,
    c.nome AS cliente_nome,
    c.contacto AS cliente_contacto,
    v.numero AS venda_numero,
    v.data_venda
   FROM ((public.dividas d
     JOIN public.clientes c ON ((d.cliente_id = c.id)))
     LEFT JOIN public.vendas v ON ((d.venda_id = v.id)));


--
-- Name: v_familias_areas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_familias_areas AS
 SELECT f.id AS familia_id,
    f.nome AS familia_nome,
    f.descricao,
    f.ativo,
    array_agg(fa.area_id) AS area_ids,
    string_agg((a.nome)::text, ', '::text ORDER BY (a.nome)::text) AS areas_nomes
   FROM ((public.familias f
     LEFT JOIN public.familia_areas fa ON ((f.id = fa.familia_id)))
     LEFT JOIN public.areas a ON ((fa.area_id = a.id)))
  GROUP BY f.id, f.nome, f.descricao, f.ativo;


--
-- Name: v_familias_com_setores; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_familias_com_setores AS
 SELECT f.id,
    f.nome,
    f.descricao,
    f.ativo,
    f.created_at,
    COALESCE(array_agg(DISTINCT fs.setor_id) FILTER (WHERE (fs.setor_id IS NOT NULL)), ARRAY[]::integer[]) AS setor_ids,
    COALESCE(array_agg(DISTINCT s.nome) FILTER (WHERE (s.nome IS NOT NULL)), (ARRAY[]::text[])::character varying[]) AS setor_nomes,
    string_agg(DISTINCT (s.nome)::text, ', '::text ORDER BY (s.nome)::text) AS setores_texto,
    COALESCE(array_agg(DISTINCT fa.area_id) FILTER (WHERE (fa.area_id IS NOT NULL)), ARRAY[]::integer[]) AS area_ids,
    COALESCE(array_agg(DISTINCT a.nome) FILTER (WHERE (a.nome IS NOT NULL)), (ARRAY[]::text[])::character varying[]) AS area_nomes,
    string_agg(DISTINCT (a.nome)::text, ', '::text ORDER BY (a.nome)::text) AS areas_texto
   FROM ((((public.familias f
     LEFT JOIN public.familia_setores fs ON ((f.id = fs.familia_id)))
     LEFT JOIN public.setores s ON ((fs.setor_id = s.id)))
     LEFT JOIN public.familia_areas fa ON ((f.id = fa.familia_id)))
     LEFT JOIN public.areas a ON ((fa.area_id = a.id)))
  GROUP BY f.id, f.nome, f.descricao, f.ativo, f.created_at;


--
-- Name: v_faturas_entrada_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_faturas_entrada_completo AS
 SELECT f.id,
    f.fornecedor_id,
    fo.nome AS fornecedor_nome,
    fo.nif AS fornecedor_nif,
    f.numero_fatura,
    f.data_fatura,
    f.total,
    f.observacoes,
    f.usuario,
    f.created_at,
    f.updated_at,
    ( SELECT count(*) AS count
           FROM public.itens_fatura_entrada
          WHERE (itens_fatura_entrada.fatura_id = f.id)) AS total_itens
   FROM (public.faturas_entrada f
     JOIN public.fornecedores fo ON ((f.fornecedor_id = fo.id)))
  ORDER BY f.data_fatura DESC, f.created_at DESC;


--
-- Name: v_itens_fatura_entrada_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_itens_fatura_entrada_completo AS
 SELECT i.id,
    i.fatura_id,
    i.produto_id,
    p.codigo AS produto_codigo,
    p.nome AS produto_nome,
    i.quantidade,
    i.preco_unitario,
    i.subtotal,
    f.numero_fatura,
    f.data_fatura,
    fo.nome AS fornecedor_nome
   FROM (((public.itens_fatura_entrada i
     JOIN public.produtos p ON ((i.produto_id = p.id)))
     JOIN public.faturas_entrada f ON ((i.fatura_id = f.id)))
     JOIN public.fornecedores fo ON ((f.fornecedor_id = fo.id)));


--
-- Name: v_mesas_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_mesas_completo AS
 SELECT m.id,
    m.numero,
    m.local_id,
    l.nome AS local_nome,
    m.capacidade,
    m.ativo,
    p.id AS pedido_id,
    p.numero AS pedido_numero,
    p.usuario_id,
    u.nome AS usuario_nome,
    p.total AS pedido_total,
    p.data_abertura,
        CASE
            WHEN (p.id IS NOT NULL) THEN 'ocupada'::text
            WHEN (m.ativo = false) THEN 'inativa'::text
            ELSE 'livre'::text
        END AS status
   FROM (((public.mesas m
     LEFT JOIN public.locais_mesa l ON ((m.local_id = l.id)))
     LEFT JOIN public.pedidos p ON (((m.id = p.mesa_id) AND ((p.status)::text = 'aberto'::text))))
     LEFT JOIN public.usuarios u ON ((p.usuario_id = u.id)))
  ORDER BY m.numero;


--
-- Name: v_mesas_por_local; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_mesas_por_local AS
SELECT
    NULL::integer AS local_id,
    NULL::character varying(50) AS local_nome,
    NULL::bigint AS total_mesas,
    NULL::bigint AS mesas_ativas,
    NULL::bigint AS mesas_ocupadas,
    NULL::bigint AS mesas_livres;


--
-- Name: v_pagamentos_divida_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pagamentos_divida_caixa AS
 SELECT c.id AS caixa_id,
    c.numero AS caixa_numero,
    pd.id AS pagamento_id,
    pd.divida_id,
    pd.valor,
    pd.data_pagamento,
    pd.observacoes,
    fp.nome AS forma_pagamento,
    cli.nome AS cliente_nome,
    cli.contacto AS cliente_contacto,
    d.valor_total AS divida_total,
    d.valor_pago AS divida_pago,
    d.valor_restante AS divida_restante
   FROM ((((public.caixas c
     CROSS JOIN public.pagamentos_divida pd)
     JOIN public.formas_pagamento fp ON ((pd.forma_pagamento_id = fp.id)))
     JOIN public.dividas d ON ((pd.divida_id = d.id)))
     JOIN public.clientes cli ON ((d.cliente_id = cli.id)))
  WHERE ((pd.data_pagamento >= c.data_abertura) AND (pd.data_pagamento <= COALESCE((c.data_fechamento)::timestamp with time zone, now())))
  ORDER BY pd.data_pagamento DESC;


--
-- Dependencies: 272
-- Name: VIEW v_pagamentos_divida_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_pagamentos_divida_caixa IS 'Lista detalhada de pagamentos de dívidas por caixa com dados do cliente';


--
-- Name: v_pedidos_abertos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_pedidos_abertos AS
 SELECT p.id,
    p.numero,
    p.mesa_id,
    m.numero AS mesa_numero,
    l.nome AS local_nome,
    p.usuario_id,
    u.nome AS usuario_nome,
    p.total,
    p.data_abertura,
    p.observacoes,
    count(ip.id) AS total_itens
   FROM ((((public.pedidos p
     JOIN public.mesas m ON ((p.mesa_id = m.id)))
     JOIN public.locais_mesa l ON ((m.local_id = l.id)))
     JOIN public.usuarios u ON ((p.usuario_id = u.id)))
     LEFT JOIN public.itens_pedido ip ON ((p.id = ip.pedido_id)))
  WHERE ((p.status)::text = 'aberto'::text)
  GROUP BY p.id, p.numero, p.mesa_id, m.numero, l.nome, p.usuario_id, u.nome, p.total, p.data_abertura, p.observacoes
  ORDER BY p.data_abertura DESC;


--
-- Name: v_perfil_permissoes; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_perfil_permissoes AS
 SELECT p.id AS perfil_id,
    p.nome AS perfil_nome,
    perm.id AS permissao_id,
    perm.codigo AS permissao_codigo,
    perm.nome AS permissao_nome,
    perm.categoria AS permissao_categoria,
        CASE
            WHEN (pp.id IS NOT NULL) THEN true
            ELSE false
        END AS tem_permissao
   FROM ((public.perfis_usuario p
     CROSS JOIN public.permissoes perm)
     LEFT JOIN public.perfil_permissoes pp ON (((pp.perfil_id = p.id) AND (pp.permissao_id = perm.id))))
  WHERE ((p.ativo = true) AND (perm.ativo = true))
  ORDER BY p.nome, perm.categoria, perm.nome;


--
-- Name: v_produtos_com_composicao; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_com_composicao AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.contavel,
    pc.produto_componente_id,
    comp.codigo AS componente_codigo,
    comp.nome AS componente_nome,
    pc.quantidade AS componente_quantidade,
    comp.estoque AS componente_estoque
   FROM ((public.produtos p
     JOIN public.produto_composicao pc ON ((p.id = pc.produto_id)))
     JOIN public.produtos comp ON ((pc.produto_componente_id = comp.id)))
  WHERE ((p.ativo = true) AND (comp.ativo = true))
  ORDER BY p.nome, comp.nome;


--
-- Name: v_produtos_com_setores; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_com_setores AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    p.preco,
    p.estoque,
    p.ativo,
    f.nome AS familia_nome,
    string_agg(DISTINCT (s.nome)::text, ', '::text ORDER BY (s.nome)::text) AS setores
   FROM (((public.produtos p
     LEFT JOIN public.familias f ON ((p.familia_id = f.id)))
     LEFT JOIN public.familia_setores fs ON ((f.id = fs.familia_id)))
     LEFT JOIN public.setores s ON (((fs.setor_id = s.id) AND (s.ativo = true))))
  WHERE (p.ativo = true)
  GROUP BY p.id, p.codigo, p.nome, p.familia_id, p.preco, p.estoque, p.ativo, f.nome
  ORDER BY p.nome;


--
-- Name: v_produtos_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_completo AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.familia_id,
    p.preco,
    p.preco_compra,
    p.estoque,
    p.ativo,
    p.contavel,
    p.iva,
    p.created_at,
    p.updated_at,
    p.setor_id,
    p.area_id,
    f.nome AS familia_nome,
    s.nome AS setor_nome,
    a.nome AS area_nome,
        CASE
            WHEN (p.preco_compra > (0)::numeric) THEN round((((p.preco - p.preco_compra) / p.preco_compra) * (100)::numeric), 2)
            ELSE (0)::numeric
        END AS margem_lucro_percentual,
    (EXISTS ( SELECT 1
           FROM public.produto_composicao pc
          WHERE (pc.produto_id = p.id))) AS tem_composicao
   FROM (((public.produtos p
     LEFT JOIN public.familias f ON ((p.familia_id = f.id)))
     LEFT JOIN public.setores s ON ((p.setor_id = s.id)))
     LEFT JOIN public.areas a ON ((p.area_id = a.id)));


--
-- Name: v_produtos_detalhado; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_detalhado AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.preco,
    p.estoque,
    p.ativo,
    f.nome AS familia,
    s.nome AS setor,
    a.nome AS area,
    p.created_at,
    p.updated_at
   FROM (((public.produtos p
     LEFT JOIN public.familias f ON ((p.familia_id = f.id)))
     LEFT JOIN public.setores s ON ((p.setor_id = s.id)))
     LEFT JOIN public.areas a ON ((p.area_id = a.id)))
  WHERE (p.ativo = true)
  ORDER BY p.nome;


--
-- Name: v_produtos_mais_comprados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_mais_comprados AS
 SELECT p.id AS produto_id,
    p.codigo AS produto_codigo,
    p.nome AS produto_nome,
    count(DISTINCT i.fatura_id) AS total_faturas,
    sum(i.quantidade) AS quantidade_total_comprada,
    avg(i.preco_unitario) AS preco_medio_compra,
    sum(i.subtotal) AS total_gasto
   FROM (public.produtos p
     LEFT JOIN public.itens_fatura_entrada i ON ((p.id = i.produto_id)))
  WHERE (p.ativo = true)
  GROUP BY p.id, p.codigo, p.nome
 HAVING (sum(i.quantidade) > 0)
  ORDER BY (sum(i.quantidade)) DESC;


--
-- Name: v_produtos_nao_contaveis; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_nao_contaveis AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.preco,
    count(pc.id) AS total_componentes
   FROM (public.produtos p
     LEFT JOIN public.produto_composicao pc ON ((p.id = pc.produto_id)))
  WHERE ((p.contavel = false) AND (p.ativo = true))
  GROUP BY p.id, p.codigo, p.nome, p.preco
  ORDER BY p.nome;


--
-- Name: v_produtos_por_area; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_por_area AS
 SELECT a.id AS area_id,
    a.nome AS area_nome,
    count(p.id) AS total_produtos,
    sum(p.estoque) AS total_estoque,
    sum((p.preco * (p.estoque)::numeric)) AS valor_total_estoque
   FROM (public.areas a
     LEFT JOIN public.produtos p ON (((a.id = p.area_id) AND (p.ativo = true))))
  GROUP BY a.id, a.nome
  ORDER BY a.nome;


--
-- Name: v_produtos_por_setor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_por_setor AS
 SELECT s.id AS setor_id,
    s.nome AS setor_nome,
    count(p.id) AS total_produtos,
    sum(p.estoque) AS total_estoque,
    sum((p.preco * (p.estoque)::numeric)) AS valor_total_estoque
   FROM (public.setores s
     LEFT JOIN public.produtos p ON (((s.id = p.setor_id) AND (p.ativo = true))))
  GROUP BY s.id, s.nome
  ORDER BY s.nome;


--
-- Name: v_produtos_vendidos_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_produtos_vendidos_caixa AS
 SELECT c.id AS caixa_id,
    c.numero AS caixa_numero,
    v.id AS venda_id,
    v.numero AS venda_numero,
    v.data_venda,
    v.total AS venda_total,
    p.id AS produto_id,
    p.nome AS produto_nome,
    iv.quantidade,
    iv.preco_unitario,
    iv.subtotal,
    ((iv.quantidade)::numeric * iv.preco_unitario) AS total_vendido
   FROM (((public.caixas c
     CROSS JOIN public.vendas v)
     JOIN public.itens_venda iv ON ((v.id = iv.venda_id)))
     JOIN public.produtos p ON ((iv.produto_id = p.id)))
  WHERE ((v.data_venda >= c.data_abertura) AND (v.data_venda <= COALESCE((c.data_fechamento)::timestamp with time zone, now())) AND (((v.tipo_venda)::text = 'NORMAL'::text) OR (v.tipo_venda IS NULL)))
  ORDER BY v.data_venda DESC, p.nome;


--
-- Dependencies: 273
-- Name: VIEW v_produtos_vendidos_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_produtos_vendidos_caixa IS 'Lista detalhada de produtos vendidos por caixa';


--
-- Name: v_resumo_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_resumo_caixa AS
 SELECT id,
    numero,
    terminal,
    usuario,
    status,
    data_abertura,
    data_fechamento,
    total_vendas_pagas,
    qtd_vendas_pagas,
    total_vendas_credito,
    qtd_vendas_credito,
    total_cash,
    qtd_transacoes_cash,
    total_emola,
    qtd_transacoes_emola,
    total_mpesa,
    qtd_transacoes_mpesa,
    total_pos,
    qtd_transacoes_pos,
    total_dividas_pagas,
    qtd_dividas_pagas,
    total_despesas,
    qtd_despesas,
    total_entradas,
    total_saidas,
    saldo_final,
    (((total_cash + total_emola) + total_mpesa) + total_pos) AS soma_formas_validacao,
        CASE
            WHEN (abs(((((total_cash + total_emola) + total_mpesa) + total_pos) - total_entradas)) < 0.01) THEN 'OK'::text
            ELSE 'ERRO'::text
        END AS status_validacao,
        CASE
            WHEN (abs(((((total_cash + total_emola) + total_mpesa) + total_pos) - total_entradas)) < 0.01) THEN true
            ELSE false
        END AS totais_corretos,
    observacoes,
    created_at
   FROM public.caixas c
  ORDER BY data_abertura DESC;


--
-- Dependencies: 270
-- Name: VIEW v_resumo_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_resumo_caixa IS 'Resumo completo de todos os caixas com validação';


--
-- Name: v_resumo_compras_fornecedor; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_resumo_compras_fornecedor AS
 SELECT fo.id AS fornecedor_id,
    fo.nome AS fornecedor_nome,
    count(DISTINCT f.id) AS total_faturas,
    sum(f.total) AS total_comprado,
    avg(f.total) AS media_por_fatura,
    min(f.data_fatura) AS primeira_compra,
    max(f.data_fatura) AS ultima_compra
   FROM (public.fornecedores fo
     LEFT JOIN public.faturas_entrada f ON ((fo.id = f.fornecedor_id)))
  WHERE (fo.ativo = true)
  GROUP BY fo.id, fo.nome
  ORDER BY (sum(f.total)) DESC NULLS LAST;


--
-- Name: v_resumo_produtos_caixa; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_resumo_produtos_caixa AS
 SELECT c.id AS caixa_id,
    c.numero AS caixa_numero,
    p.id AS produto_id,
    p.nome AS produto_nome,
    sum(iv.quantidade) AS quantidade_total,
    iv.preco_unitario,
    sum(iv.subtotal) AS total_vendido
   FROM (((public.caixas c
     CROSS JOIN public.vendas v)
     JOIN public.itens_venda iv ON ((v.id = iv.venda_id)))
     JOIN public.produtos p ON ((iv.produto_id = p.id)))
  WHERE ((v.data_venda >= c.data_abertura) AND (v.data_venda <= COALESCE((c.data_fechamento)::timestamp with time zone, now())) AND (((v.tipo_venda)::text = 'NORMAL'::text) OR (v.tipo_venda IS NULL)))
  GROUP BY c.id, c.numero, p.id, p.nome, iv.preco_unitario
  ORDER BY (sum(iv.subtotal)) DESC;


--
-- Dependencies: 274
-- Name: VIEW v_resumo_produtos_caixa; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_resumo_produtos_caixa IS 'Resumo agregado de produtos vendidos por caixa';


--
-- Name: v_setores_ativos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_setores_ativos AS
 SELECT id,
    nome,
    descricao,
    ativo,
    created_at
   FROM public.setores
  WHERE (ativo = true)
  ORDER BY nome;


--
-- Name: v_usuarios_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_usuarios_completo AS
 SELECT u.id,
    u.nome,
    u.perfil_id,
    p.nome AS perfil_nome,
    u.codigo,
    u.ativo,
    u.created_at,
    u.updated_at
   FROM (public.usuarios u
     JOIN public.perfis_usuario p ON ((u.perfil_id = p.id)))
  ORDER BY u.nome;


--
-- Name: v_vendas_com_pagamentos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_vendas_com_pagamentos AS
 SELECT v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    json_agg(json_build_object('forma_pagamento', fp.nome, 'valor', pv.valor) ORDER BY pv.id) FILTER (WHERE (pv.id IS NOT NULL)) AS pagamentos
   FROM ((public.vendas v
     LEFT JOIN public.pagamentos_venda pv ON ((v.id = pv.venda_id)))
     LEFT JOIN public.formas_pagamento fp ON ((pv.forma_pagamento_id = fp.id)))
  GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;


--
-- Name: v_vendas_completo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_vendas_completo AS
 SELECT v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    v.forma_pagamento_id,
    fp.nome AS forma_pagamento_nome
   FROM (public.vendas v
     LEFT JOIN public.formas_pagamento fp ON ((v.forma_pagamento_id = fp.id)));


--
-- Name: v_vendas_resumo; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_vendas_resumo AS
 SELECT v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    count(iv.id) AS total_itens
   FROM (public.vendas v
     LEFT JOIN public.itens_venda iv ON ((v.id = iv.venda_id)))
  GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;


--
-- Name: vendas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vendas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Dependencies: 223
-- Name: vendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vendas_id_seq OWNED BY public.vendas.id;


--
-- Name: vw_anomalias_data; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_anomalias_data AS
 SELECT id AS venda_id,
    numero AS venda_numero,
    data_venda,
    lag(data_venda) OVER (ORDER BY id) AS venda_anterior,
    (data_venda - lag(data_venda) OVER (ORDER BY id)) AS diferenca,
        CASE
            WHEN (data_venda < lag(data_venda) OVER (ORDER BY id)) THEN 'RETROCESSO DETECTADO'::text
            WHEN ((data_venda - lag(data_venda) OVER (ORDER BY id)) > '1 day'::interval) THEN 'SALTO GRANDE'::text
            ELSE 'Normal'::text
        END AS status
   FROM public.vendas v
  ORDER BY id DESC
 LIMIT 100;


--
-- Name: vw_areas_impressoras; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_areas_impressoras AS
 SELECT a.id AS area_id,
    a.nome AS area_nome,
    a.descricao AS area_descricao,
    i.id AS impressora_id,
    i.nome AS impressora_nome,
    i.tipo AS impressora_tipo,
    i.caminho_rede AS impressora_caminho_rede
   FROM (public.areas a
     LEFT JOIN public.impressoras i ON ((i.id = a.impressora_id)))
  WHERE (a.ativo = true)
  ORDER BY a.nome;


--
-- Name: vw_auditoria_detalhada; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_auditoria_detalhada AS
 SELECT a.id,
    a.tabela,
    a.operacao,
    a.registro_id,
    a.usuario_id,
    u.nome AS usuario_nome,
    u.codigo AS usuario_codigo,
    a.terminal_nome,
    a.ip_address,
    a.descricao,
    a.data_operacao,
    a.dados_anteriores,
    a.dados_novos
   FROM (public.auditoria a
     LEFT JOIN public.usuarios u ON ((u.id = a.usuario_id)))
  ORDER BY a.data_operacao DESC;


--
-- Name: vw_auditoria_por_usuario; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_auditoria_por_usuario AS
 SELECT u.id AS usuario_id,
    u.nome AS usuario_nome,
    a.tabela,
    a.operacao,
    count(*) AS total_operacoes,
    max(a.data_operacao) AS ultima_operacao
   FROM (public.auditoria a
     JOIN public.usuarios u ON ((u.id = a.usuario_id)))
  GROUP BY u.id, u.nome, a.tabela, a.operacao
  ORDER BY (count(*)) DESC;


--
-- Name: vw_historico_precos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_historico_precos AS
 SELECT a.id,
    a.registro_id AS produto_id,
    (a.dados_anteriores ->> 'nome'::text) AS produto_nome,
    ((a.dados_anteriores ->> 'preco'::text))::numeric(10,2) AS preco_anterior,
    ((a.dados_novos ->> 'preco'::text))::numeric(10,2) AS preco_novo,
    (((a.dados_novos ->> 'preco'::text))::numeric(10,2) - ((a.dados_anteriores ->> 'preco'::text))::numeric(10,2)) AS diferenca,
    a.usuario_id,
    u.nome AS usuario_nome,
    a.data_operacao
   FROM (public.auditoria a
     LEFT JOIN public.usuarios u ON ((u.id = a.usuario_id)))
  WHERE (((a.tabela)::text = 'produtos'::text) AND ((a.operacao)::text = 'UPDATE'::text) AND ((a.dados_anteriores ->> 'preco'::text) IS DISTINCT FROM (a.dados_novos ->> 'preco'::text)))
  ORDER BY a.data_operacao DESC;


--
-- Name: vw_logins_falhados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_logins_falhados AS
 SELECT l.id,
    l.usuario_id,
    u.nome AS usuario_nome,
    u.codigo AS usuario_codigo,
    l.terminal_nome,
    l.ip_address,
    l.motivo_falha,
    l.data_hora,
    ( SELECT count(*) AS count
           FROM public.logs_acesso l2
          WHERE ((l2.usuario_id = l.usuario_id) AND ((l2.tipo)::text = 'LOGIN_FALHOU'::text) AND (l2.data_hora >= (now() - '01:00:00'::interval)))) AS tentativas_ultima_hora
   FROM (public.logs_acesso l
     LEFT JOIN public.usuarios u ON ((u.id = l.usuario_id)))
  WHERE ((l.tipo)::text = 'LOGIN_FALHOU'::text)
  ORDER BY l.data_hora DESC;


--
-- Name: vw_mapeamento_impressao; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_mapeamento_impressao AS
 SELECT td.id AS tipo_documento_id,
    td.codigo AS documento_codigo,
    td.nome AS documento_nome,
    i.id AS impressora_id,
    i.nome AS impressora_nome,
    i.tipo AS impressora_tipo,
    i.caminho_rede AS impressora_caminho_rede,
    di.prioridade
   FROM ((public.tipos_documento td
     LEFT JOIN public.documento_impressora di ON ((di.tipo_documento_id = td.id)))
     LEFT JOIN public.impressoras i ON ((i.id = di.impressora_id)))
  WHERE (td.ativo = true)
  ORDER BY td.nome, di.prioridade;


--
-- Name: vw_operacoes_suspeitas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_operacoes_suspeitas AS
 SELECT a.usuario_id,
    u.nome AS usuario_nome,
    a.tabela,
    a.operacao,
    count(*) AS total,
    min(a.data_operacao) AS primeira_operacao,
    max(a.data_operacao) AS ultima_operacao,
    (EXTRACT(epoch FROM (max(a.data_operacao) - min(a.data_operacao))) / (60)::numeric) AS duracao_minutos
   FROM (public.auditoria a
     LEFT JOIN public.usuarios u ON ((u.id = a.usuario_id)))
  WHERE (a.data_operacao >= (now() - '01:00:00'::interval))
  GROUP BY a.usuario_id, u.nome, a.tabela, a.operacao
 HAVING (count(*) > 50)
  ORDER BY (count(*)) DESC;


--
-- Name: vw_produtos_com_codigo_barras; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_produtos_com_codigo_barras AS
 SELECT p.id,
    p.codigo,
    p.nome,
    p.codigo_barras,
    f.nome AS familia_nome,
    p.preco,
    p.estoque,
    p.ativo,
        CASE
            WHEN (p.codigo_barras IS NOT NULL) THEN 'Sim'::text
            ELSE 'Não'::text
        END AS tem_codigo_barras
   FROM (public.produtos p
     LEFT JOIN public.familias f ON ((f.id = p.familia_id)))
  WHERE (p.ativo = true)
  ORDER BY p.nome;


--
-- Name: vw_produtos_deletados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_produtos_deletados AS
 SELECT a.id AS auditoria_id,
    a.registro_id AS produto_id,
    (a.dados_anteriores ->> 'codigo'::text) AS codigo,
    (a.dados_anteriores ->> 'nome'::text) AS nome,
    ((a.dados_anteriores ->> 'preco'::text))::numeric(10,2) AS preco,
    ((a.dados_anteriores ->> 'estoque'::text))::integer AS estoque,
    a.usuario_id,
    u.nome AS usuario_nome,
    a.data_operacao AS data_delecao
   FROM (public.auditoria a
     LEFT JOIN public.usuarios u ON ((u.id = a.usuario_id)))
  WHERE (((a.tabela)::text = 'produtos'::text) AND ((a.operacao)::text = 'DELETE'::text))
  ORDER BY a.data_operacao DESC;


--
-- Name: vw_terminais_ativos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_terminais_ativos AS
 SELECT t.id,
    t.nome,
    t.ip_address,
    t.tipo,
    t.descricao,
    t.ultima_conexao,
        CASE
            WHEN (t.ultima_conexao IS NULL) THEN 'Nunca Conectado'::text
            WHEN (t.ultima_conexao > (CURRENT_TIMESTAMP - '00:05:00'::interval)) THEN 'Online'::text
            WHEN (t.ultima_conexao > (CURRENT_TIMESTAMP - '01:00:00'::interval)) THEN 'Inativo'::text
            ELSE 'Offline'::text
        END AS status_conexao,
    u.nome AS usuario_atual,
    u.id AS usuario_id
   FROM (public.terminais t
     LEFT JOIN public.usuarios u ON ((u.terminal_id_atual = t.id)))
  WHERE (t.ativo = true)
  ORDER BY t.nome;


--
-- Name: vw_vendas_por_terminal; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_vendas_por_terminal AS
 SELECT t.id AS terminal_id,
    t.nome AS terminal_nome,
    count(v.id) AS total_vendas,
    sum(v.total) AS valor_total,
    date(v.data_venda) AS data
   FROM (public.terminais t
     LEFT JOIN public.vendas v ON ((v.terminal_id = t.id)))
  GROUP BY t.id, t.nome, (date(v.data_venda))
  ORDER BY (date(v.data_venda)) DESC, t.nome;


--
-- Name: acertos_stock id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acertos_stock ALTER COLUMN id SET DEFAULT nextval('public.acertos_stock_id_seq'::regclass);


--
-- Name: areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas ALTER COLUMN id SET DEFAULT nextval('public.areas_id_seq'::regclass);


--
-- Name: auditoria id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria ALTER COLUMN id SET DEFAULT nextval('public.auditoria_id_seq'::regclass);


--
-- Name: caixas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixas ALTER COLUMN id SET DEFAULT nextval('public.caixas_id_seq'::regclass);


--
-- Name: cancelamentos_item_pedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelamentos_item_pedido ALTER COLUMN id SET DEFAULT nextval('public.cancelamentos_item_pedido_id_seq'::regclass);


--
-- Name: clientes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes ALTER COLUMN id SET DEFAULT nextval('public.clientes_id_seq'::regclass);


--
-- Name: conferencias_caixa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conferencias_caixa ALTER COLUMN id SET DEFAULT nextval('public.conferencias_caixa_id_seq'::regclass);


--
-- Name: configuracoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes ALTER COLUMN id SET DEFAULT nextval('public.configuracoes_id_seq'::regclass);


--
-- Name: controle_fecho_caixa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.controle_fecho_caixa ALTER COLUMN id SET DEFAULT nextval('public.controle_fecho_caixa_id_seq'::regclass);


--
-- Name: despesas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despesas ALTER COLUMN id SET DEFAULT nextval('public.despesas_id_seq'::regclass);


--
-- Name: dividas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividas ALTER COLUMN id SET DEFAULT nextval('public.dividas_id_seq'::regclass);


--
-- Name: documento_impressora id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_impressora ALTER COLUMN id SET DEFAULT nextval('public.documento_impressora_id_seq'::regclass);


--
-- Name: empresa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresa ALTER COLUMN id SET DEFAULT nextval('public.empresa_id_seq'::regclass);


--
-- Name: familia_areas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_areas ALTER COLUMN id SET DEFAULT nextval('public.familia_areas_id_seq'::regclass);


--
-- Name: familia_setores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_setores ALTER COLUMN id SET DEFAULT nextval('public.familia_setores_id_seq'::regclass);


--
-- Name: familias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familias ALTER COLUMN id SET DEFAULT nextval('public.familias_id_seq'::regclass);


--
-- Name: faturas_entrada id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas_entrada ALTER COLUMN id SET DEFAULT nextval('public.faturas_entrada_id_seq'::regclass);


--
-- Name: formas_pagamento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formas_pagamento ALTER COLUMN id SET DEFAULT nextval('public.formas_pagamento_id_seq'::regclass);


--
-- Name: fornecedores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedores ALTER COLUMN id SET DEFAULT nextval('public.fornecedores_id_seq'::regclass);


--
-- Name: impressoras id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressoras ALTER COLUMN id SET DEFAULT nextval('public.impressoras_id_seq'::regclass);


--
-- Name: itens_fatura_entrada id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_fatura_entrada ALTER COLUMN id SET DEFAULT nextval('public.itens_fatura_entrada_id_seq'::regclass);


--
-- Name: itens_pedido id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_pedido ALTER COLUMN id SET DEFAULT nextval('public.itens_pedido_id_seq'::regclass);


--
-- Name: itens_venda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_venda ALTER COLUMN id SET DEFAULT nextval('public.itens_venda_id_seq'::regclass);


--
-- Name: locais_mesa id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locais_mesa ALTER COLUMN id SET DEFAULT nextval('public.locais_mesa_id_seq'::regclass);


--
-- Name: logs_acesso id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_acesso ALTER COLUMN id SET DEFAULT nextval('public.logs_acesso_id_seq'::regclass);


--
-- Name: mesas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mesas ALTER COLUMN id SET DEFAULT nextval('public.mesas_id_seq'::regclass);


--
-- Name: pagamentos_divida id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_divida ALTER COLUMN id SET DEFAULT nextval('public.pagamentos_divida_id_seq'::regclass);


--
-- Name: pagamentos_venda id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_venda ALTER COLUMN id SET DEFAULT nextval('public.pagamentos_venda_id_seq'::regclass);


--
-- Name: pedidos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos ALTER COLUMN id SET DEFAULT nextval('public.pedidos_id_seq'::regclass);


--
-- Name: perfil_permissoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissoes ALTER COLUMN id SET DEFAULT nextval('public.perfil_permissoes_id_seq'::regclass);


--
-- Name: perfis_usuario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfis_usuario ALTER COLUMN id SET DEFAULT nextval('public.perfis_usuario_id_seq'::regclass);


--
-- Name: permissoes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissoes ALTER COLUMN id SET DEFAULT nextval('public.permissoes_id_seq'::regclass);


--
-- Name: produto_composicao id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_composicao ALTER COLUMN id SET DEFAULT nextval('public.produto_composicao_id_seq'::regclass);


--
-- Name: produtos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos ALTER COLUMN id SET DEFAULT nextval('public.produtos_id_seq'::regclass);


--
-- Name: servidor_tempo id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servidor_tempo ALTER COLUMN id SET DEFAULT nextval('public.servidor_tempo_id_seq'::regclass);


--
-- Name: setores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setores ALTER COLUMN id SET DEFAULT nextval('public.setores_id_seq'::regclass);


--
-- Name: terminais id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminais ALTER COLUMN id SET DEFAULT nextval('public.terminais_id_seq'::regclass);


--
-- Name: terminal_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminal_logs ALTER COLUMN id SET DEFAULT nextval('public.terminal_logs_id_seq'::regclass);


--
-- Name: tipos_documento id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documento ALTER COLUMN id SET DEFAULT nextval('public.tipos_documento_id_seq'::regclass);


--
-- Name: usuarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios ALTER COLUMN id SET DEFAULT nextval('public.usuarios_id_seq'::regclass);


--
-- Name: vendas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas ALTER COLUMN id SET DEFAULT nextval('public.vendas_id_seq'::regclass);


--
-- Name: acertos_stock acertos_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acertos_stock
    ADD CONSTRAINT acertos_stock_pkey PRIMARY KEY (id);


--
-- Name: areas areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_pkey PRIMARY KEY (id);


--
-- Name: auditoria auditoria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_pkey PRIMARY KEY (id);


--
-- Name: caixas caixas_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixas
    ADD CONSTRAINT caixas_numero_key UNIQUE (numero);


--
-- Name: caixas caixas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.caixas
    ADD CONSTRAINT caixas_pkey PRIMARY KEY (id);


--
-- Name: cancelamentos_item_pedido cancelamentos_item_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelamentos_item_pedido
    ADD CONSTRAINT cancelamentos_item_pedido_pkey PRIMARY KEY (id);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- Name: conferencias_caixa conferencias_caixa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conferencias_caixa
    ADD CONSTRAINT conferencias_caixa_pkey PRIMARY KEY (id);


--
-- Name: configuracoes configuracoes_chave_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes
    ADD CONSTRAINT configuracoes_chave_key UNIQUE (chave);


--
-- Name: configuracoes configuracoes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configuracoes
    ADD CONSTRAINT configuracoes_pkey PRIMARY KEY (id);


--
-- Name: controle_fecho_caixa controle_fecho_caixa_data_fecho_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.controle_fecho_caixa
    ADD CONSTRAINT controle_fecho_caixa_data_fecho_key UNIQUE (data_fecho);


--
-- Name: controle_fecho_caixa controle_fecho_caixa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.controle_fecho_caixa
    ADD CONSTRAINT controle_fecho_caixa_pkey PRIMARY KEY (id);


--
-- Name: despesas despesas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despesas
    ADD CONSTRAINT despesas_pkey PRIMARY KEY (id);


--
-- Name: dividas dividas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividas
    ADD CONSTRAINT dividas_pkey PRIMARY KEY (id);


--
-- Name: dividas dividas_venda_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividas
    ADD CONSTRAINT dividas_venda_id_key UNIQUE (venda_id);


--
-- Name: documento_impressora documento_impressora_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_impressora
    ADD CONSTRAINT documento_impressora_pkey PRIMARY KEY (id);


--
-- Name: documento_impressora documento_impressora_tipo_documento_id_impressora_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_impressora
    ADD CONSTRAINT documento_impressora_tipo_documento_id_impressora_id_key UNIQUE (tipo_documento_id, impressora_id);


--
-- Name: empresa empresa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id);


--
-- Name: familia_areas familia_areas_familia_id_area_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_areas
    ADD CONSTRAINT familia_areas_familia_id_area_id_key UNIQUE (familia_id, area_id);


--
-- Name: familia_areas familia_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_areas
    ADD CONSTRAINT familia_areas_pkey PRIMARY KEY (id);


--
-- Name: familia_setores familia_setores_familia_id_setor_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_setores
    ADD CONSTRAINT familia_setores_familia_id_setor_id_key UNIQUE (familia_id, setor_id);


--
-- Name: familia_setores familia_setores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_setores
    ADD CONSTRAINT familia_setores_pkey PRIMARY KEY (id);


--
-- Name: familias familias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familias
    ADD CONSTRAINT familias_pkey PRIMARY KEY (id);


--
-- Name: faturas_entrada faturas_entrada_fornecedor_id_numero_fatura_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas_entrada
    ADD CONSTRAINT faturas_entrada_fornecedor_id_numero_fatura_key UNIQUE (fornecedor_id, numero_fatura);


--
-- Name: faturas_entrada faturas_entrada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas_entrada
    ADD CONSTRAINT faturas_entrada_pkey PRIMARY KEY (id);


--
-- Name: formas_pagamento formas_pagamento_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formas_pagamento
    ADD CONSTRAINT formas_pagamento_nome_key UNIQUE (nome);


--
-- Name: formas_pagamento formas_pagamento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.formas_pagamento
    ADD CONSTRAINT formas_pagamento_pkey PRIMARY KEY (id);


--
-- Name: fornecedores fornecedores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fornecedores
    ADD CONSTRAINT fornecedores_pkey PRIMARY KEY (id);


--
-- Name: impressoras impressoras_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressoras
    ADD CONSTRAINT impressoras_nome_key UNIQUE (nome);


--
-- Name: impressoras impressoras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressoras
    ADD CONSTRAINT impressoras_pkey PRIMARY KEY (id);


--
-- Name: itens_fatura_entrada itens_fatura_entrada_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_fatura_entrada
    ADD CONSTRAINT itens_fatura_entrada_pkey PRIMARY KEY (id);


--
-- Name: itens_pedido itens_pedido_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT itens_pedido_pkey PRIMARY KEY (id);


--
-- Name: itens_venda itens_venda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_venda
    ADD CONSTRAINT itens_venda_pkey PRIMARY KEY (id);


--
-- Name: locais_mesa locais_mesa_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locais_mesa
    ADD CONSTRAINT locais_mesa_nome_key UNIQUE (nome);


--
-- Name: locais_mesa locais_mesa_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.locais_mesa
    ADD CONSTRAINT locais_mesa_pkey PRIMARY KEY (id);


--
-- Name: logs_acesso logs_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_acesso
    ADD CONSTRAINT logs_acesso_pkey PRIMARY KEY (id);


--
-- Name: mesas mesas_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mesas
    ADD CONSTRAINT mesas_numero_key UNIQUE (numero);


--
-- Name: mesas mesas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mesas
    ADD CONSTRAINT mesas_pkey PRIMARY KEY (id);


--
-- Name: pagamentos_divida pagamentos_divida_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_divida
    ADD CONSTRAINT pagamentos_divida_pkey PRIMARY KEY (id);


--
-- Name: pagamentos_venda pagamentos_venda_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_venda
    ADD CONSTRAINT pagamentos_venda_pkey PRIMARY KEY (id);


--
-- Name: pedidos pedidos_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_numero_key UNIQUE (numero);


--
-- Name: pedidos pedidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_pkey PRIMARY KEY (id);


--
-- Name: perfil_permissoes perfil_permissoes_perfil_id_permissao_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissoes
    ADD CONSTRAINT perfil_permissoes_perfil_id_permissao_id_key UNIQUE (perfil_id, permissao_id);


--
-- Name: perfil_permissoes perfil_permissoes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissoes
    ADD CONSTRAINT perfil_permissoes_pkey PRIMARY KEY (id);


--
-- Name: perfis_usuario perfis_usuario_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfis_usuario
    ADD CONSTRAINT perfis_usuario_nome_key UNIQUE (nome);


--
-- Name: perfis_usuario perfis_usuario_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfis_usuario
    ADD CONSTRAINT perfis_usuario_pkey PRIMARY KEY (id);


--
-- Name: permissoes permissoes_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissoes
    ADD CONSTRAINT permissoes_codigo_key UNIQUE (codigo);


--
-- Name: permissoes permissoes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissoes
    ADD CONSTRAINT permissoes_pkey PRIMARY KEY (id);


--
-- Name: produto_composicao produto_composicao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_composicao
    ADD CONSTRAINT produto_composicao_pkey PRIMARY KEY (id);


--
-- Name: produto_composicao produto_composicao_produto_id_produto_componente_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_composicao
    ADD CONSTRAINT produto_composicao_produto_id_produto_componente_id_key UNIQUE (produto_id, produto_componente_id);


--
-- Name: produtos produtos_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_codigo_key UNIQUE (codigo);


--
-- Name: produtos produtos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_pkey PRIMARY KEY (id);


--
-- Name: servidor_tempo servidor_tempo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servidor_tempo
    ADD CONSTRAINT servidor_tempo_pkey PRIMARY KEY (id);


--
-- Name: setores setores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.setores
    ADD CONSTRAINT setores_pkey PRIMARY KEY (id);


--
-- Name: terminais terminais_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminais
    ADD CONSTRAINT terminais_nome_key UNIQUE (nome);


--
-- Name: terminais terminais_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminais
    ADD CONSTRAINT terminais_pkey PRIMARY KEY (id);


--
-- Name: terminal_logs terminal_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminal_logs
    ADD CONSTRAINT terminal_logs_pkey PRIMARY KEY (id);


--
-- Name: tipos_documento tipos_documento_codigo_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documento
    ADD CONSTRAINT tipos_documento_codigo_key UNIQUE (codigo);


--
-- Name: tipos_documento tipos_documento_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documento
    ADD CONSTRAINT tipos_documento_pkey PRIMARY KEY (id);


--
-- Name: usuarios usuarios_nome_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_nome_key UNIQUE (nome);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: vendas vendas_numero_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT vendas_numero_key UNIQUE (numero);


--
-- Name: vendas vendas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT vendas_pkey PRIMARY KEY (id);


--
-- Name: idx_acertos_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acertos_area ON public.acertos_stock USING btree (area_id);


--
-- Name: idx_acertos_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acertos_data ON public.acertos_stock USING btree (data);


--
-- Name: idx_acertos_motivo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acertos_motivo ON public.acertos_stock USING btree (motivo);


--
-- Name: idx_acertos_produto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acertos_produto ON public.acertos_stock USING btree (produto_id);


--
-- Name: idx_acertos_setor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_acertos_setor ON public.acertos_stock USING btree (setor_id);


--
-- Name: idx_areas_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_areas_ativo ON public.areas USING btree (ativo);


--
-- Name: idx_areas_impressora; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_areas_impressora ON public.areas USING btree (impressora_id);


--
-- Name: idx_auditoria_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_data ON public.auditoria USING btree (data_operacao DESC);


--
-- Name: idx_auditoria_operacao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_operacao ON public.auditoria USING btree (operacao);


--
-- Name: idx_auditoria_registro; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_registro ON public.auditoria USING btree (tabela, registro_id);


--
-- Name: idx_auditoria_tabela; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_tabela ON public.auditoria USING btree (tabela);


--
-- Name: idx_auditoria_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_auditoria_usuario ON public.auditoria USING btree (usuario_id);


--
-- Name: idx_caixas_data_abertura; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixas_data_abertura ON public.caixas USING btree (data_abertura);


--
-- Name: idx_caixas_numero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixas_numero ON public.caixas USING btree (numero);


--
-- Name: idx_caixas_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixas_status ON public.caixas USING btree (status);


--
-- Name: idx_caixas_terminal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_caixas_terminal ON public.caixas USING btree (terminal);


--
-- Name: idx_cancelamentos_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancelamentos_data ON public.cancelamentos_item_pedido USING btree (data_cancelamento);


--
-- Name: idx_cancelamentos_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancelamentos_pedido ON public.cancelamentos_item_pedido USING btree (pedido_id);


--
-- Name: idx_cancelamentos_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cancelamentos_usuario ON public.cancelamentos_item_pedido USING btree (usuario_id);


--
-- Name: idx_clientes_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_ativo ON public.clientes USING btree (ativo);


--
-- Name: idx_clientes_contacto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_contacto ON public.clientes USING btree (contacto);


--
-- Name: idx_clientes_nome; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clientes_nome ON public.clientes USING btree (nome);


--
-- Name: idx_conferencias_caixa_caixa_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conferencias_caixa_caixa_id ON public.conferencias_caixa USING btree (caixa_id);


--
-- Name: idx_configuracoes_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_configuracoes_categoria ON public.configuracoes USING btree (categoria);


--
-- Name: idx_configuracoes_chave; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_configuracoes_chave ON public.configuracoes USING btree (chave);


--
-- Name: idx_controle_fecho_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_controle_fecho_data ON public.controle_fecho_caixa USING btree (data_fecho DESC);


--
-- Name: idx_despesas_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_despesas_categoria ON public.despesas USING btree (categoria);


--
-- Name: idx_despesas_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_despesas_data ON public.despesas USING btree (data_despesa);


--
-- Name: idx_dividas_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dividas_cliente ON public.dividas USING btree (cliente_id);


--
-- Name: idx_dividas_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dividas_data ON public.dividas USING btree (data_divida);


--
-- Name: idx_dividas_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_dividas_status ON public.dividas USING btree (status);


--
-- Name: idx_documento_impressora_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documento_impressora_tipo ON public.documento_impressora USING btree (tipo_documento_id);


--
-- Name: idx_familia_areas_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_familia_areas_area ON public.familia_areas USING btree (area_id);


--
-- Name: idx_familia_areas_familia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_familia_areas_familia ON public.familia_areas USING btree (familia_id);


--
-- Name: idx_familia_setores_familia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_familia_setores_familia ON public.familia_setores USING btree (familia_id);


--
-- Name: idx_familia_setores_setor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_familia_setores_setor ON public.familia_setores USING btree (setor_id);


--
-- Name: idx_faturas_entrada_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_faturas_entrada_data ON public.faturas_entrada USING btree (data_fatura);


--
-- Name: idx_faturas_entrada_fornecedor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_faturas_entrada_fornecedor ON public.faturas_entrada USING btree (fornecedor_id);


--
-- Name: idx_faturas_entrada_numero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_faturas_entrada_numero ON public.faturas_entrada USING btree (numero_fatura);


--
-- Name: idx_fornecedores_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fornecedores_ativo ON public.fornecedores USING btree (ativo);


--
-- Name: idx_fornecedores_nif; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fornecedores_nif ON public.fornecedores USING btree (nif);


--
-- Name: idx_fornecedores_nome; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fornecedores_nome ON public.fornecedores USING btree (nome);


--
-- Name: idx_impressoras_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_impressoras_ativo ON public.impressoras USING btree (ativo);


--
-- Name: idx_itens_fatura_entrada_fatura; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_itens_fatura_entrada_fatura ON public.itens_fatura_entrada USING btree (fatura_id);


--
-- Name: idx_itens_fatura_entrada_produto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_itens_fatura_entrada_produto ON public.itens_fatura_entrada USING btree (produto_id);


--
-- Name: idx_itens_pedido_pedido; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_itens_pedido_pedido ON public.itens_pedido USING btree (pedido_id);


--
-- Name: idx_itens_venda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_itens_venda ON public.itens_venda USING btree (venda_id);


--
-- Name: idx_logs_acesso_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_acesso_data ON public.logs_acesso USING btree (data_hora DESC);


--
-- Name: idx_logs_acesso_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_acesso_tipo ON public.logs_acesso USING btree (tipo);


--
-- Name: idx_logs_acesso_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_acesso_usuario ON public.logs_acesso USING btree (usuario_id);


--
-- Name: idx_mesas_local; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mesas_local ON public.mesas USING btree (local_id);


--
-- Name: idx_mesas_numero; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mesas_numero ON public.mesas USING btree (numero);


--
-- Name: idx_pagamentos_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagamentos_data ON public.pagamentos_divida USING btree (data_pagamento);


--
-- Name: idx_pagamentos_divida; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagamentos_divida ON public.pagamentos_divida USING btree (divida_id);


--
-- Name: idx_pagamentos_venda_forma_pagamento_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagamentos_venda_forma_pagamento_id ON public.pagamentos_venda USING btree (forma_pagamento_id);


--
-- Name: idx_pagamentos_venda_venda_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pagamentos_venda_venda_id ON public.pagamentos_venda USING btree (venda_id);


--
-- Name: idx_pedidos_mesa; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_mesa ON public.pedidos USING btree (mesa_id);


--
-- Name: idx_pedidos_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_status ON public.pedidos USING btree (status);


--
-- Name: idx_pedidos_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pedidos_usuario ON public.pedidos USING btree (usuario_id);


--
-- Name: idx_perfil_permissoes_perfil; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perfil_permissoes_perfil ON public.perfil_permissoes USING btree (perfil_id);


--
-- Name: idx_perfil_permissoes_permissao; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perfil_permissoes_permissao ON public.perfil_permissoes USING btree (permissao_id);


--
-- Name: idx_permissoes_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissoes_categoria ON public.permissoes USING btree (categoria);


--
-- Name: idx_permissoes_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_permissoes_codigo ON public.permissoes USING btree (codigo);


--
-- Name: idx_produto_composicao_componente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produto_composicao_componente ON public.produto_composicao USING btree (produto_id);


--
-- Name: idx_produto_composicao_produto; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produto_composicao_produto ON public.produto_composicao USING btree (produto_id);


--
-- Name: idx_produtos_area; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_area ON public.produtos USING btree (area_id);


--
-- Name: idx_produtos_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_ativo ON public.produtos USING btree (ativo);


--
-- Name: idx_produtos_codigo_barras; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_produtos_codigo_barras ON public.produtos USING btree (codigo_barras) WHERE (codigo_barras IS NOT NULL);


--
-- Name: idx_produtos_codigo_barras_lower; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_codigo_barras_lower ON public.produtos USING btree (lower((codigo_barras)::text)) WHERE (codigo_barras IS NOT NULL);


--
-- Name: idx_produtos_estoque_baixo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_estoque_baixo ON public.produtos USING btree (estoque_minimo) WHERE (estoque < estoque_minimo);


--
-- Name: idx_produtos_familia; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_familia ON public.produtos USING btree (familia_id);


--
-- Name: idx_produtos_setor; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_produtos_setor ON public.produtos USING btree (setor_id);


--
-- Name: idx_servidor_tempo_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servidor_tempo_data ON public.servidor_tempo USING btree (ultima_data_servidor DESC);


--
-- Name: idx_setores_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_setores_ativo ON public.setores USING btree (ativo);


--
-- Name: idx_terminais_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terminais_ativo ON public.terminais USING btree (ativo);


--
-- Name: idx_terminais_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terminais_tipo ON public.terminais USING btree (tipo);


--
-- Name: idx_terminal_logs_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terminal_logs_created ON public.terminal_logs USING btree (created_at);


--
-- Name: idx_terminal_logs_terminal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_terminal_logs_terminal ON public.terminal_logs USING btree (terminal_id);


--
-- Name: idx_tipos_documento_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_tipos_documento_codigo ON public.tipos_documento USING btree (codigo);


--
-- Name: idx_usuarios_ativo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_ativo ON public.usuarios USING btree (ativo);


--
-- Name: idx_usuarios_codigo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_codigo ON public.usuarios USING btree (codigo);


--
-- Name: idx_usuarios_nome; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_nome ON public.usuarios USING btree (nome);


--
-- Name: idx_usuarios_perfil; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_usuarios_perfil ON public.usuarios USING btree (perfil_id);


--
-- Name: idx_vendas_cliente; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_cliente ON public.vendas USING btree (cliente_id);


--
-- Name: idx_vendas_data; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_data ON public.vendas USING btree (data_venda);


--
-- Name: idx_vendas_forma_pagamento; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_forma_pagamento ON public.vendas USING btree (forma_pagamento_id);


--
-- Name: idx_vendas_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_status ON public.vendas USING btree (status);


--
-- Name: idx_vendas_terminal; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_terminal ON public.vendas USING btree (terminal_id);


--
-- Name: idx_vendas_tipo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_tipo ON public.vendas USING btree (tipo_venda);


--
-- Name: idx_vendas_usuario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_vendas_usuario ON public.vendas USING btree (usuario_id);


--
-- Name: v_mesas_por_local _RETURN; Type: RULE; Schema: public; Owner: -
--

CREATE OR REPLACE VIEW public.v_mesas_por_local AS
 SELECT l.id AS local_id,
    l.nome AS local_nome,
    count(m.id) AS total_mesas,
    count(
        CASE
            WHEN m.ativo THEN 1
            ELSE NULL::integer
        END) AS mesas_ativas,
    count(p.id) AS mesas_ocupadas,
    count(
        CASE
            WHEN (m.ativo AND (p.id IS NULL)) THEN 1
            ELSE NULL::integer
        END) AS mesas_livres
   FROM ((public.locais_mesa l
     LEFT JOIN public.mesas m ON ((l.id = m.local_id)))
     LEFT JOIN public.pedidos p ON (((m.id = p.mesa_id) AND ((p.status)::text = 'aberto'::text))))
  GROUP BY l.id, l.nome
  ORDER BY l.ordem;


--
-- Name: produtos before_insert_produto_codigo; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER before_insert_produto_codigo BEFORE INSERT ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.trigger_gerar_codigo_produto();


--
-- Name: configuracoes trigger_atualizar_data_configuracao; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_data_configuracao BEFORE UPDATE ON public.configuracoes FOR EACH ROW EXECUTE FUNCTION public.atualizar_data_configuracao();


--
-- Name: acertos_stock trigger_atualizar_estoque; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_estoque AFTER INSERT ON public.acertos_stock FOR EACH ROW EXECUTE FUNCTION public.atualizar_estoque_produto();


--
-- Name: impressoras trigger_atualizar_impressoras; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_impressoras BEFORE UPDATE ON public.impressoras FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at_impressoras();


--
-- Name: terminais trigger_atualizar_terminais; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_terminais BEFORE UPDATE ON public.terminais FOR EACH ROW EXECUTE FUNCTION public.atualizar_updated_at_terminais();


--
-- Name: itens_pedido trigger_atualizar_total_pedido; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_total_pedido AFTER INSERT OR DELETE OR UPDATE ON public.itens_pedido FOR EACH ROW EXECUTE FUNCTION public.atualizar_total_pedido();


--
-- Name: dividas trigger_atualizar_valor_restante; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_atualizar_valor_restante BEFORE INSERT OR UPDATE ON public.dividas FOR EACH ROW EXECUTE FUNCTION public.atualizar_valor_restante();


--
-- Name: areas trigger_audit_areas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_areas AFTER INSERT OR DELETE OR UPDATE ON public.areas FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: clientes trigger_audit_clientes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_clientes AFTER INSERT OR DELETE OR UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: familias trigger_audit_familias; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_familias AFTER INSERT OR DELETE OR UPDATE ON public.familias FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: impressoras trigger_audit_impressoras; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_impressoras AFTER INSERT OR DELETE OR UPDATE ON public.impressoras FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: itens_venda trigger_audit_itens_venda; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_itens_venda AFTER INSERT OR DELETE OR UPDATE ON public.itens_venda FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: mesas trigger_audit_mesas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_mesas AFTER INSERT OR DELETE OR UPDATE ON public.mesas FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: perfil_permissoes trigger_audit_perfil_permissoes; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_perfil_permissoes AFTER INSERT OR DELETE OR UPDATE ON public.perfil_permissoes FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: produtos trigger_audit_produtos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_produtos AFTER INSERT OR DELETE OR UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: usuarios trigger_audit_usuarios; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_usuarios AFTER INSERT OR DELETE OR UPDATE ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: vendas trigger_audit_vendas; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_audit_vendas AFTER INSERT OR DELETE OR UPDATE ON public.vendas FOR EACH ROW EXECUTE FUNCTION public.audit_trigger_func();


--
-- Name: produtos trigger_validar_codigo_barras_produto; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_validar_codigo_barras_produto BEFORE INSERT OR UPDATE ON public.produtos FOR EACH ROW EXECUTE FUNCTION public.trigger_validar_codigo_barras();


--
-- Name: vendas trigger_validar_data_venda; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_validar_data_venda BEFORE INSERT ON public.vendas FOR EACH ROW EXECUTE FUNCTION public.validar_data_venda();


--
-- Name: acertos_stock acertos_stock_area_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acertos_stock
    ADD CONSTRAINT acertos_stock_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);


--
-- Name: acertos_stock acertos_stock_produto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acertos_stock
    ADD CONSTRAINT acertos_stock_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES public.produtos(id) ON DELETE CASCADE;


--
-- Name: acertos_stock acertos_stock_setor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acertos_stock
    ADD CONSTRAINT acertos_stock_setor_id_fkey FOREIGN KEY (setor_id) REFERENCES public.setores(id);


--
-- Name: areas areas_impressora_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.areas
    ADD CONSTRAINT areas_impressora_id_fkey FOREIGN KEY (impressora_id) REFERENCES public.impressoras(id) ON DELETE SET NULL;


--
-- Name: auditoria auditoria_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auditoria
    ADD CONSTRAINT auditoria_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: cancelamentos_item_pedido cancelamentos_item_pedido_item_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelamentos_item_pedido
    ADD CONSTRAINT cancelamentos_item_pedido_item_pedido_id_fkey FOREIGN KEY (item_pedido_id) REFERENCES public.itens_pedido(id) ON DELETE CASCADE;


--
-- Name: cancelamentos_item_pedido cancelamentos_item_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelamentos_item_pedido
    ADD CONSTRAINT cancelamentos_item_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- Name: cancelamentos_item_pedido cancelamentos_item_pedido_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.cancelamentos_item_pedido
    ADD CONSTRAINT cancelamentos_item_pedido_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: conferencias_caixa conferencias_caixa_caixa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conferencias_caixa
    ADD CONSTRAINT conferencias_caixa_caixa_id_fkey FOREIGN KEY (caixa_id) REFERENCES public.caixas(id) ON DELETE CASCADE;


--
-- Name: controle_fecho_caixa controle_fecho_caixa_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.controle_fecho_caixa
    ADD CONSTRAINT controle_fecho_caixa_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: despesas despesas_forma_pagamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.despesas
    ADD CONSTRAINT despesas_forma_pagamento_id_fkey FOREIGN KEY (forma_pagamento_id) REFERENCES public.formas_pagamento(id);


--
-- Name: dividas dividas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividas
    ADD CONSTRAINT dividas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE CASCADE;


--
-- Name: dividas dividas_venda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dividas
    ADD CONSTRAINT dividas_venda_id_fkey FOREIGN KEY (venda_id) REFERENCES public.vendas(id) ON DELETE CASCADE;


--
-- Name: documento_impressora documento_impressora_impressora_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_impressora
    ADD CONSTRAINT documento_impressora_impressora_id_fkey FOREIGN KEY (impressora_id) REFERENCES public.impressoras(id) ON DELETE CASCADE;


--
-- Name: documento_impressora documento_impressora_tipo_documento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documento_impressora
    ADD CONSTRAINT documento_impressora_tipo_documento_id_fkey FOREIGN KEY (tipo_documento_id) REFERENCES public.tipos_documento(id) ON DELETE CASCADE;


--
-- Name: familia_areas familia_areas_area_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_areas
    ADD CONSTRAINT familia_areas_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id) ON DELETE CASCADE;


--
-- Name: familia_areas familia_areas_familia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_areas
    ADD CONSTRAINT familia_areas_familia_id_fkey FOREIGN KEY (familia_id) REFERENCES public.familias(id) ON DELETE CASCADE;


--
-- Name: familia_setores familia_setores_familia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_setores
    ADD CONSTRAINT familia_setores_familia_id_fkey FOREIGN KEY (familia_id) REFERENCES public.familias(id) ON DELETE CASCADE;


--
-- Name: familia_setores familia_setores_setor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.familia_setores
    ADD CONSTRAINT familia_setores_setor_id_fkey FOREIGN KEY (setor_id) REFERENCES public.setores(id) ON DELETE CASCADE;


--
-- Name: faturas_entrada faturas_entrada_fornecedor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.faturas_entrada
    ADD CONSTRAINT faturas_entrada_fornecedor_id_fkey FOREIGN KEY (fornecedor_id) REFERENCES public.fornecedores(id) ON DELETE RESTRICT;


--
-- Name: itens_fatura_entrada itens_fatura_entrada_fatura_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_fatura_entrada
    ADD CONSTRAINT itens_fatura_entrada_fatura_id_fkey FOREIGN KEY (fatura_id) REFERENCES public.faturas_entrada(id) ON DELETE CASCADE;


--
-- Name: itens_fatura_entrada itens_fatura_entrada_produto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_fatura_entrada
    ADD CONSTRAINT itens_fatura_entrada_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES public.produtos(id) ON DELETE RESTRICT;


--
-- Name: itens_pedido itens_pedido_pedido_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT itens_pedido_pedido_id_fkey FOREIGN KEY (pedido_id) REFERENCES public.pedidos(id) ON DELETE CASCADE;


--
-- Name: itens_pedido itens_pedido_produto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_pedido
    ADD CONSTRAINT itens_pedido_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES public.produtos(id) ON DELETE RESTRICT;


--
-- Name: itens_venda itens_venda_produto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_venda
    ADD CONSTRAINT itens_venda_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES public.produtos(id);


--
-- Name: itens_venda itens_venda_venda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.itens_venda
    ADD CONSTRAINT itens_venda_venda_id_fkey FOREIGN KEY (venda_id) REFERENCES public.vendas(id) ON DELETE CASCADE;


--
-- Name: logs_acesso logs_acesso_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs_acesso
    ADD CONSTRAINT logs_acesso_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: mesas mesas_local_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mesas
    ADD CONSTRAINT mesas_local_id_fkey FOREIGN KEY (local_id) REFERENCES public.locais_mesa(id) ON DELETE RESTRICT;


--
-- Name: pagamentos_divida pagamentos_divida_divida_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_divida
    ADD CONSTRAINT pagamentos_divida_divida_id_fkey FOREIGN KEY (divida_id) REFERENCES public.dividas(id) ON DELETE CASCADE;


--
-- Name: pagamentos_divida pagamentos_divida_forma_pagamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_divida
    ADD CONSTRAINT pagamentos_divida_forma_pagamento_id_fkey FOREIGN KEY (forma_pagamento_id) REFERENCES public.formas_pagamento(id);


--
-- Name: pagamentos_venda pagamentos_venda_forma_pagamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_venda
    ADD CONSTRAINT pagamentos_venda_forma_pagamento_id_fkey FOREIGN KEY (forma_pagamento_id) REFERENCES public.formas_pagamento(id);


--
-- Name: pagamentos_venda pagamentos_venda_venda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pagamentos_venda
    ADD CONSTRAINT pagamentos_venda_venda_id_fkey FOREIGN KEY (venda_id) REFERENCES public.vendas(id) ON DELETE CASCADE;


--
-- Name: pedidos pedidos_mesa_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_mesa_id_fkey FOREIGN KEY (mesa_id) REFERENCES public.mesas(id) ON DELETE RESTRICT;


--
-- Name: pedidos pedidos_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pedidos
    ADD CONSTRAINT pedidos_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE RESTRICT;


--
-- Name: perfil_permissoes perfil_permissoes_perfil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissoes
    ADD CONSTRAINT perfil_permissoes_perfil_id_fkey FOREIGN KEY (perfil_id) REFERENCES public.perfis_usuario(id) ON DELETE CASCADE;


--
-- Name: perfil_permissoes perfil_permissoes_permissao_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.perfil_permissoes
    ADD CONSTRAINT perfil_permissoes_permissao_id_fkey FOREIGN KEY (permissao_id) REFERENCES public.permissoes(id) ON DELETE CASCADE;


--
-- Name: produto_composicao produto_composicao_produto_componente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_composicao
    ADD CONSTRAINT produto_composicao_produto_componente_id_fkey FOREIGN KEY (produto_componente_id) REFERENCES public.produtos(id) ON DELETE CASCADE;


--
-- Name: produto_composicao produto_composicao_produto_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produto_composicao
    ADD CONSTRAINT produto_composicao_produto_id_fkey FOREIGN KEY (produto_id) REFERENCES public.produtos(id) ON DELETE CASCADE;


--
-- Name: produtos produtos_area_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_area_id_fkey FOREIGN KEY (area_id) REFERENCES public.areas(id);


--
-- Name: produtos produtos_familia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_familia_id_fkey FOREIGN KEY (familia_id) REFERENCES public.familias(id) ON DELETE SET NULL;


--
-- Name: produtos produtos_setor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.produtos
    ADD CONSTRAINT produtos_setor_id_fkey FOREIGN KEY (setor_id) REFERENCES public.setores(id);


--
-- Name: terminal_logs terminal_logs_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminal_logs
    ADD CONSTRAINT terminal_logs_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminais(id) ON DELETE CASCADE;


--
-- Name: terminal_logs terminal_logs_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.terminal_logs
    ADD CONSTRAINT terminal_logs_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id) ON DELETE SET NULL;


--
-- Name: usuarios usuarios_perfil_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_perfil_id_fkey FOREIGN KEY (perfil_id) REFERENCES public.perfis_usuario(id) ON DELETE RESTRICT;


--
-- Name: usuarios usuarios_terminal_id_atual_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_terminal_id_atual_fkey FOREIGN KEY (terminal_id_atual) REFERENCES public.terminais(id) ON DELETE SET NULL;


--
-- Name: vendas vendas_cliente_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT vendas_cliente_id_fkey FOREIGN KEY (cliente_id) REFERENCES public.clientes(id);


--
-- Name: vendas vendas_forma_pagamento_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT vendas_forma_pagamento_id_fkey FOREIGN KEY (forma_pagamento_id) REFERENCES public.formas_pagamento(id);


--
-- Name: vendas vendas_terminal_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vendas
    ADD CONSTRAINT vendas_terminal_id_fkey FOREIGN KEY (terminal_id) REFERENCES public.terminais(id) ON DELETE SET NULL;




-- =====================================================
-- DADOS INICIAIS ESSENCIAIS
-- =====================================================

-- Perfis de usuário
-- Inserir perfis apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Super Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Super Administrador', 'Acesso total ao sistema');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Administrador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Administrador', 'Administrador com acesso a relatórios e configurações');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Gerente') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Gerente', 'Gerente com acesso a relatórios');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Operador') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Operador', 'Operador de caixa básico');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM perfis_usuario WHERE nome = 'Vendedor') THEN
        INSERT INTO perfis_usuario (nome, descricao) VALUES ('Vendedor', 'Vendedor sem acesso administrativo');
    END IF;
END $$;

-- Permissões do sistema
INSERT INTO permissoes (codigo, nome, categoria, descricao) VALUES
    -- Vendas
    ('efectuar_pagamento', 'Efectuar Pagamento', 'VENDAS', 'Permitir processar pagamentos de vendas'),
    ('fechar_caixa', 'Fechar Caixa', 'VENDAS', 'Permitir fechar o caixa'),
    ('cancelar_venda', 'Cancelar Venda', 'VENDAS', 'Permitir cancelar vendas'),
    ('imprimir_conta', 'Imprimir Conta', 'VENDAS', 'Permitir imprimir contas'),

    -- Stock
    ('entrada_stock', 'Entrada de Stock', 'STOCK', 'Permitir registar entradas de stock'),
    ('acerto_stock', 'Acerto de Stock', 'STOCK', 'Permitir fazer acertos de stock'),
    ('ver_stock', 'Ver Stock', 'STOCK', 'Permitir visualizar stock'),
    ('gestao_faturas', 'Gestão de Faturas', 'STOCK', 'Permitir visualizar e editar faturas de entrada'),

    -- Cadastros
    ('gestao_produtos', 'Gestão de Produtos', 'CADASTROS', 'Permitir criar e editar produtos'),
    ('gestao_familias', 'Gestão de Famílias', 'CADASTROS', 'Permitir criar e editar famílias'),
    ('gestao_clientes', 'Gestão de Clientes', 'CADASTROS', 'Permitir criar e editar clientes'),
    ('gestao_fornecedores', 'Gestão de Fornecedores', 'CADASTROS', 'Permitir criar e editar fornecedores'),
    ('gestao_setores', 'Gestão de Setores', 'CADASTROS', 'Permitir criar e editar setores'),
    ('gestao_areas', 'Gestão de Áreas', 'CADASTROS', 'Permitir criar e editar áreas'),

    -- Financeiro
    ('gestao_despesas', 'Gestão de Despesas', 'FINANCEIRO', 'Permitir criar e editar despesas'),
    ('gestao_dividas', 'Gestão de Dívidas', 'FINANCEIRO', 'Permitir registar e gerenciar dívidas'),
    ('gestao_pagamentos', 'Gestão de Formas de Pagamento', 'FINANCEIRO', 'Permitir configurar formas de pagamento'),

    -- Relatórios
    ('visualizar_relatorios', 'Visualizar Relatórios', 'RELATORIOS', 'Permitir visualizar relatórios gerais'),
    ('visualizar_margens', 'Visualizar Margens', 'RELATORIOS', 'Permitir visualizar margens e lucros'),
    ('visualizar_stock', 'Visualizar Relatório de Stock', 'RELATORIOS', 'Permitir visualizar relatório de stock'),

    -- Administração
    ('acesso_admin', 'Acesso Administração', 'ADMIN', 'Permitir acesso ao módulo de administração'),
    ('gestao_usuarios', 'Gestão de Usuários', 'ADMIN', 'Permitir criar e editar usuários'),
    ('gestao_perfis', 'Gestão de Perfis', 'ADMIN', 'Permitir criar e editar perfis'),
    ('gestao_permissoes', 'Gestão de Permissões', 'ADMIN', 'Permitir configurar permissões por perfil'),
    ('configuracoes_sistema', 'Configurações do Sistema', 'ADMIN', 'Permitir alterar configurações gerais'),
    ('gestao_empresa', 'Gestão de Empresa', 'ADMIN', 'Permitir editar dados da empresa'),
    ('gestao_mesas', 'Gestão de Mesas', 'ADMIN', 'Permitir criar e editar mesas')
ON CONFLICT (codigo) DO UPDATE SET nome = EXCLUDED.nome;

-- Dar todas as permissões ao Super Administrador e Administrador
-- Usar INSERT apenas se não existir
INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'),
    p.id
FROM permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador')
      AND pp.permissao_id = p.id
  );

INSERT INTO perfil_permissoes (perfil_id, permissao_id)
SELECT
    (SELECT id FROM perfis_usuario WHERE nome = 'Administrador'),
    p.id
FROM permissoes p
WHERE p.ativo = true
  AND NOT EXISTS (
    SELECT 1 FROM perfil_permissoes pp
    WHERE pp.perfil_id = (SELECT id FROM perfis_usuario WHERE nome = 'Administrador')
      AND pp.permissao_id = p.id
  );

-- USUÁRIO SUPER ADMINISTRADOR PADRÃO
-- Nome: Admin
-- Código: 0000
-- Inserir usuário Admin apenas se não existir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE codigo = '0000') THEN
        INSERT INTO usuarios (nome, codigo, perfil_id)
        VALUES ('Admin', '0000', (SELECT id FROM perfis_usuario WHERE nome = 'Super Administrador'));
    ELSE
        UPDATE usuarios SET nome = 'Admin', ativo = true WHERE codigo = '0000';
    END IF;
END $$;

-- Formas de pagamento padrão
-- Inserir formas de pagamento apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Dinheiro') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Dinheiro', 'CASH');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Emola') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Emola', 'EMOLA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'M-Pesa') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('M-Pesa', 'MPESA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'POS/Cartão') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('POS/Cartão', 'POS');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Transferência') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Transferência', 'TRANSFERENCIA');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM formas_pagamento WHERE nome = 'Crédito') THEN
        INSERT INTO formas_pagamento (nome, tipo) VALUES ('Crédito', 'CREDITO');
    END IF;
END $$;

-- Famílias de produtos padrão
-- Inserir famílias apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'BEBIDAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('BEBIDAS', 'Bebidas em geral');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'COMIDAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('COMIDAS', 'Pratos e lanches');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'SOBREMESAS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('SOBREMESAS', 'Doces e sobremesas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'PETISCOS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('PETISCOS', 'Petiscos e aperitivos');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM familias WHERE nome = 'OUTROS') THEN
        INSERT INTO familias (nome, descricao) VALUES ('OUTROS', 'Outros produtos');
    END IF;
END $$;

-- Setores padrão
-- Inserir setores apenas se não existirem
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'BAR') THEN
        INSERT INTO setores (nome, descricao) VALUES ('BAR', 'Bar e bebidas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'COZINHA') THEN
        INSERT INTO setores (nome, descricao) VALUES ('COZINHA', 'Cozinha e pratos quentes');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'CONFEITARIA') THEN
        INSERT INTO setores (nome, descricao) VALUES ('CONFEITARIA', 'Doces e sobremesas');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM setores WHERE nome = 'DIVERSOS') THEN
        INSERT INTO setores (nome, descricao) VALUES ('DIVERSOS', 'Produtos diversos');
    END IF;
END $$;

-- =====================================================
-- FIM DOS DADOS INICIAIS
-- =====================================================

SELECT 'BASE DE DADOS CRIADA COM SUCESSO!' as status;
SELECT COUNT(*) || ' tabelas criadas' as info FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';


-- Completed on 2025-12-06 22:09:56

--
-- PostgreSQL database dump complete
--


