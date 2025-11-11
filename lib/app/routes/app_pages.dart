import 'package:get/get.dart';
import '../modules/home/home_page.dart';
import '../modules/admin/admin_page.dart';
import '../modules/vendas/vendas_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.home,
      page: () => HomePage(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => AdminPage(),
    ),
    GetPage(
      name: AppRoutes.vendas,
      page: () => VendasPage(),
    ),
  ];
}
