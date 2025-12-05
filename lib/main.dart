import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';
import 'core/database/database_config.dart';
import 'core/services/auth_service.dart';
import 'core/services/licenca_service.dart';
import 'core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/modules/licenca/licenca_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carregar configurações salvas do banco de dados
  print('📝 Carregando configurações...');
  await DatabaseConfig.loadSavedConfig();

  // Inicializar serviço de licença
  print('🔐 Verificando licença...');
  final licencaService = await Get.putAsync(() => LicencaService().init());

  // Inicializar banco de dados
  print('🔄 Conectando ao PostgreSQL...');
  DatabaseService dbService;
  bool isConnected = false;

  try {
    dbService = await Get.putAsync(() => DatabaseService().init());
    isConnected = dbService.isConnected.value;
    print('✅ Conexão estabelecida!');
  } catch (e) {
    print('❌ Erro ao conectar: $e');
    dbService = Get.put(DatabaseService());
    isConnected = false;
  }

  // Inicializar serviço de autenticação
  Get.put(AuthService());

  runApp(MyApp(
    isDbConnected: isConnected,
    licencaService: licencaService,
  ));
}

class MyApp extends StatefulWidget {
  final bool isDbConnected;
  final LicencaService licencaService;

  const MyApp({
    Key? key,
    required this.isDbConnected,
    required this.licencaService,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Verificar licença após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarLicenca();
    });
  }

  void _verificarLicenca() {
    // Se licença vencida, mostrar dialog bloqueante
    if (!widget.licencaService.licencaValida.value) {
      Get.dialog(
        const LicencaDialog(bloqueado: true),
        barrierDismissible: false,
      );
      return;
    }

    // Se deve mostrar alerta (30 dias antes), mostrar dialog não-bloqueante
    if (widget.licencaService.mostrarAlerta.value) {
      Get.dialog(
        const LicencaDialog(bloqueado: false),
        barrierDismissible: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Frentex Software',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: widget.isDbConnected ? AppRoutes.home : AppRoutes.databaseConfig,
      getPages: AppPages.routes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'PT'), // Português de Portugal
        Locale('pt', 'BR'), // Português do Brasil
        Locale('en', 'US'), // Inglês
      ],
      locale: const Locale('pt', 'PT'), // Locale padrão
    );
  }
}
