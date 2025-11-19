import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar banco de dados
  print('🔄 Conectando ao PostgreSQL...');
  try {
    await Get.putAsync(() => DatabaseService().init());
    print('✅ Conexão estabelecida!');
  } catch (e) {
    print('❌ Erro ao conectar: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Frentex Software',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.home,
      getPages: AppPages.routes,
    );
  }
}
