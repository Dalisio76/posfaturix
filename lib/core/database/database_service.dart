import 'package:postgres/postgres.dart';
import 'package:get/get.dart';
import 'database_config.dart';

class DatabaseService extends GetxService {
  Connection? _connection;
  final RxBool isConnected = false.obs;
  final RxString connectionError = ''.obs;
  int _retryCount = 0;
  static const int maxRetries = 3;

  Future<DatabaseService> init() async {
    await _connect();
    return this;
  }

  Future<void> _connect() async {
    try {
      _connection = await Connection.open(
        Endpoint(
          host: DatabaseConfig.host,
          port: DatabaseConfig.port,
          database: DatabaseConfig.database,
          username: DatabaseConfig.username,
          password: DatabaseConfig.password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: DatabaseConfig.connectTimeout,
        ),
      );

      isConnected.value = true;
      connectionError.value = '';
      _retryCount = 0;
      print('✅ Conectado ao PostgreSQL em ${DatabaseConfig.host}:${DatabaseConfig.port}');
    } catch (e) {
      isConnected.value = false;
      _retryCount++;

      final errorMsg = '''
❌ Erro ao conectar ao PostgreSQL:
   Servidor: ${DatabaseConfig.host}:${DatabaseConfig.port}
   Database: ${DatabaseConfig.database}
   Tentativa: $_retryCount de $maxRetries
   Erro: $e
      ''';

      print(errorMsg);
      connectionError.value = errorMsg;

      // Tentar reconectar se ainda houver tentativas
      if (_retryCount < maxRetries) {
        print('⏳ Tentando reconectar em 3 segundos...');
        await Future.delayed(Duration(seconds: 3));
        await _connect();
      } else {
        print('''
╔════════════════════════════════════════════════════════════════╗
║  FALHA NA CONEXÃO COM O BANCO DE DADOS                        ║
╟────────────────────────────────────────────────────────────────╢
║  A aplicação não conseguiu conectar ao PostgreSQL.             ║
║                                                                 ║
║  Verifique:                                                     ║
║  1. PostgreSQL está instalado e rodando?                       ║
║  2. O servidor está acessível em ${DatabaseConfig.host}:${DatabaseConfig.port}?        ║
║  3. O banco "${DatabaseConfig.database}" existe?                        ║
║  4. Usuário e senha estão corretos?                            ║
║                                                                 ║
║  Configure em: lib/core/database/database_config.dart          ║
╚════════════════════════════════════════════════════════════════╝
        ''');
        // Não lançar exceção para permitir que a app mostre erro na UI
      }
    }
  }

  /// Reconectar manualmente
  Future<void> reconnect() async {
    _retryCount = 0;
    await _connect();
  }

  /// Executar query SELECT - retorna lista de mapas
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    if (_connection == null || !isConnected.value) {
      throw Exception('Não conectado ao banco de dados. Configure a conexão primeiro.');
    }

    try {
      final result = await _connection!.execute(
        Sql.named(sql),
        parameters: parameters,
      );

      return result.map((row) => row.toColumnMap()).toList();
    } catch (e) {
      print('❌ Erro na query: $e');
      print('SQL: $sql');
      rethrow;
    }
  }

  /// Executar INSERT, UPDATE, DELETE
  Future<void> execute(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    if (_connection == null || !isConnected.value) {
      throw Exception('Não conectado ao banco de dados. Configure a conexão primeiro.');
    }

    try {
      await _connection!.execute(
        Sql.named(sql),
        parameters: parameters,
      );
    } catch (e) {
      print('❌ Erro ao executar: $e');
      print('SQL: $sql');
      rethrow;
    }
  }

  /// Executar INSERT e retornar ID gerado
  Future<int> insert(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    if (_connection == null || !isConnected.value) {
      throw Exception('Não conectado ao banco de dados. Configure a conexão primeiro.');
    }

    try {
      final result = await _connection!.execute(
        Sql.named(sql + ' RETURNING id'),
        parameters: parameters,
      );

      if (result.isEmpty) {
        throw Exception('Insert não retornou ID');
      }

      return result.first[0] as int;
    } catch (e) {
      print('❌ Erro ao inserir: $e');
      print('SQL: $sql');
      rethrow;
    }
  }

  /// Transação (para vendas com múltiplos itens)
  Future<T> transaction<T>(
    Future<T> Function(TxSession ctx) action,
  ) async {
    if (_connection == null || !isConnected.value) {
      throw Exception('Não conectado ao banco de dados. Configure a conexão primeiro.');
    }

    return await _connection!.runTx((ctx) async {
      return await action(ctx);
    });
  }

  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
    }
    isConnected.value = false;
  }
}
