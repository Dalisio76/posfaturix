import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/auditoria_model.dart';

class AuditoriaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  // ============================================
  // CONSULTAS DE AUDITORIA
  // ============================================

  /// Lista registros de auditoria com filtros
  Future<List<AuditoriaModel>> listar({
    String? tabela,
    String? operacao,
    int? usuarioId,
    DateTime? dataInicio,
    DateTime? dataFim,
    int limit = 100,
    int offset = 0,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (tabela != null && tabela.isNotEmpty) {
      conditions.add('tabela = @tabela');
      parameters['tabela'] = tabela;
    }

    if (operacao != null && operacao.isNotEmpty) {
      conditions.add('operacao = @operacao');
      parameters['operacao'] = operacao;
    }

    if (usuarioId != null) {
      conditions.add('usuario_id = @usuario_id');
      parameters['usuario_id'] = usuarioId;
    }

    if (dataInicio != null) {
      conditions.add('data_operacao >= @data_inicio');
      parameters['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      conditions.add('data_operacao <= @data_fim');
      parameters['data_fim'] = dataFim.toIso8601String();
    }

    final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final resultado = await _db.query(
      '''
      SELECT * FROM vw_auditoria_detalhada
      $whereClause
      ORDER BY data_operacao DESC
      LIMIT @limit OFFSET @offset
      ''',
      parameters: {
        ...parameters,
        'limit': limit,
        'offset': offset,
      },
    );

    return resultado.map((row) => AuditoriaModel.fromMap(row)).toList();
  }

  /// Conta total de registros (para paginação)
  Future<int> contar({
    String? tabela,
    String? operacao,
    int? usuarioId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (tabela != null && tabela.isNotEmpty) {
      conditions.add('tabela = @tabela');
      parameters['tabela'] = tabela;
    }

    if (operacao != null && operacao.isNotEmpty) {
      conditions.add('operacao = @operacao');
      parameters['operacao'] = operacao;
    }

    if (usuarioId != null) {
      conditions.add('usuario_id = @usuario_id');
      parameters['usuario_id'] = usuarioId;
    }

    if (dataInicio != null) {
      conditions.add('data_operacao >= @data_inicio');
      parameters['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      conditions.add('data_operacao <= @data_fim');
      parameters['data_fim'] = dataFim.toIso8601String();
    }

    final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final resultado = await _db.query(
      '''
      SELECT COUNT(*) as total FROM auditoria
      $whereClause
      ''',
      parameters: parameters,
    );

    return resultado.first['total'] as int;
  }

  /// Busca histórico de alterações de um registro específico
  Future<List<AuditoriaModel>> buscarHistoricoRegistro(
    String tabela,
    int registroId,
  ) async {
    final resultado = await _db.query(
      '''
      SELECT * FROM buscar_historico_registro(@tabela, @registro_id)
      ''',
      parameters: {
        'tabela': tabela,
        'registro_id': registroId,
      },
    );

    return resultado.map((row) {
      final map = row;
      return AuditoriaModel(
        id: map['id'] as int?,
        tabela: tabela,
        operacao: map['operacao'] as String,
        registroId: registroId,
        usuarioId: null,
        usuarioNome: map['usuario_nome'] as String?,
        descricao: map['descricao'] as String?,
        dadosAnteriores: map['dados_anteriores'] as Map<String, dynamic>?,
        dadosNovos: map['dados_novos'] as Map<String, dynamic>?,
        dataOperacao: DateTime.parse(map['data_operacao'] as String),
      );
    }).toList();
  }

  /// Lista resumo de operações por usuário
  Future<List<AuditoriaPorUsuarioModel>> listarPorUsuario() async {
    final resultado = await _db.query('SELECT * FROM vw_auditoria_por_usuario LIMIT 100');

    return resultado
        .map((row) => AuditoriaPorUsuarioModel.fromMap(row))
        .toList();
  }

  /// Lista operações suspeitas
  Future<List<Map<String, dynamic>>> listarOperacoesSuspeitas() async {
    final resultado = await _db.query('SELECT * FROM vw_operacoes_suspeitas');
    return resultado.map((row) => row).toList();
  }

  /// Lista histórico de alterações de preços
  Future<List<HistoricoPrecoModel>> listarHistoricoPrecos({int limit = 50}) async {
    final resultado = await _db.query(
      '''
      SELECT * FROM vw_historico_precos
      ORDER BY data_operacao DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );

    return resultado.map((row) => HistoricoPrecoModel.fromMap(row)).toList();
  }

  /// Lista produtos deletados (para possível recuperação)
  Future<List<Map<String, dynamic>>> listarProdutosDeletados({int limit = 50}) async {
    final resultado = await _db.query(
      '''
      SELECT * FROM vw_produtos_deletados
      ORDER BY data_delecao DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );

    return resultado.map((row) => row).toList();
  }

  // ============================================
  // LOGS DE ACESSO
  // ============================================

  /// Lista logs de acesso
  Future<List<LogAcessoModel>> listarLogsAcesso({
    String? tipo,
    int? usuarioId,
    DateTime? dataInicio,
    DateTime? dataFim,
    int limit = 100,
    int offset = 0,
  }) async {
    final conditions = <String>[];
    final parameters = <String, dynamic>{};

    if (tipo != null && tipo.isNotEmpty) {
      conditions.add('tipo = @tipo');
      parameters['tipo'] = tipo;
    }

    if (usuarioId != null) {
      conditions.add('usuario_id = @usuario_id');
      parameters['usuario_id'] = usuarioId;
    }

    if (dataInicio != null) {
      conditions.add('data_hora >= @data_inicio');
      parameters['data_inicio'] = dataInicio.toIso8601String();
    }

    if (dataFim != null) {
      conditions.add('data_hora <= @data_fim');
      parameters['data_fim'] = dataFim.toIso8601String();
    }

    final whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final resultado = await _db.query(
      '''
      SELECT
        l.*,
        u.nome as usuario_nome,
        u.codigo as usuario_codigo
      FROM logs_acesso l
      LEFT JOIN usuarios u ON u.id = l.usuario_id
      $whereClause
      ORDER BY l.data_hora DESC
      LIMIT @limit OFFSET @offset
      ''',
      parameters: {
        ...parameters,
        'limit': limit,
        'offset': offset,
      },
    );

    return resultado.map((row) => LogAcessoModel.fromMap(row)).toList();
  }

  /// Lista tentativas de login falhadas
  Future<List<LogAcessoModel>> listarLoginsFalhados({int limit = 50}) async {
    final resultado = await _db.query(
      '''
      SELECT * FROM vw_logins_falhados
      ORDER BY data_hora DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );

    return resultado.map((row) => LogAcessoModel.fromMap(row)).toList();
  }

  /// Registra login bem-sucedido
  Future<void> registrarLogin(
    int usuarioId, {
    String? terminalNome,
    String? ipAddress,
  }) async {
    await _db.query(
      '''
      SELECT registrar_login(@usuario_id, @terminal_nome, @ip_address)
      ''',
      parameters: {
        'usuario_id': usuarioId,
        'terminal_nome': terminalNome,
        'ip_address': ipAddress,
      },
    );
  }

  /// Registra logout
  Future<void> registrarLogout(
    int usuarioId, {
    String? terminalNome,
    String? ipAddress,
  }) async {
    await _db.query(
      '''
      SELECT registrar_logout(@usuario_id, @terminal_nome, @ip_address)
      ''',
      parameters: {
        'usuario_id': usuarioId,
        'terminal_nome': terminalNome,
        'ip_address': ipAddress,
      },
    );
  }

  /// Registra tentativa de login falhada
  Future<void> registrarLoginFalhado(
    String codigo,
    String motivo, {
    String? terminalNome,
    String? ipAddress,
  }) async {
    await _db.query(
      '''
      SELECT registrar_login_falhado(@codigo, @motivo, @terminal_nome, @ip_address)
      ''',
      parameters: {
        'codigo': codigo,
        'motivo': motivo,
        'terminal_nome': terminalNome,
        'ip_address': ipAddress,
      },
    );
  }

  /// Limpa logs antigos (manutenção)
  Future<int> limparLogsAntigos({int dias = 90}) async {
    final resultado = await _db.query(
      '''
      SELECT limpar_logs_antigos(@dias) as deletados
      ''',
      parameters: {'dias': dias},
    );

    return resultado.first['deletados'] as int;
  }

  // ============================================
  // ESTATÍSTICAS
  // ============================================

  /// Retorna estatísticas gerais de auditoria
  Future<Map<String, dynamic>> obterEstatisticas({
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final periodo = dataInicio != null && dataFim != null
        ? 'WHERE data_operacao BETWEEN @data_inicio AND @data_fim'
        : 'WHERE data_operacao >= CURRENT_DATE - INTERVAL \'7 days\'';

    final parameters = <String, dynamic>{};
    if (dataInicio != null) parameters['data_inicio'] = dataInicio.toIso8601String();
    if (dataFim != null) parameters['data_fim'] = dataFim.toIso8601String();

    final resultado = await _db.query(
      '''
      SELECT
        COUNT(*) as total_operacoes,
        COUNT(DISTINCT usuario_id) as usuarios_ativos,
        COUNT(DISTINCT tabela) as tabelas_afetadas,
        COUNT(CASE WHEN operacao = 'INSERT' THEN 1 END) as total_inserts,
        COUNT(CASE WHEN operacao = 'UPDATE' THEN 1 END) as total_updates,
        COUNT(CASE WHEN operacao = 'DELETE' THEN 1 END) as total_deletes
      FROM auditoria
      $periodo
      ''',
      parameters: parameters,
    );

    return resultado.first;
  }

  /// Retorna operações mais frequentes
  Future<List<Map<String, dynamic>>> obterOperacoesMaisFrequentes({int limit = 10}) async {
    final resultado = await _db.query(
      '''
      SELECT
        tabela,
        operacao,
        COUNT(*) as total
      FROM auditoria
      WHERE data_operacao >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY tabela, operacao
      ORDER BY total DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );

    return resultado.map((row) => row).toList();
  }

  /// Retorna usuários mais ativos
  Future<List<Map<String, dynamic>>> obterUsuariosMaisAtivos({int limit = 10}) async {
    final resultado = await _db.query(
      '''
      SELECT
        u.id,
        u.nome,
        u.codigo,
        COUNT(a.id) as total_operacoes
      FROM usuarios u
      INNER JOIN auditoria a ON a.usuario_id = u.id
      WHERE a.data_operacao >= CURRENT_DATE - INTERVAL '7 days'
      GROUP BY u.id, u.nome, u.codigo
      ORDER BY total_operacoes DESC
      LIMIT @limit
      ''',
      parameters: {'limit': limit},
    );

    return resultado.map((row) => row).toList();
  }
}
