import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/admin_controller.dart';
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

class AdminPage extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());
  final RxInt selectedIndex = 0.obs;

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
          Divider(),
          _buildMenuItem(8, Icons.analytics, 'Relatórios'),
          _buildMenuItem(9, Icons.trending_up, 'Margens/Lucros'),
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
      onTap: () {
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
      case 8: return 'RELATÓRIOS';
      case 9: return 'MARGENS/LUCROS';
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
      case 8: return RelatoriosTab();
      case 9: return MargensTab();
      default: return EmpresaTab();
    }
  }
}
