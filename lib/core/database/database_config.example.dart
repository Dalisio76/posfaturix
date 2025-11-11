class DatabaseConfig {
  // Configuração do PostgreSQL local
  static const String host = 'localhost';
  static const int port = 5432;
  static const String database = 'pdv_system';
  static const String username = 'postgres';
  static const String password = 'SUA_SENHA_AQUI'; // ALTERE PARA SUA SENHA!

  // Configurações de conexão
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 30);
}
