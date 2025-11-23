import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../login/login_page.dart';
import '../../data/models/usuario_model.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou Nome do Sistema
              Icon(
                Icons.point_of_sale,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'SISTEMA PDV',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Frentex e Serviços',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 60),

              // Botões principais
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMenuButton(
                    icon: Icons.shopping_cart,
                    label: 'VENDAS',
                    color: AppTheme.secondaryColor,
                    onTap: () => _abrirComLogin(AppRoutes.vendas),
                  ),
                  SizedBox(width: 40),
                  _buildMenuButton(
                    icon: Icons.admin_panel_settings,
                    label: 'ADMIN',
                    color: AppTheme.warningColor,
                    onTap: () => _abrirComLogin(AppRoutes.admin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirComLogin(String rota) async {
    final usuario = await Get.to<UsuarioModel>(() => LoginPage());

    if (usuario != null) {
      Get.toNamed(rota);
    }
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
