import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import 'controllers/admin_controller.dart';
import 'views/vendedor_operador_tab.dart';
import 'views/produtos_pedidos_tab.dart';
import 'views/stock_baixo_tab.dart';

// ==========================================
// NOVA INTERFACE DE ADMINISTRAÇÃO
// Design moderno, touch-friendly, organizado
// ==========================================

class AdminPageNovo extends StatefulWidget {
  const AdminPageNovo({Key? key}) : super(key: key);

  @override
  State<AdminPageNovo> createState() => _AdminPageNovoState();
}

class _AdminPageNovoState extends State<AdminPageNovo> {
  final AdminController controller = Get.put(AdminController());
  final AuthService authService = Get.find<AuthService>();
  final RxString searchQuery = ''.obs;
  final Rxn<AdminMenuItem> selectedItem = Rxn<AdminMenuItem>();
  final RxList<String> breadcrumb = <String>['Dashboard'].obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: Obx(() => selectedItem.value == null
          ? _buildDashboard()
          : _buildConteudo()),
    );
  }

  // ==========================================
  // APP BAR com busca e navegação
  // ==========================================
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: Row(
        children: [
          Icon(Icons.admin_panel_settings, size: 28, color: Get.theme.primaryColor),
          SizedBox(width: 12),
          Text(
            'ADMINISTRAÇÃO',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        // Campo de busca
        Container(
          width: 300,
          height: 40,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: TextField(
            onChanged: (value) => searchQuery.value = value,
            decoration: InputDecoration(
              hintText: 'Buscar funcionalidade...',
              prefixIcon: Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),

        // Botão voltar
        IconButton(
          icon: Icon(Icons.arrow_back, size: 24),
          onPressed: () => Get.back(),
          tooltip: 'Voltar',
        ),
        SizedBox(width: 8),
      ],
    );
  }

  // ==========================================
  // DASHBOARD - Tela inicial com cards
  // ==========================================
  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(),
          SizedBox(height: 24),

          // Estatísticas rápidas
          _buildEstatisticasRapidas(),
          SizedBox(height: 32),

          // Categorias de menu
          _buildCategoria(
            'CADASTROS BÁSICOS',
            Colors.blue,
            _getCadastrosBasicos(),
          ),
          SizedBox(height: 24),

          _buildCategoria(
            'OPERAÇÕES',
            Colors.green,
            _getOperacoes(),
          ),
          SizedBox(height: 24),

          _buildCategoria(
            'RELATÓRIOS & ANÁLISES',
            Colors.orange,
            _getRelatorios(),
          ),
          SizedBox(height: 24),

          _buildCategoria(
            'SISTEMA & SEGURANÇA',
            Colors.purple,
            _getSistema(),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Breadcrumb de navegação
  // ==========================================
  Widget _buildBreadcrumb() {
    return Obx(() => Row(
      children: [
        InkWell(
          onTap: () {
            selectedItem.value = null;
            breadcrumb.value = ['Dashboard'];
          },
          child: Text(
            'Dashboard',
            style: TextStyle(
              color: selectedItem.value == null
                  ? Get.theme.primaryColor
                  : Colors.grey,
              fontWeight: selectedItem.value == null
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        if (selectedItem.value != null) ...[
          Icon(Icons.chevron_right, size: 16, color: Colors.grey),
          Text(
            selectedItem.value!.titulo,
            style: TextStyle(
              color: Get.theme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ],
    ));
  }

  // ==========================================
  // Estatísticas rápidas
  // ==========================================
  Widget _buildEstatisticasRapidas() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Produtos',
            '1.234',
            Icons.inventory,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Clientes Ativos',
            '567',
            Icons.people,
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Mesas Ocupadas',
            '12/25',
            Icons.table_restaurant,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Usuários',
            '8',
            Icons.person,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String valor, IconData icon, Color cor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cor, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Categoria de menus
  // ==========================================
  Widget _buildCategoria(String titulo, Color cor, List<AdminMenuItem> itens) {
    // Filtrar por busca
    final itensFiltrados = searchQuery.value.isEmpty
        ? itens
        : itens.where((item) =>
            item.titulo.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            (item.descricao?.toLowerCase().contains(searchQuery.value.toLowerCase()) ?? false)
          ).toList();

    if (itensFiltrados.isEmpty) return Container();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5, // 5 colunas em desktop
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3, // Cards retangulares
          ),
          itemCount: itensFiltrados.length,
          itemBuilder: (context, index) {
            return _buildMenuCard(itensFiltrados[index], cor);
          },
        ),
      ],
    );
  }

  // ==========================================
  // Card de menu (TOUCH-FRIENDLY)
  // ==========================================
  Widget _buildMenuCard(AdminMenuItem item, Color cor) {
    return InkWell(
      onTap: () async {
        // Verificar permissões
        // NOTA: O AuthService já faz bypass para perfis Administrador
        // mas mantemos verificação por segurança
        if (item.permissoes.isNotEmpty) {
          final perfilNome = authService.perfilUsuario.toLowerCase();
          final isAdmin = perfilNome.contains('administrador');

          // Se não é admin, verificar permissões
          if (!isAdmin) {
            final temPermissao = await authService.temAlgumaPermissao(item.permissoes);
            if (!temPermissao) {
              Get.snackbar(
                'Acesso Negado',
                'Você não tem permissão para acessar ${item.titulo}',
                backgroundColor: Colors.red[700],
                colorText: Colors.white,
              );
              return;
            }
          }
        }

        selectedItem.value = item;
        breadcrumb.value = ['Dashboard', item.titulo];
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icone,
                size: 40,
                color: cor,
              ),
            ),
            SizedBox(height: 12),
            Text(
              item.titulo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (item.descricao != null) ...[
              SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item.descricao!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Conteúdo da funcionalidade selecionada
  // ==========================================
  Widget _buildConteudo() {
    return Column(
      children: [
        // Breadcrumb
        Container(
          padding: EdgeInsets.all(24),
          color: Colors.white,
          child: Row(
            children: [
              _buildBreadcrumb(),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  selectedItem.value = null;
                  breadcrumb.value = ['Dashboard'];
                },
                icon: Icon(Icons.dashboard, size: 18),
                label: Text('Voltar ao Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),

        // Conteúdo da tab
        Expanded(
          child: Container(
            padding: EdgeInsets.all(24),
            child: selectedItem.value!.widget,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DEFINIÇÃO DOS MENUS
  // ==========================================

  List<AdminMenuItem> _getCadastrosBasicos() {
    return [
      AdminMenuItem(
        titulo: 'Empresa',
        icone: Icons.business,
        widget: Container(child: Text('Empresa Tab')), // Substituir pelos widgets reais
        permissoes: ['gestao_empresa'],
        descricao: 'Dados da empresa',
      ),
      AdminMenuItem(
        titulo: 'Produtos',
        icone: Icons.inventory,
        widget: Container(child: Text('Produtos Tab')),
        permissoes: ['gestao_produtos'],
        descricao: 'Catálogo de produtos',
      ),
      AdminMenuItem(
        titulo: 'Famílias',
        icone: Icons.category,
        widget: Container(child: Text('Famílias Tab')),
        permissoes: ['gestao_produtos'],
        descricao: 'Categorias de produtos',
      ),
      AdminMenuItem(
        titulo: 'Clientes',
        icone: Icons.people,
        widget: Container(child: Text('Clientes Tab')),
        permissoes: ['gestao_clientes'],
        descricao: 'Cadastro de clientes',
      ),
      AdminMenuItem(
        titulo: 'Fornecedores',
        icone: Icons.local_shipping,
        widget: Container(child: Text('Fornecedores Tab')),
        permissoes: ['gestao_fornecedores'],
        descricao: 'Gestão de fornecedores',
      ),
      AdminMenuItem(
        titulo: 'Mesas',
        icone: Icons.table_restaurant,
        widget: Container(child: Text('Mesas Tab')),
        permissoes: ['gestao_mesas'],
        descricao: 'Configuração de mesas',
      ),
    ];
  }

  List<AdminMenuItem> _getOperacoes() {
    return [
      AdminMenuItem(
        titulo: 'Faturas Entrada',
        icone: Icons.receipt_long,
        widget: Container(child: Text('Faturas Tab')),
        permissoes: ['gestao_faturas'],
        descricao: 'Registro de compras',
      ),
      AdminMenuItem(
        titulo: 'Acerto Stock',
        icone: Icons.inventory_2,
        widget: Container(child: Text('Acerto Stock Tab')),
        permissoes: ['acerto_stock'],
        descricao: 'Ajustes de estoque',
      ),
      AdminMenuItem(
        titulo: 'Despesas',
        icone: Icons.money_off,
        widget: Container(child: Text('Despesas Tab')),
        permissoes: ['gestao_despesas'],
        descricao: 'Controle de despesas',
      ),
      AdminMenuItem(
        titulo: 'Pagamentos',
        icone: Icons.payment,
        widget: Container(child: Text('Formas Pagamento Tab')),
        permissoes: ['gestao_pagamentos'],
        descricao: 'Formas de pagamento',
      ),
    ];
  }

  List<AdminMenuItem> _getRelatorios() {
    return [
      AdminMenuItem(
        titulo: 'Relatórios',
        icone: Icons.analytics,
        widget: Container(child: Text('Relatórios Tab')),
        permissoes: ['visualizar_relatorios'],
        descricao: 'Relatórios gerais',
      ),
      AdminMenuItem(
        titulo: 'Produtos Pedidos',
        icone: Icons.shopping_cart,
        widget: ProdutosPedidosTab(),
        permissoes: ['visualizar_relatorios'],
        descricao: 'Ver produtos pedidos por mesa e operador',
      ),
      AdminMenuItem(
        titulo: 'Margens/Lucros',
        icone: Icons.trending_up,
        widget: Container(child: Text('Margens Tab')),
        permissoes: ['visualizar_margens'],
        descricao: 'Análise de margens',
      ),
      AdminMenuItem(
        titulo: 'Stock',
        icone: Icons.warehouse,
        widget: Container(child: Text('Stock Tab')),
        permissoes: ['visualizar_stock'],
        descricao: 'Relatório de estoque',
      ),
      AdminMenuItem(
        titulo: 'Stock Baixo',
        icone: Icons.warning_amber,
        widget: const StockBaixoTab(),
        permissoes: ['visualizar_stock'],
        descricao: 'Produtos com stock baixo',
      ),
      AdminMenuItem(
        titulo: 'Vendedor/Operador',
        icone: Icons.person_search,
        widget: VendedorOperadorTab(),
        permissoes: ['visualizar_relatorios'],
        descricao: 'Performance de vendedores',
      ),
    ];
  }

  List<AdminMenuItem> _getSistema() {
    return [
      AdminMenuItem(
        titulo: 'Usuários',
        icone: Icons.person,
        widget: Container(child: Text('Usuários Tab')),
        permissoes: ['gestao_usuarios'],
        descricao: 'Gerenciar usuários',
      ),
      AdminMenuItem(
        titulo: 'Perfis',
        icone: Icons.badge,
        widget: Container(child: Text('Perfis Tab')),
        permissoes: ['gestao_perfis'],
        descricao: 'Perfis de acesso',
      ),
      AdminMenuItem(
        titulo: 'Permissões',
        icone: Icons.security,
        widget: Container(child: Text('Permissões Tab')),
        permissoes: ['gestao_permissoes'],
        descricao: 'Configurar permissões',
      ),
      AdminMenuItem(
        titulo: 'Configurações',
        icone: Icons.settings,
        widget: Container(child: Text('Config Tab')),
        permissoes: ['configuracoes_sistema'],
        descricao: 'Configurações gerais',
      ),
      AdminMenuItem(
        titulo: 'Setores',
        icone: Icons.store,
        widget: Container(child: Text('Setores Tab')),
        permissoes: ['gestao_setores'],
        descricao: 'Setores da empresa',
      ),
      AdminMenuItem(
        titulo: 'Áreas',
        icone: Icons.location_on,
        widget: Container(child: Text('Áreas Tab')),
        permissoes: ['gestao_areas'],
        descricao: 'Áreas de venda',
      ),
    ];
  }
}

// ==========================================
// MODEL: Item do menu administrativo
// ==========================================
class AdminMenuItem {
  final String titulo;
  final IconData icone;
  final Widget widget;
  final List<String> permissoes;
  final String? descricao;

  AdminMenuItem({
    required this.titulo,
    required this.icone,
    required this.widget,
    this.permissoes = const [],
    this.descricao,
  });
}
