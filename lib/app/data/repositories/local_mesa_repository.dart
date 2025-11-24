import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/local_mesa_model.dart';

class LocalMesaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  Future<List<LocalMesaModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM locais_mesa
      WHERE ativo = true
      ORDER BY ordem, nome
    ''');

    return result.map((map) => LocalMesaModel.fromMap(map)).toList();
  }

  Future<LocalMesaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM locais_mesa WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return LocalMesaModel.fromMap(result.first);
  }

  Future<int> inserir(LocalMesaModel local) async {
    return await _db.insert('''
      INSERT INTO locais_mesa (nome, descricao, ordem, ativo)
      VALUES (@nome, @descricao, @ordem, @ativo)
    ''', parameters: local.toMap());
  }

  Future<void> atualizar(int id, LocalMesaModel local) async {
    await _db.execute('''
      UPDATE locais_mesa
      SET nome = @nome,
          descricao = @descricao,
          ordem = @ordem,
          ativo = @ativo
      WHERE id = @id
    ''', parameters: {
      ...local.toMap(),
      'id': id,
    });
  }

  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE locais_mesa SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
