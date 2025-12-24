-- Correção da view v_produtos_completo para incluir codigo_barras
-- Execute este script no PostgreSQL para corrigir o problema do código de barras que desaparece

DROP VIEW IF EXISTS public.v_produtos_completo;

CREATE VIEW public.v_produtos_completo AS
SELECT p.id,
    p.codigo,
    p.nome,
    p.codigo_barras,
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

COMMENT ON VIEW public.v_produtos_completo IS 'View completa de produtos com informações de família, setor, área e código de barras';
