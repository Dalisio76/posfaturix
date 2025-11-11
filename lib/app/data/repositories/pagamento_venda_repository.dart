import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/pagamento_venda_model.dart';

class PagamentoVendaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<PagamentoVendaModel>> listarPorVenda(int vendaId) async {
    final result = await _db.query('''
      SELECT pv.*, fp.nome as forma_pagamento_nome
      FROM pagamentos_venda pv
      LEFT JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
      WHERE pv.venda_id = @venda_id
      ORDER BY pv.id
    ''', parameters: {'venda_id': vendaId});

    return result.map((map) => PagamentoVendaModel.fromMap(map)).toList();
  }

  Future<int> inserir(PagamentoVendaModel pagamento) async {
    return await _db.insert('''
      INSERT INTO pagamentos_venda (venda_id, forma_pagamento_id, valor)
      VALUES (@venda_id, @forma_pagamento_id, @valor)
    ''', parameters: pagamento.toMap());
  }

  Future<void> deletarPorVenda(int vendaId) async {
    await _db.execute('''
      DELETE FROM pagamentos_venda WHERE venda_id = @venda_id
    ''', parameters: {'venda_id': vendaId});
  }
}
