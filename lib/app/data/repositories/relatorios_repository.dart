import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/caixa_model.dart';

class RelatoriosRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  // Listar todas as caixas (abertas e fechadas)
  Future<List<CaixaModel>> listarTodasCaixas() async {
    final result = await _db.query('''
      SELECT * FROM v_resumo_caixa
      ORDER BY data_abertura DESC
    ''');

    return result.map((map) => CaixaModel.fromMap(map)).toList();
  }

  // Listar apenas caixas abertas
  Future<List<CaixaModel>> listarCaixasAbertas() async {
    final result = await _db.query('''
      SELECT * FROM v_resumo_caixa
      WHERE status = 'ABERTO'
      ORDER BY data_abertura DESC
    ''');

    return result.map((map) => CaixaModel.fromMap(map)).toList();
  }

  // Listar apenas caixas fechadas
  Future<List<CaixaModel>> listarCaixasFechadas({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    String sql = '''
      SELECT * FROM v_resumo_caixa
      WHERE status = 'FECHADO'
    ''';

    Map<String, dynamic> params = {};

    if (dataInicio != null) {
      sql += ' AND data_fechamento >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      sql += ' AND data_fechamento <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }

    sql += ' ORDER BY data_fechamento DESC';

    final result = await _db.query(sql, parameters: params);
    return result.map((map) => CaixaModel.fromMap(map)).toList();
  }

  // Buscar detalhes de uma caixa específica
  Future<CaixaModel?> buscarCaixaPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_resumo_caixa
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return CaixaModel.fromMap(result.first);
  }

  // Buscar produtos vendidos em uma caixa específica
  Future<List<Map<String, dynamic>>> buscarProdutosVendidosCaixa(int caixaId) async {
    final result = await _db.query('''
      SELECT * FROM v_produtos_vendidos_caixa
      WHERE caixa_id = @caixa_id
      ORDER BY total_vendido DESC
    ''', parameters: {'caixa_id': caixaId});

    return result;
  }

  // Buscar despesas de uma caixa específica
  Future<List<Map<String, dynamic>>> buscarDespesasCaixa(int caixaId) async {
    final result = await _db.query('''
      SELECT * FROM v_despesas_caixa
      WHERE caixa_id = @caixa_id
      ORDER BY data_despesa DESC
    ''', parameters: {'caixa_id': caixaId});

    return result;
  }

  // Buscar pagamentos de dívidas em uma caixa específica
  Future<List<Map<String, dynamic>>> buscarPagamentosDividaCaixa(int caixaId) async {
    final result = await _db.query('''
      SELECT * FROM v_pagamentos_divida_caixa
      WHERE caixa_id = @caixa_id
      ORDER BY data_pagamento DESC
    ''', parameters: {'caixa_id': caixaId});

    return result;
  }

  // Buscar resumo de produtos vendidos (agregado) em uma caixa
  Future<List<Map<String, dynamic>>> buscarResumoProdutosCaixa(int caixaId) async {
    final result = await _db.query('''
      SELECT * FROM v_resumo_produtos_caixa
      WHERE caixa_id = @caixa_id
      ORDER BY total_vendido DESC
    ''', parameters: {'caixa_id': caixaId});

    return result;
  }

  // Buscar dados agregados por período de datas
  Future<Map<String, dynamic>> buscarDadosPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    // Buscar todas as vendas no período
    final vendas = await _db.query('''
      SELECT
        COUNT(*) as total_vendas,
        SUM(CASE WHEN tipo_venda = 'NORMAL' OR tipo_venda IS NULL THEN total ELSE 0 END) as total_vendas_pagas,
        SUM(CASE WHEN tipo_venda = 'DIVIDA' THEN total ELSE 0 END) as total_vendas_credito
      FROM vendas
      WHERE data_venda >= @data_inicio
        AND data_venda <= @data_fim
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    // Buscar formas de pagamento no período
    final formasPagamento = await _db.query('''
      SELECT
        fp.nome as forma_pagamento,
        SUM(pv.valor) as total,
        COUNT(*) as quantidade
      FROM pagamentos_venda pv
      INNER JOIN vendas v ON pv.venda_id = v.id
      INNER JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
      WHERE v.data_venda >= @data_inicio
        AND v.data_venda <= @data_fim
      GROUP BY fp.nome
      ORDER BY total DESC
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    // Buscar pagamentos de dívidas no período
    final dividasPagas = await _db.query('''
      SELECT
        COALESCE(SUM(valor), 0) as total_dividas_pagas,
        COUNT(*) as qtd_dividas_pagas
      FROM pagamentos_divida
      WHERE data_pagamento >= @data_inicio
        AND data_pagamento <= @data_fim
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    // Buscar despesas no período
    final despesas = await _db.query('''
      SELECT
        COALESCE(SUM(valor), 0) as total_despesas,
        COUNT(*) as qtd_despesas
      FROM despesas
      WHERE data_despesa >= @data_inicio
        AND data_despesa <= @data_fim
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    return {
      'vendas': vendas.isNotEmpty ? vendas.first : {},
      'formas_pagamento': formasPagamento,
      'dividas_pagas': dividasPagas.isNotEmpty ? dividasPagas.first : {},
      'despesas': despesas.isNotEmpty ? despesas.first : {},
    };
  }

  // Buscar produtos vendidos por período
  Future<List<Map<String, dynamic>>> buscarProdutosPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final result = await _db.query('''
      SELECT
        p.nome as produto_nome,
        SUM(iv.quantidade) as quantidade_total,
        iv.preco_unitario,
        SUM(iv.subtotal) as total_vendido
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.data_venda >= @data_inicio
        AND v.data_venda <= @data_fim
        AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
      GROUP BY p.id, p.nome, iv.preco_unitario
      ORDER BY total_vendido DESC
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    return result;
  }

  // Buscar produtos agrupados por família para impressão
  Future<Map<String, List<Map<String, dynamic>>>> buscarProdutosPorFamiliaPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    final result = await _db.query('''
      SELECT
        COALESCE(f.nome, 'SEM FAMÍLIA') as familia_nome,
        p.nome as produto_nome,
        SUM(iv.quantidade) as quantidade_total,
        SUM(iv.subtotal) as total_vendido
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      LEFT JOIN familias f ON p.familia_id = f.id
      WHERE v.data_venda >= @data_inicio
        AND v.data_venda <= @data_fim
        AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
      GROUP BY f.nome, p.id, p.nome
      ORDER BY f.nome, total_vendido DESC
    ''', parameters: {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    });

    // Agrupar por família
    Map<String, List<Map<String, dynamic>>> produtosPorFamilia = {};

    for (var row in result) {
      final familia = row['familia_nome'] as String;
      if (!produtosPorFamilia.containsKey(familia)) {
        produtosPorFamilia[familia] = [];
      }
      produtosPorFamilia[familia]!.add(row);
    }

    return produtosPorFamilia;
  }

  // Buscar margens/lucros por período
  Future<List<Map<String, dynamic>>> buscarMargensPorPeriodo({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? produtoNome,
    int? setorId,
  }) async {
    String sql = '''
      SELECT
        p.id as produto_id,
        p.nome as designacao,
        SUM(iv.quantidade) as quantidade,
        SUM(iv.subtotal) as valor,
        SUM(iv.quantidade * p.preco_compra) as compra,
        SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_compra) as lucro,
        CASE
          WHEN SUM(iv.subtotal) > 0
          THEN ((SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_compra)) / SUM(iv.subtotal)) * 100
          ELSE 0
        END as percentagem,
        s.nome as setor
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      LEFT JOIN setores s ON p.setor_id = s.id
      WHERE v.data_venda >= @data_inicio
        AND v.data_venda <= @data_fim
        AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
    ''';

    Map<String, dynamic> params = {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    };

    if (produtoNome != null && produtoNome.isNotEmpty) {
      sql += ' AND LOWER(p.nome) LIKE @produto_nome';
      params['produto_nome'] = '%${produtoNome.toLowerCase()}%';
    }

    if (setorId != null) {
      sql += ' AND p.setor_id = @setor_id';
      params['setor_id'] = setorId;
    }

    sql += '''
      GROUP BY p.id, p.nome, s.nome
      ORDER BY lucro DESC
    ''';

    final result = await _db.query(sql, parameters: params);
    return result;
  }

  // Buscar resumo de margens (totais)
  Future<Map<String, dynamic>> buscarResumoMargens({
    required DateTime dataInicio,
    required DateTime dataFim,
    String? produtoNome,
    int? setorId,
  }) async {
    String sql = '''
      SELECT
        COALESCE(SUM(iv.subtotal), 0) as total_vendas,
        COALESCE(SUM(iv.quantidade * p.preco_compra), 0) as total_compra,
        COALESCE(SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_compra), 0) as total_lucro,
        CASE
          WHEN SUM(iv.subtotal) > 0
          THEN ((SUM(iv.subtotal) - SUM(iv.quantidade * p.preco_compra)) / SUM(iv.subtotal)) * 100
          ELSE 0
        END as percentagem_total
      FROM itens_venda iv
      INNER JOIN vendas v ON iv.venda_id = v.id
      INNER JOIN produtos p ON iv.produto_id = p.id
      WHERE v.data_venda >= @data_inicio
        AND v.data_venda <= @data_fim
        AND (v.tipo_venda = 'NORMAL' OR v.tipo_venda IS NULL)
    ''';

    Map<String, dynamic> params = {
      'data_inicio': dataInicio.toIso8601String(),
      'data_fim': dataFim.toIso8601String(),
    };

    if (produtoNome != null && produtoNome.isNotEmpty) {
      sql += ' AND LOWER(p.nome) LIKE @produto_nome';
      params['produto_nome'] = '%${produtoNome.toLowerCase()}%';
    }

    if (setorId != null) {
      sql += ' AND p.setor_id = @setor_id';
      params['setor_id'] = setorId;
    }

    final result = await _db.query(sql, parameters: params);
    return result.isNotEmpty ? result.first : {};
  }
}
