import 'package:postgres/postgres.dart';
import 'package:get/get.dart';
import 'database_config.dart';

class DatabaseService extends GetxService {
  late Connection _connection;
  final RxBool isConnected = false.obs;

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
      print('✅ Conectado ao PostgreSQL em ${DatabaseConfig.host}:${DatabaseConfig.port}');
    } catch (e) {
      isConnected.value = false;
      print('❌ Erro ao conectar ao PostgreSQL: $e');

      // Tentar reconectar após 5 segundos
      await Future.delayed(Duration(seconds: 5));
      await _connect();
    }
  }

  /// Executar query SELECT - retorna lista de mapas
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final result = await _connection.execute(
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
    try {
      await _connection.execute(
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
    try {
      final result = await _connection.execute(
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
    return await _connection.runTx((ctx) async {
      return await action(ctx);
    });
  }

  Future<void> close() async {
    await _connection.close();
    isConnected.value = false;
  }
}
