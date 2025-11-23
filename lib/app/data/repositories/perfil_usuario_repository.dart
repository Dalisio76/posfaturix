import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/perfil_usuario_model.dart';

class PerfilUsuarioRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Listar todos os perfis
  Future<List<PerfilUsuarioModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM perfis_usuario
      ORDER BY nome
    ''');
    return result.map((map) => PerfilUsuarioModel.fromMap(map)).toList();
  }

  /// Listar apenas perfis ativos
  Future<List<PerfilUsuarioModel>> listarAtivos() async {
    final result = await _db.query('''
      SELECT * FROM perfis_usuario
      WHERE ativo = true
      ORDER BY nome
    ''');
    return result.map((map) => PerfilUsuarioModel.fromMap(map)).toList();
  }

  /// Buscar perfil por ID
  Future<PerfilUsuarioModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM perfis_usuario
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return PerfilUsuarioModel.fromMap(result.first);
  }

  /// Inserir novo perfil
  Future<int> inserir(PerfilUsuarioModel perfil) async {
    final result = await _db.query('''
      INSERT INTO perfis_usuario (nome, descricao, ativo)
      VALUES (@nome, @descricao, @ativo)
      RETURNING id
    ''', parameters: perfil.toMap());

    return result.first['id'];
  }

  /// Atualizar perfil
  Future<void> atualizar(PerfilUsuarioModel perfil) async {
    await _db.query('''
      UPDATE perfis_usuario
      SET nome = @nome,
          descricao = @descricao,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...perfil.toMap(),
      'id': perfil.id,
    });
  }

  /// Deletar perfil
  Future<void> deletar(int id) async {
    await _db.query('''
      DELETE FROM perfis_usuario
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  /// Pesquisar perfis por nome
  Future<List<PerfilUsuarioModel>> pesquisar(String termo) async {
    final result = await _db.query('''
      SELECT * FROM perfis_usuario
      WHERE nome ILIKE @termo
      ORDER BY nome
    ''', parameters: {'termo': '%$termo%'});

    return result.map((map) => PerfilUsuarioModel.fromMap(map)).toList();
  }
}
