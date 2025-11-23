import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import 'controllers/admin_controller.dart';
import 'utils/admin_menu_permissions.dart';
import 'views/familias_tab.dart';
import 'views/produtos_tab.dart';
import 'views/empresa_tab.dart';
import 'views/formas_pagamento_tab.dart';
import 'views/setores_tab.dart';
import 'views/areas_tab.dart';
import 'views/clientes_tab.dart';
import 'views/despesas_tab.dart';
import 'views/relatorios_tab.dart';
import 'views/margens_tab.dart';
import 'views/acerto_stock_tab.dart';
import 'views/fornecedores_tab.dart';
import 'views/faturas_entrada_tab.dart';
import 'views/relatorio_stock_tab.dart';
import 'views/perfis_usuario_tab.dart';
import 'views/usuarios_tab.dart';
import 'views/configurar_permissoes_tab.dart';

class AdminPage extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());
  final RxInt selectedIndex = 0.obs;
  final AuthService authService = Get.find<AuthService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_getTitulo())),
      ),
      drawer: _buildDrawer(),
      body: Obx(() => _getBody()),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Get.theme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'ADMINISTRAÇÃO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildMenuItem(0, Icons.business, 'Dados da Empresa'),
          Divider(),
          _buildMenuItem(1, Icons.category, 'Famílias'),
          _buildMenuItem(2, Icons.inventory, 'Produtos'),
          Divider(),
          _buildMenuItem(3, Icons.payment, 'Formas de Pagamento'),
          _buildMenuItem(4, Icons.store, 'Setores'),
          _buildMenuItem(5, Icons.location_on, 'Áreas'),
          Divider(),
          _buildMenuItem(6, Icons.people, 'Clientes'),
          _buildMenuItem(7, Icons.receipt_long, 'Despesas'),
          _buildMenuItem(8, Icons.business, 'Fornecedores'),
          _buildMenuItem(9, Icons.shopping_cart, 'Faturas de Entrada'),
          Divider(),
          _buildMenuItem(10, Icons.analytics, 'Relatórios'),
          _buildMenuItem(11, Icons.trending_up, 'Margens/Lucros'),
          _buildMenuItem(12, Icons.inventory_2, 'Acerto de Stock'),
          _buildMenuItem(13, Icons.warehouse, 'Relatório de Stock'),
          Divider(),
          _buildMenuItem(14, Icons.people, 'Usuários'),
          _buildMenuItem(15, Icons.badge, 'Perfis de Usuário'),
          _buildMenuItem(16, Icons.security, 'Configurar Permissões'),
          Divider(),
          ListTile(
            leading: Icon(Icons.arrow_back, color: Colors.red),
            title: Text('Voltar', style: TextStyle(color: Colors.red)),
            onTap: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    return Obx(() => ListTile(
      selected: selectedIndex.value == index,
      selectedTileColor: Get.theme.primaryColor.withOpacity(0.1),
      leading: Icon(
        icon,
        color: selectedIndex.value == index
            ? Get.theme.primaryColor
            : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selectedIndex.value == index
              ? FontWeight.bold
              : FontWeight.normal,
          color: selectedIndex.value == index
              ? Get.theme.primaryColor
              : Colors.black,
        ),
      ),
      onTap: () async {
        // Verificar permissões antes de permitir acesso
        final permissoesNecessarias = AdminMenuPermissions.getPermissions(index);

        if (permissoesNecessarias.isNotEmpty) {
          final temPermissao = await authService.temAlgumaPermissao(permissoesNecessarias);

          if (!temPermissao) {
            Get.snackbar(
              'Acesso Negado',
              'Você não tem permissão para acessar $title',
              snackPosition: SnackPosition.TOP,
              duration: const Duration(seconds: 3),
            );
            return;
          }
        }

        selectedIndex.value = index;
        Get.back(); // Fechar drawer
      },
    ));
  }

  String _getTitulo() {
    switch (selectedIndex.value) {
      case 0: return 'EMPRESA';
      case 1: return 'FAMÍLIAS';
      case 2: return 'PRODUTOS';
      case 3: return 'FORMAS DE PAGAMENTO';
      case 4: return 'SETORES';
      case 5: return 'ÁREAS';
      case 6: return 'CLIENTES';
      case 7: return 'DESPESAS';
      case 8: return 'FORNECEDORES';
      case 9: return 'FATURAS DE ENTRADA';
      case 10: return 'RELATÓRIOS';
      case 11: return 'MARGENS/LUCROS';
      case 12: return 'ACERTO DE STOCK';
      case 13: return 'RELATÓRIO DE STOCK';
      case 14: return 'USUÁRIOS';
      case 15: return 'PERFIS DE USUÁRIO';
      case 16: return 'CONFIGURAR PERMISSÕES';
      default: return 'ADMIN';
    }
  }

  Widget _getBody() {
    switch (selectedIndex.value) {
      case 0: return EmpresaTab();
      case 1: return FamiliasTab();
      case 2: return ProdutosTab();
      case 3: return FormasPagamentoTab();
      case 4: return SetoresTab();
      case 5: return AreasTab();
      case 6: return ClientesTab();
      case 7: return DespesasTab();
      case 8: return FornecedoresTab();
      case 9: return FaturasEntradaTab();
      case 10: return RelatoriosTab();
      case 11: return MargensTab();
      case 12: return AcertoStockTab();
      case 13: return RelatorioStockTab();
      case 14: return UsuariosTab();
      case 15: return PerfisUsuarioTab();
      case 16: return ConfigurarPermissoesTab();
      default: return EmpresaTab();
    }
  }
}
