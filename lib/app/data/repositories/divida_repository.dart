import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/divida_model.dart';

class DividaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<DividaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      ORDER BY data_divida DESC
    ''');

    return result.map((map) => DividaModel.fromMap(map)).toList();
  }

  Future<List<DividaModel>> listarPorCliente(int clienteId) async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      WHERE cliente_id = @cliente_id
      ORDER BY data_divida DESC
    ''', parameters: {'cliente_id': clienteId});

    return result.map((map) => DividaModel.fromMap(map)).toList();
  }

  Future<List<DividaModel>> listarPendentes() async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      WHERE status != 'PAGO'
      ORDER BY data_divida DESC
    ''');

    return result.map((map) => DividaModel.fromMap(map)).toList();
  }

  Future<DividaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return DividaModel.fromMap(result.first);
  }

  Future<DividaModel?> buscarPorVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      WHERE venda_id = @venda_id
    ''', parameters: {'venda_id': vendaId});

    if (result.isEmpty) return null;
    return DividaModel.fromMap(result.first);
  }

  Future<int> inserir(DividaModel divida) async {
    return await _db.insert('''
      INSERT INTO dividas (cliente_id, venda_id, valor_total, valor_pago, valor_restante, status, observacoes, data_divida, data_vencimento)
      VALUES (@cliente_id, @venda_id, @valor_total, @valor_pago, @valor_restante, @status, @observacoes, @data_divida, @data_vencimento)
    ''', parameters: divida.toMap());
  }

  Future<void> atualizar(int id, DividaModel divida) async {
    await _db.execute('''
      UPDATE dividas
      SET cliente_id = @cliente_id,
          venda_id = @venda_id,
          valor_total = @valor_total,
          valor_pago = @valor_pago,
          valor_restante = @valor_restante,
          status = @status,
          observacoes = @observacoes,
          data_divida = @data_divida,
          data_vencimento = @data_vencimento
      WHERE id = @id
    ''', parameters: {
      ...divida.toMap(),
      'id': id,
    });
  }

  Future<bool> registrarPagamento(
    int dividaId,
    double valor,
    int? formaPagamentoId,
    String? observacoes,
    String? usuario,
  ) async {
    try {
      await _db.query('''
        SELECT registrar_pagamento_divida(@divida_id, @valor, @forma_pagamento_id, @observacoes, @usuario)
      ''', parameters: {
        'divida_id': dividaId,
        'valor': valor,
        'forma_pagamento_id': formaPagamentoId,
        'observacoes': observacoes,
        'usuario': usuario,
      });
      return true;
    } catch (e) {
      print('Erro ao registrar pagamento: $e');
      return false;
    }
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM dividas WHERE id = @id
    ''', parameters: {'id': id});
  }
}
