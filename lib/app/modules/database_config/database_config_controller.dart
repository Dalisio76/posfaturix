import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';
import '../../../core/database/database_service.dart';
import '../../routes/app_routes.dart';

class DatabaseConfigController extends GetxController {
  // Controllers de texto
  final hostController = TextEditingController(text: 'localhost');
  final portController = TextEditingController(text: '5432');
  final databaseController = TextEditingController(text: 'pdv_system');
  final usernameController = TextEditingController(text: 'postgres');
  final passwordController = TextEditingController(text: 'frentex');

  // Estado
  final RxBool isConnected = false.obs;
  final RxBool isTesting = false.obs;
  final RxBool showPassword = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedConfig();
  }

  /// Carregar configuração salva
  Future<void> loadSavedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedHost = prefs.getString('db_host');
      final savedPort = prefs.getString('db_port');
      final savedDatabase = prefs.getString('db_database');
      final savedUsername = prefs.getString('db_username');
      final savedPassword = prefs.getString('db_password');

      if (savedHost != null) hostController.text = savedHost;
      if (savedPort != null) portController.text = savedPort;
      if (savedDatabase != null) databaseController.text = savedDatabase;
      if (savedUsername != null) usernameController.text = savedUsername;
      if (savedPassword != null) passwordController.text = savedPassword;
    } catch (e) {
      print('Erro ao carregar configuração: $e');
    }
  }

  /// Salvar configuração
  Future<void> saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('db_host', hostController.text);
      await prefs.setString('db_port', portController.text);
      await prefs.setString('db_database', databaseController.text);
      await prefs.setString('db_username', usernameController.text);
      await prefs.setString('db_password', passwordController.text);

      print('✅ Configuração salva com sucesso!');
    } catch (e) {
      print('❌ Erro ao salvar configuração: $e');
    }
  }

  /// Testar conexão
  Future<void> testConnection() async {
    isTesting.value = true;
    isConnected.value = false;
    errorMessage.value = '';

    try {
      // Validar campos
      if (hostController.text.trim().isEmpty) {
        throw Exception('O campo Host é obrigatório');
      }
      if (portController.text.trim().isEmpty) {
        throw Exception('O campo Porta é obrigatório');
      }
      if (databaseController.text.trim().isEmpty) {
        throw Exception('O campo Nome do Banco é obrigatório');
      }
      if (usernameController.text.trim().isEmpty) {
        throw Exception('O campo Usuário é obrigatório');
      }
      if (passwordController.text.trim().isEmpty) {
        throw Exception('O campo Senha é obrigatório');
      }

      final port = int.tryParse(portController.text);
      if (port == null || port <= 0 || port > 65535) {
        throw Exception('Porta inválida. Use um número entre 1 e 65535');
      }

      print('🔄 Testando conexão com PostgreSQL...');
      print('   Host: ${hostController.text}');
      print('   Port: $port');
      print('   Database: ${databaseController.text}');
      print('   Username: ${usernameController.text}');

      // Tentar conectar
      final connection = await Connection.open(
        Endpoint(
          host: hostController.text.trim(),
          port: port,
          database: databaseController.text.trim(),
          username: usernameController.text.trim(),
          password: passwordController.text.trim(),
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 10),
        ),
      );

      // Testar query simples
      final result = await connection.execute('SELECT version()');
      final version = result.first[0] as String;
      print('✅ Conexão bem-sucedida!');
      print('   PostgreSQL: ${version.split('PostgreSQL')[1].split(' on')[0].trim()}');

      // Fechar conexão de teste
      await connection.close();

      isConnected.value = true;
      errorMessage.value = '';

      Get.snackbar(
        '✅ Sucesso',
        'Conexão estabelecida com sucesso!',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      isConnected.value = false;

      String errorMsg = e.toString();

      // Mensagens de erro mais amigáveis
      if (errorMsg.contains('Connection refused')) {
        errorMsg = 'Servidor não encontrado ou PostgreSQL não está rodando.\nVerifique se o PostgreSQL está instalado e rodando.';
      } else if (errorMsg.contains('Timeout')) {
        errorMsg = 'Tempo esgotado ao tentar conectar.\nVerifique o IP do servidor e firewall.';
      } else if (errorMsg.contains('password authentication failed')) {
        errorMsg = 'Usuário ou senha incorretos.';
      } else if (errorMsg.contains('database') && errorMsg.contains('does not exist')) {
        errorMsg = 'O banco de dados "${databaseController.text}" não existe.\nCrie o banco ou verifique o nome.';
      }

      errorMessage.value = errorMsg;

      Get.snackbar(
        '❌ Erro de Conexão',
        errorMsg,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        icon: const Icon(Icons.error, color: Colors.red),
        duration: const Duration(seconds: 5),
      );

      print('❌ Erro ao conectar: $e');
    } finally {
      isTesting.value = false;
    }
  }

  /// Salvar e continuar
  Future<void> saveAndContinue() async {
    if (!isConnected.value) {
      Get.snackbar(
        '⚠️ Atenção',
        'Teste a conexão antes de continuar',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        icon: const Icon(Icons.warning, color: Colors.orange),
      );
      return;
    }

    try {
      // Salvar configuração
      await saveConfig();

      // Atualizar DatabaseConfig dinâmicamente
      await _updateDatabaseConfig();

      // Reconectar o DatabaseService
      final dbService = Get.find<DatabaseService>();
      await dbService.reconnect();

      if (dbService.isConnected.value) {
        Get.snackbar(
          '✅ Configuração Salva',
          'Aplicação configurada com sucesso!',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );

        // Navegar para home
        Get.offAllNamed(AppRoutes.home);
      } else {
        throw Exception('Falha ao reconectar após salvar configuração');
      }
    } catch (e) {
      Get.snackbar(
        '❌ Erro',
        'Erro ao salvar configuração: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        icon: const Icon(Icons.error, color: Colors.red),
      );
      print('❌ Erro ao salvar: $e');
    }
  }

  /// Atualizar DatabaseConfig com os novos valores
  Future<void> _updateDatabaseConfig() async {
    // Criar arquivo de configuração dinâmica
    final configContent = '''
class DatabaseConfig {
  static const String host = '${hostController.text.trim()}';
  static const int port = ${int.parse(portController.text)};
  static const String database = '${databaseController.text.trim()}';
  static const String username = '${usernameController.text.trim()}';
  static const String password = '${passwordController.text.trim()}';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration queryTimeout = Duration(seconds: 30);

  static const String terminalNome = 'Terminal Principal';
  static const int? terminalId = null;

  static String get connectionString {
    return 'postgresql://\$username:\$password@\$host:\$port/\$database';
  }

  static bool get isServidor => host == 'localhost' || host == '127.0.0.1';
}
''';

    // Salvar em SharedPreferences também
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_config_dart', configContent);

    print('✅ DatabaseConfig atualizado');
  }

  /// Toggle visibilidade da senha
  void togglePasswordVisibility() {
    showPassword.value = !showPassword.value;
  }

  @override
  void onClose() {
    hostController.dispose();
    portController.dispose();
    databaseController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
