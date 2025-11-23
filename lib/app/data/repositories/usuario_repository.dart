import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/usuario_model.dart';

class UsuarioRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Listar todos os usuários
  Future<List<UsuarioModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM v_usuarios_completo
      ORDER BY nome
    ''');
    return result.map((map) => UsuarioModel.fromMap(map)).toList();
  }

  /// Listar apenas usuários ativos
  Future<List<UsuarioModel>> listarAtivos() async {
    final result = await _db.query('''
      SELECT * FROM v_usuarios_completo
      WHERE ativo = true
      ORDER BY nome
    ''');
    return result.map((map) => UsuarioModel.fromMap(map)).toList();
  }

  /// Buscar usuário por ID
  Future<UsuarioModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_usuarios_completo
      WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return UsuarioModel.fromMap(result.first);
  }

  /// Buscar usuário por código (para login)
  Future<UsuarioModel?> buscarPorCodigo(String codigo) async {
    final result = await _db.query('''
      SELECT * FROM v_usuarios_completo
      WHERE codigo = @codigo AND ativo = true
    ''', parameters: {'codigo': codigo});

    if (result.isEmpty) return null;
    return UsuarioModel.fromMap(result.first);
  }

  /// Inserir novo usuário
  Future<int> inserir(UsuarioModel usuario) async {
    final result = await _db.query('''
      INSERT INTO usuarios (nome, perfil_id, codigo, ativo)
      VALUES (@nome, @perfil_id, @codigo, @ativo)
      RETURNING id
    ''', parameters: usuario.toMap());

    return result.first['id'];
  }

  /// Atualizar usuário
  Future<void> atualizar(UsuarioModel usuario) async {
    await _db.query('''
      UPDATE usuarios
      SET nome = @nome,
          perfil_id = @perfil_id,
          codigo = @codigo,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...usuario.toMap(),
      'id': usuario.id,
    });
  }

  /// Redefinir senha (código) do usuário
  Future<void> redefinirSenha(int id, String novoCodigo) async {
    await _db.query('''
      UPDATE usuarios
      SET codigo = @codigo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      'id': id,
      'codigo': novoCodigo,
    });
  }

  /// Deletar usuário
  Future<void> deletar(int id) async {
    await _db.query('''
      DELETE FROM usuarios
      WHERE id = @id
    ''', parameters: {'id': id});
  }

  /// Pesquisar usuários por nome
  Future<List<UsuarioModel>> pesquisar(String termo) async {
    final result = await _db.query('''
      SELECT * FROM v_usuarios_completo
      WHERE nome ILIKE @termo
      ORDER BY nome
    ''', parameters: {'termo': '%$termo%'});

    return result.map((map) => UsuarioModel.fromMap(map)).toList();
  }

  /// Verificar se código já existe (para evitar duplicatas)
  Future<bool> codigoExiste(String codigo, {int? excluirId}) async {
    final result = await _db.query('''
      SELECT COUNT(*) as count FROM usuarios
      WHERE codigo = @codigo
      ${excluirId != null ? 'AND id != @excluir_id' : ''}
    ''', parameters: {
      'codigo': codigo,
      if (excluirId != null) 'excluir_id': excluirId,
    });

    return (result.first['count'] ?? 0) > 0;
  }
}
