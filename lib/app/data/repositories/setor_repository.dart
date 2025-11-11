import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/setor_model.dart';

class SetorRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<SetorModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM setores
      WHERE ativo = true
      ORDER BY nome
    ''');

    return result.map((map) => SetorModel.fromMap(map)).toList();
  }

  Future<SetorModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM setores WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return SetorModel.fromMap(result.first);
  }

  Future<int> inserir(SetorModel setor) async {
    return await _db.insert('''
      INSERT INTO setores (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
    ''', parameters: setor.toMap());
  }

  Future<void> atualizar(int id, SetorModel setor) async {
    await _db.execute('''
      UPDATE setores
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...setor.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE setores SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
