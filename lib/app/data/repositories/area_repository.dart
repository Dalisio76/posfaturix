import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/area_model.dart';

class AreaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<AreaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM areas
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => AreaModel.fromMap(map)).toList();
  }

  Future<AreaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM areas WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return AreaModel.fromMap(result.first);
  }

  Future<int> inserir(AreaModel area) async {
    return await _db.insert('''
      INSERT INTO areas (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: area.toMap());
  }

  Future<void> atualizar(int id, AreaModel area) async {
    await _db.execute('''
      UPDATE areas
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...area.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE areas SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
