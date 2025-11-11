import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/forma_pagamento_model.dart';

class FormaPagamentoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<FormaPagamentoModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM formas_pagamento
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => FormaPagamentoModel.fromMap(map)).toList();
  }

  Future<FormaPagamentoModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM formas_pagamento WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return FormaPagamentoModel.fromMap(result.first);
  }

  Future<int> inserir(FormaPagamentoModel forma) async {
    return await _db.insert('''
      INSERT INTO formas_pagamento (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: forma.toMap());
  }

  Future<void> atualizar(int id, FormaPagamentoModel forma) async {
    await _db.execute('''
      UPDATE formas_pagamento
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...forma.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE formas_pagamento SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
