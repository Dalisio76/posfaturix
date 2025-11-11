import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/empresa_model.dart';

class EmpresaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Buscar dados da empresa (sempre retorna o primeiro registro)
  Future<EmpresaModel?> buscarDados() async {
    final result = await _db.query('''
      SELECT * FROM empresa WHERE ativo = true LIMIT 1
    ''');

    if (result.isEmpty) return null;
    return EmpresaModel.fromMap(result.first);
  }

  /// Atualizar dados da empresa
  Future<void> atualizar(int id, EmpresaModel empresa) async {
    await _db.execute('''
      UPDATE empresa
      SET nome = @nome,
          nuit = @nuit,
          endereco = @endereco,
          cidade = @cidade,
          email = @email,
          contacto = @contacto,
          logo_url = @logo_url,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...empresa.toMap(),
      'id': id,
    });
  }
}
