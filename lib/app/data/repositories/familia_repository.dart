import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/familia_model.dart';

class FamiliaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<FamiliaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM familias
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => FamiliaModel.fromMap(map)).toList();
  }

  Future<FamiliaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM familias
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return FamiliaModel.fromMap(result.first);
  }

  Future<int> inserir(FamiliaModel familia) async {
    return await _db.insert('''
      INSERT INTO familias (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: familia.toMap());
  }

  Future<void> atualizar(int id, FamiliaModel familia) async {
    await _db.execute('''
      UPDATE familias
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...familia.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    // Soft delete
    await _db.execute('''
      UPDATE familias SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
