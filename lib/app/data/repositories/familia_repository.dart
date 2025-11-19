import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/familia_model.dart';

class FamiliaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<FamiliaModel>> listarTodas() async {
    final result = await _db.query('''
      SELECT * FROM v_familias_com_setores
      ORDER BY nome
    ''');

    return result.map((map) => FamiliaModel.fromMap(map)).toList();
  }

  Future<FamiliaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_familias_com_setores
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return FamiliaModel.fromMap(result.first);
  }

  Future<int> inserir(FamiliaModel familia, List<int> setorIds) async {
    // 1. Inserir a família
    final familiaId = await _db.insert('''
      INSERT INTO familias (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: familia.toMap());

    // 2. Associar setores
    if (setorIds.isNotEmpty) {
      await associarSetores(familiaId, setorIds);
    }

    return familiaId;
  }

  Future<void> atualizar(int id, FamiliaModel familia, List<int> setorIds) async {
    // 1. Atualizar a família
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

    // 2. Remover setores antigos e adicionar novos
    await _db.execute('''
      DELETE FROM familia_setores WHERE familia_id = @id
    ''', parameters: {'id': id});

    if (setorIds.isNotEmpty) {
      await associarSetores(id, setorIds);
    }
  }

  Future<void> associarSetores(int familiaId, List<int> setorIds) async {
    for (final setorId in setorIds) {
      await _db.execute('''
        INSERT INTO familia_setores (familia_id, setor_id)
        VALUES (@familia_id, @setor_id)
        ON CONFLICT (familia_id, setor_id) DO NOTHING
      ''', parameters: {
        'familia_id': familiaId,
        'setor_id': setorId,
      });
    }
  }

  Future<void> desassociarSetor(int familiaId, int setorId) async {
    await _db.execute('''
      DELETE FROM familia_setores
      WHERE familia_id = @familia_id AND setor_id = @setor_id
    ''', parameters: {
      'familia_id': familiaId,
      'setor_id': setorId,
    });
  }

  Future<List<int>> buscarSetoresDaFamilia(int familiaId) async {
    final result = await _db.query('''
      SELECT setor_id FROM familia_setores
      WHERE familia_id = @familia_id
      ORDER BY setor_id
    ''', parameters: {'familia_id': familiaId});

    return result.map((map) => map['setor_id'] as int).toList();
  }

  Future<void> deletar(int id) async {
    // Soft delete
    await _db.execute('''
      UPDATE familias SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
