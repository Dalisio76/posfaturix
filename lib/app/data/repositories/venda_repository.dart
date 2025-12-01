import 'package:get/get.dart';
import 'package:postgres/postgres.dart';
import '../../../core/database/database_service.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../models/pagamento_venda_model.dart';

class VendaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<ItemVendaModel>> buscarItensPorVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT iv.*, p.nome as produto_nome
      FROM itens_venda iv
      LEFT JOIN produtos p ON iv.produto_id = p.id
      WHERE iv.venda_id = @venda_id
      ORDER BY iv.id
    ''', parameters: {'venda_id': vendaId});

    return result.map((map) => ItemVendaModel.fromMap(map)).toList();
  }

  Future<int> registrarVenda(
    VendaModel venda,
    List<ItemVendaModel> itens,
    List<PagamentoVendaModel> pagamentos,
  ) async {
    return await _db.transaction((conn) async {
      // 1. Inserir venda
      final vendaResult = await conn.execute(
        Sql.named('''
          INSERT INTO vendas (numero, total, terminal)
          VALUES (@numero, @total, @terminal)
          RETURNING id
        '''),
        parameters: {
          'numero': venda.numero,
          'total': venda.total,
          'terminal': venda.terminal,
        },
      );

      final vendaId = vendaResult.first[0] as int;

      // 2. Inserir itens
      for (var item in itens) {
        await conn.execute(
          Sql.named('''
            INSERT INTO itens_venda (venda_id, produto_id, quantidade, preco_unitario, subtotal)
            VALUES (@venda_id, @produto_id, @quantidade, @preco_unitario, @subtotal)
          '''),
          parameters: {
            'venda_id': vendaId,
            'produto_id': item.produtoId,
            'quantidade': item.quantidade,
            'preco_unitario': item.precoUnitario,
            'subtotal': item.subtotal,
          },
        );

        // 3. Abater estoque (considera composição automaticamente)
        await conn.execute(
          Sql.named('''
            SELECT abater_estoque_produto(@produto_id, @quantidade)
          '''),
          parameters: {
            'produto_id': item.produtoId,
            'quantidade': item.quantidade,
          },
        );
      }

      // 4. Inserir pagamentos
      for (var pagamento in pagamentos) {
        await conn.execute(
          Sql.named('''
            INSERT INTO pagamentos_venda (venda_id, forma_pagamento_id, valor)
            VALUES (@venda_id, @forma_pagamento_id, @valor)
          '''),
          parameters: {
            'venda_id': vendaId,
            'forma_pagamento_id': pagamento.formaPagamentoId,
            'valor': pagamento.valor,
          },
        );
      }

      return vendaId;
    });
  }

  Future<List<VendaModel>> listarVendas({DateTime? dataInicio, DateTime? dataFim}) async {
    String sql = 'SELECT * FROM vendas WHERE 1=1';
    Map<String, dynamic> params = {};

    if (dataInicio != null) {
      sql += ' AND data_venda >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      sql += ' AND data_venda <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }

    sql += ' ORDER BY data_venda DESC';

    final result = await _db.query(sql, parameters: params);
    return result.map((map) => VendaModel.fromMap(map)).toList();
  }

  Future<List<VendaModel>> listarTodasVendas({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
    String? numeroFiltro,
  }) async {
    String sql = '''
      SELECT
        v.*,
        c.nome as cliente_nome,
        u.nome as usuario_nome
      FROM vendas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN usuarios u ON v.usuario_id = u.id
      WHERE 1=1
    ''';
    Map<String, dynamic> params = {};

    if (dataInicio != null) {
      sql += ' AND v.data_venda >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      sql += ' AND v.data_venda <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }

    if (status != null && status.isNotEmpty) {
      sql += ' AND v.status = @status';
      params['status'] = status;
    }

    if (numeroFiltro != null && numeroFiltro.isNotEmpty) {
      sql += ' AND v.numero ILIKE @numero';
      params['numero'] = '%$numeroFiltro%';
    }

    sql += ' ORDER BY v.data_venda DESC';

    final result = await _db.query(sql, parameters: params);
    return result.map((map) => VendaModel.fromMap(map)).toList();
  }

  Future<List<ItemVendaModel>> listarItensVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT iv.*, p.nome as produto_nome
      FROM itens_venda iv
      LEFT JOIN produtos p ON iv.produto_id = p.id
      WHERE iv.venda_id = @venda_id
      ORDER BY iv.id
    ''', parameters: {'venda_id': vendaId});

    return result.map((map) => ItemVendaModel.fromMap(map)).toList();
  }

  Future<List<PagamentoVendaModel>> listarPagamentosVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT
        pv.*,
        fp.nome as forma_pagamento_nome
      FROM pagamentos_venda pv
      LEFT JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
      WHERE pv.venda_id = @venda_id
      ORDER BY pv.id
    ''', parameters: {'venda_id': vendaId});

    return result.map((map) => PagamentoVendaModel.fromMap(map)).toList();
  }

  Future<VendaModel?> buscarVendaPorId(int vendaId) async {
    final result = await _db.query('''
      SELECT
        v.*,
        c.nome as cliente_nome,
        u.nome as usuario_nome
      FROM vendas v
      LEFT JOIN clientes c ON v.cliente_id = c.id
      LEFT JOIN usuarios u ON v.usuario_id = u.id
      WHERE v.id = @venda_id
    ''', parameters: {'venda_id': vendaId});

    if (result.isEmpty) return null;
    return VendaModel.fromMap(result.first);
  }

  Future<void> cancelarVenda(int vendaId, int usuarioIdCancelamento) async {
    return await _db.transaction((conn) async {
      // 1. Verificar se venda existe e já não está cancelada
      final vendaResult = await conn.execute(
        Sql.named('SELECT status FROM vendas WHERE id = @venda_id'),
        parameters: {'venda_id': vendaId},
      );

      if (vendaResult.isEmpty) {
        throw Exception('Venda não encontrada');
      }

      final statusAtual = vendaResult.first[0] as String?;
      if (statusAtual == 'cancelada') {
        throw Exception('Venda já está cancelada');
      }

      // 2. Buscar itens da venda para restaurar estoque
      final itensResult = await conn.execute(
        Sql.named('''
          SELECT produto_id, quantidade
          FROM itens_venda
          WHERE venda_id = @venda_id
        '''),
        parameters: {'venda_id': vendaId},
      );

      // 3. Restaurar estoque de cada produto
      for (final item in itensResult) {
        final produtoId = item[0] as int;
        final quantidade = item[1] as int;

        await conn.execute(
          Sql.named('''
            UPDATE produtos
            SET estoque = estoque + @quantidade
            WHERE id = @produto_id
          '''),
          parameters: {
            'produto_id': produtoId,
            'quantidade': quantidade,
          },
        );
      }

      // 4. Atualizar status da venda para cancelada
      await conn.execute(
        Sql.named('''
          UPDATE vendas
          SET
            status = 'cancelada',
            observacoes = COALESCE(observacoes || E'\n', '') || 'Cancelada em ' || NOW()::TEXT || ' por usuário ID ' || @usuario_id::TEXT
          WHERE id = @venda_id
        '''),
        parameters: {
          'venda_id': vendaId,
          'usuario_id': usuarioIdCancelamento,
        },
      );

      // 5. Registrar no log de auditoria (se existir tabela)
      try {
        await conn.execute(
          Sql.named('''
            INSERT INTO auditoria (
              usuario_id,
              tabela,
              operacao,
              registro_id,
              descricao,
              data_hora
            ) VALUES (
              @usuario_id,
              'vendas',
              'CANCELAMENTO',
              @venda_id,
              'Venda cancelada',
              NOW()
            )
          '''),
          parameters: {
            'usuario_id': usuarioIdCancelamento,
            'venda_id': vendaId,
          },
        );
      } catch (e) {
        // Tabela auditoria pode não existir - ignorar erro
        print('Aviso: Não foi possível registrar auditoria: $e');
      }
    });
  }
}
