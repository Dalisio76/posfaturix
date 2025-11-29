import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/database/database_service.dart';
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
import 'views/acerto_stock_tab.dart';
import 'views/fornecedores_tab.dart';
import 'views/faturas_entrada_tab.dart';
import 'views/relatorio_stock_tab.dart';
import 'views/mesas_tab.dart';
import 'views/perfis_usuario_tab.dart';
import 'views/usuarios_tab.dart';
import 'views/configurar_permissoes_tab.dart';
import 'views/impressoras_tab.dart';
import 'views/mapeamento_impressoras_tab.dart';
import '../definicoes/definicoes_page.dart';

// ==========================================
// NOVA INTERFACE DE ADMINISTRAÇÃO
// Design moderno, touch-friendly, organizado
// ==========================================

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AdminController controller = Get.put(AdminController());
  final AuthService authService = Get.find<AuthService>();
  final RxString searchQuery = ''.obs;
  final Rxn<AdminMenuItem> selectedItem = Rxn<AdminMenuItem>();
  final RxList<String> breadcrumb = <String>['Dashboard'].obs;

  // Estatísticas
  final RxInt totalProdutos = 0.obs;
  final RxInt totalClientes = 0.obs;
  final RxString mesasInfo = '---'.obs;
  final RxInt totalUsuarios = 0.obs;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    try {
      final db = Get.find<DatabaseService>();

      // Total produtos
      final prodResult = await db.query('SELECT COUNT(*) as total FROM produtos');
      totalProdutos.value = prodResult.first['total'] as int;

      // Total clientes
      final clientesResult = await db.query('SELECT COUNT(*) as total FROM clientes');
      totalClientes.value = clientesResult.first['total'] as int;

      // Mesas (total e ocupadas)
      final mesasResult = await db.query('''
        SELECT
          COUNT(DISTINCT m.id) as total,
          COUNT(DISTINCT CASE WHEN p.status = 'aberto' THEN m.id END) as ocupadas
        FROM mesas m
        LEFT JOIN pedidos p ON p.mesa_id = m.id AND p.status = 'aberto'
      ''');
      if (mesasResult.isNotEmpty) {
        final total = mesasResult.first['total'] as int;
        final ocupadas = mesasResult.first['ocupadas'] as int;
        mesasInfo.value = '$ocupadas/$total';
      }

      // Total usuários
      final userResult = await db.query('SELECT COUNT(*) as total FROM usuarios');
      totalUsuarios.value = userResult.first['total'] as int;
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  Future<bool> _confirmarSaida() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Confirmar Saída'),
          ],
        ),
        content: Text(
          'Tem certeza que deseja sair da administração?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'CANCELAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'SIM, SAIR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Se estiver visualizando um item, volta ao dashboard
        if (selectedItem.value != null) {
          selectedItem.value = null;
          breadcrumb.value = ['Dashboard'];
          return false;
        }
        // Se estiver no dashboard, pede confirmação para sair
        return await _confirmarSaida();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _buildAppBar(),
        body: Obx(() => selectedItem.value == null
            ? _buildDashboard()
            : _buildConteudo()),
      ),
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
          onPressed: () async {
            // Se estiver em um item, volta ao dashboard
            if (selectedItem.value != null) {
              selectedItem.value = null;
              breadcrumb.value = ['Dashboard'];
            } else {
              // Se estiver no dashboard, pede confirmação para sair
              final confirmar = await _confirmarSaida();
              if (confirmar) {
                Get.back();
              }
            }
          },
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

          // Estatísticas rápidas (placeholder - implementar queries reais depois)
          _buildEstatisticasRapidas(),
          SizedBox(height: 32),

          // Categorias de menu
          _buildCategoria(
            'PRODUTOS',
            Colors.blue,
            _getCadastrosBasicos(),
          ),
          SizedBox(height: 24),

          _buildCategoria(
            'STOCK',
            Colors.green,
            _getStock(),
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
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Produtos',
            totalProdutos.value.toString(),
            Icons.inventory,
            Colors.blue,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Clientes Ativos',
            totalClientes.value.toString(),
            Icons.people,
            Colors.green,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Mesas',
            mesasInfo.value,
            Icons.table_restaurant,
            Colors.orange,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Usuários',
            totalUsuarios.value.toString(),
            Icons.person,
            Colors.purple,
          ),
        ),
      ],
    ));
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
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsividade: ajustar colunas baseado na largura
            int crossAxisCount = 5;
            if (constraints.maxWidth < 1400) crossAxisCount = 4;
            if (constraints.maxWidth < 1100) crossAxisCount = 3;
            if (constraints.maxWidth < 800) crossAxisCount = 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3, // Cards retangulares
              ),
              itemCount: itensFiltrados.length,
              itemBuilder: (context, index) {
                return _buildMenuCard(itensFiltrados[index], cor);
              },
            );
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
        if (item.permissoes.isNotEmpty) {
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                item.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
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
            color: Colors.white,
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
        titulo: 'Produtos',
        icone: Icons.inventory,
        widget: ProdutosTab(),
        permissoes: ['registar_produtos'],
        descricao: 'Catálogo de produtos',
      ),
      AdminMenuItem(
        titulo: 'Famílias',
        icone: Icons.category,
        widget: FamiliasTab(),
        permissoes: ['registar_familias'],
        descricao: 'Categorias de produtos',
      ),
      AdminMenuItem(
        titulo: 'Clientes',
        icone: Icons.people,
        widget: ClientesTab(),
        permissoes: ['registar_clientes'],
        descricao: 'Cadastro de clientes',
      ),
      AdminMenuItem(
        titulo: 'Fornecedores',
        icone: Icons.local_shipping,
        widget: FornecedoresTab(),
        permissoes: ['registar_fornecedores'],
        descricao: 'Gestão de fornecedores',
      ),
    ];
  }

  List<AdminMenuItem> _getStock() {
    return [
      AdminMenuItem(
        titulo: 'Faturas Entrada',
        icone: Icons.receipt_long,
        widget: FaturasEntradaTab(),
        permissoes: ['entrada_stock'],
        descricao: 'Registro de compras',
      ),
      AdminMenuItem(
        titulo: 'Acerto Stock',
        icone: Icons.inventory_2,
        widget: AcertoStockTab(),
        permissoes: ['acerto_stock'],
        descricao: 'Ajustes de estoque',
      ),
      AdminMenuItem(
        titulo: 'Despesas',
        icone: Icons.money_off,
        widget: DespesasTab(),
        permissoes: ['registar_despesas'],
        descricao: 'Controle de despesas',
      ),
      AdminMenuItem(
        titulo: 'Pagamentos',
        icone: Icons.payment,
        widget: FormasPagamentoTab(),
        permissoes: ['acesso_admin'],
        descricao: 'Formas de pagamento',
      ),
    ];
  }

  List<AdminMenuItem> _getRelatorios() {
    return [
      AdminMenuItem(
        titulo: 'Relatórios',
        icone: Icons.analytics,
        widget: RelatoriosTab(),
        permissoes: ['relatorios'],
        descricao: 'Relatórios gerais',
      ),
      AdminMenuItem(
        titulo: 'Margens/Lucros',
        icone: Icons.trending_up,
        widget: MargensTab(),
        permissoes: ['relatorios'],
        descricao: 'Análise de margens',
      ),
      AdminMenuItem(
        titulo: 'Stock',
        icone: Icons.warehouse,
        widget: RelatorioStockTab(),
        permissoes: ['relatorios'],
        descricao: 'Relatório de estoque',
      ),
    ];
  }

  List<AdminMenuItem> _getSistema() {
    return [
      AdminMenuItem(
        titulo: 'Empresa',
        icone: Icons.business,
        widget: EmpresaTab(),
        permissoes: ['configuracoes_sistema'],
        descricao: 'Dados da empresa',
      ),
      AdminMenuItem(
        titulo: 'Mesas',
        icone: Icons.table_restaurant,
        widget: MesasTab(),
        permissoes: ['acesso_admin'],
        descricao: 'Configuração de mesas',
      ),
      AdminMenuItem(
        titulo: 'Usuários',
        icone: Icons.person,
        widget: UsuariosTab(),
        permissoes: ['gestao_usuarios'],
        descricao: 'Gerenciar usuários',
      ),
      AdminMenuItem(
        titulo: 'Perfis',
        icone: Icons.badge,
        widget: PerfisUsuarioTab(),
        permissoes: ['gestao_perfis'],
        descricao: 'Perfis de acesso',
      ),
      AdminMenuItem(
        titulo: 'Permissões',
        icone: Icons.security,
        widget: ConfigurarPermissoesTab(),
        permissoes: ['gestao_permissoes'],
        descricao: 'Configurar permissões',
      ),
      AdminMenuItem(
        titulo: 'Impressoras',
        icone: Icons.print,
        widget: ImpressorasTab(),
        permissoes: ['acesso_admin'],
        descricao: 'Gestão de impressoras',
      ),
      AdminMenuItem(
        titulo: 'Mapeamento Impressão',
        icone: Icons.settings_ethernet,
        widget: MapeamentoImpressorasTab(),
        permissoes: ['acesso_admin'],
        descricao: 'Documentos e impressoras',
      ),
      AdminMenuItem(
        titulo: 'Configurações',
        icone: Icons.settings,
        widget: DefinicoesPage(),
        permissoes: ['configuracoes_sistema'],
        descricao: 'Configurações gerais',
      ),
      AdminMenuItem(
        titulo: 'Setores',
        icone: Icons.store,
        widget: SetoresTab(),
        permissoes: ['registar_setores'],
        descricao: 'Setores da empresa',
      ),
      AdminMenuItem(
        titulo: 'Áreas',
        icone: Icons.location_on,
        widget: AreasTab(),
        permissoes: ['acesso_admin'],
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
