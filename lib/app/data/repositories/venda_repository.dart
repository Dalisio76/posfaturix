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

        // 3. Atualizar estoque
        await conn.execute(
          Sql.named('''
            UPDATE produtos
            SET estoque = estoque - @quantidade
            WHERE id = @produto_id
          '''),
          parameters: {
            'quantidade': item.quantidade,
            'produto_id': item.produtoId,
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

  Future<List<ItemVendaModel>> listarItensVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT iv.*, p.nome as produto_nome
      FROM itens_venda iv
      LEFT JOIN produtos p ON iv.produto_id = p.id
      WHERE iv.venda_id = @venda_id
    ''', parameters: {'venda_id': vendaId});

    return result.map((map) => ItemVendaModel.fromMap(map)).toList();
  }
}
