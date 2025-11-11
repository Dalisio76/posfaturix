import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/despesa_model.dart';

class DespesaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<DespesaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT d.*, f.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento f ON d.forma_pagamento_id = f.id
      ORDER BY d.data_despesa DESC
    ''');

    return result.map((map) => DespesaModel.fromMap(map)).toList();
  }

  Future<List<DespesaModel>> listarPorCategoria(String categoria) async {
    final result = await _db.query('''
      SELECT d.*, f.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento f ON d.forma_pagamento_id = f.id
      WHERE d.categoria = @categoria
      ORDER BY d.data_despesa DESC
    ''', parameters: {'categoria': categoria});

    return result.map((map) => DespesaModel.fromMap(map)).toList();
  }

  Future<List<DespesaModel>> listarPorPeriodo(
      DateTime inicio, DateTime fim) async {
    final result = await _db.query('''
      SELECT d.*, f.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento f ON d.forma_pagamento_id = f.id
      WHERE d.data_despesa BETWEEN @inicio AND @fim
      ORDER BY d.data_despesa DESC
    ''', parameters: {
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
    });

    return result.map((map) => DespesaModel.fromMap(map)).toList();
  }

  Future<double> calcularTotalPorPeriodo(DateTime inicio, DateTime fim) async {
    final result = await _db.query('''
      SELECT COALESCE(SUM(valor), 0) as total
      FROM despesas
      WHERE data_despesa BETWEEN @inicio AND @fim
    ''', parameters: {
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
    });

    if (result.isEmpty) return 0;
    return double.parse(result.first['total'].toString());
  }

  Future<Map<String, double>> calcularTotalPorCategoria(
      DateTime inicio, DateTime fim) async {
    final result = await _db.query('''
      SELECT categoria, SUM(valor) as total
      FROM despesas
      WHERE data_despesa BETWEEN @inicio AND @fim
      GROUP BY categoria
      ORDER BY total DESC
    ''', parameters: {
      'inicio': inicio.toIso8601String(),
      'fim': fim.toIso8601String(),
    });

    final Map<String, double> totais = {};
    for (var row in result) {
      totais[row['categoria'] ?? 'SEM_CATEGORIA'] =
          double.parse(row['total'].toString());
    }
    return totais;
  }

  Future<DespesaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT d.*, f.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento f ON d.forma_pagamento_id = f.id
      WHERE d.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return DespesaModel.fromMap(result.first);
  }

  Future<int> inserir(DespesaModel despesa) async {
    return await _db.insert('''
      INSERT INTO despesas (descricao, valor, categoria, data_despesa, forma_pagamento_id, observacoes, usuario)
      VALUES (@descricao, @valor, @categoria, @data_despesa, @forma_pagamento_id, @observacoes, @usuario)
    ''', parameters: despesa.toMap());
  }

  Future<void> atualizar(int id, DespesaModel despesa) async {
    await _db.execute('''
      UPDATE despesas
      SET descricao = @descricao,
          valor = @valor,
          categoria = @categoria,
          data_despesa = @data_despesa,
          forma_pagamento_id = @forma_pagamento_id,
          observacoes = @observacoes,
          usuario = @usuario
      WHERE id = @id
    ''', parameters: {
      ...despesa.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM despesas WHERE id = @id
    ''', parameters: {'id': id});
  }
}
