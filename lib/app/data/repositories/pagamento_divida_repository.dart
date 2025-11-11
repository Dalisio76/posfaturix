import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/pagamento_divida_model.dart';

class PagamentoDividaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<PagamentoDividaModel>> listarPorDivida(int dividaId) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as forma_pagamento_nome
      FROM pagamentos_divida p
      LEFT JOIN formas_pagamento f ON p.forma_pagamento_id = f.id
      WHERE p.divida_id = @divida_id
      ORDER BY p.data_pagamento DESC
    ''', parameters: {'divida_id': dividaId});

    return result.map((map) => PagamentoDividaModel.fromMap(map)).toList();
  }

  Future<List<PagamentoDividaModel>> listarPorPeriodo(
      DateTime inicio, DateTime fim) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as forma_pagamento_nome
      FROM pagamentos_divida p
      LEFT JOIN formas_pagamento f ON p.forma_pagamento_id = f.id
      WHERE p.data_pagamento BETWEEN @inicio AND @fim
      ORDER BY p.data_pagamento DESC
    ''', parameters: {
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
    });

    return result.map((map) => PagamentoDividaModel.fromMap(map)).toList();
  }

  Future<double> calcularTotalPorDivida(int dividaId) async {
    final result = await _db.query('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM pagamentos_divida
      WHERE divida_id = @divida_id
    ''', parameters: {'divida_id': dividaId});

    if (result.isEmpty) return 0;
    return double.parse(result.first['total'].toString());
  }

  Future<PagamentoDividaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT p.*, f.nome as forma_pagamento_nome
      FROM pagamentos_divida p
      LEFT JOIN formas_pagamento f ON p.forma_pagamento_id = f.id
      WHERE p.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return PagamentoDividaModel.fromMap(result.first);
  }

  Future<int> inserir(PagamentoDividaModel pagamento) async {
    return await _db.insert('''
      INSERT INTO pagamentos_divida (divida_id, valor, forma_pagamento_id, data_pagamento, observacoes, usuario)
      VALUES (@divida_id, @valor, @forma_pagamento_id, @data_pagamento, @observacoes, @usuario)
    ''', parameters: pagamento.toMap());
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM pagamentos_divida WHERE id = @id
    ''', parameters: {'id': id});
  }
}
