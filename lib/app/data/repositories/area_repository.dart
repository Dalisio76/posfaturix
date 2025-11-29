import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/area_model.dart';

class AreaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<AreaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT a.*, i.nome as impressora_nome
      FROM areas a
      LEFT JOIN impressoras i ON i.id = a.impressora_id
      WHERE a.ativo = true
      ORDER BY a.nome
    ''');

    return result.map((map) => AreaModel.fromMap(map)).toList();
  }

  Future<AreaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT a.*, i.nome as impressora_nome
      FROM areas a
      LEFT JOIN impressoras i ON i.id = a.impressora_id
      WHERE a.id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return AreaModel.fromMap(result.first);
  }

  Future<int> inserir(AreaModel area) async {
    return await _db.insert('''
      INSERT INTO areas (nome, descricao, ativo, impressora_id)
      VALUES (@nome, @descricao, @ativo, @impressora_id)
    ''', parameters: area.toMap());
  }

  Future<void> atualizar(int id, AreaModel area) async {
    await _db.execute('''
      UPDATE areas
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo,
          impressora_id = @impressora_id
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
