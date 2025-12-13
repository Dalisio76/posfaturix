import 'dart:io' show exit;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/caixa_printer_service.dart';
import '../../../core/services/definicoes_service.dart';
import '../../data/repositories/empresa_repository.dart';
import 'controllers/vendas_controller.dart';
import 'widgets/dialog_pesquisa_produto.dart';
import 'widgets/teclado_numerico.dart';
import 'views/tela_devedores.dart';
import '../caixa/widgets/dialog_conferencia_manual.dart';
import '../caixa/controllers/caixa_controller.dart';
import '../login/login_page.dart';

class VendasPage extends StatefulWidget {
  const VendasPage({Key? key}) : super(key: key);

  @override
  State<VendasPage> createState() => _VendasPageState();
}

class _VendasPageState extends State<VendasPage> {
  final VendasController controller = Get.put(VendasController());
  final CaixaController caixaController = Get.put(CaixaController());
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final TextEditingController _barcodeController = TextEditingController();

  Timer? _inactivityTimer;
  bool _timeoutAtivo = true;
  int _timeoutSegundos = 30;
  bool _mostrarPedidos = true;
  bool _mostrarStock = true;
  int? _itemSelecionadoIndex;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _carregarConfiguracoes() async {
    try {
      final definicoes = await DefinicoesService.carregar();
      setState(() {
        _timeoutAtivo = definicoes.timeoutAtivo;
        _timeoutSegundos = definicoes.timeoutSegundos;
        _mostrarPedidos = definicoes.mostrarBotaoPedidos;
        _mostrarStock = definicoes.mostrarStockEmVendas;
      });

      if (_timeoutAtivo) {
        _resetarTimer();
      }
    } catch (e) {
      print('Erro ao carregar configurações: $e');
      // Usar valores padrão em caso de erro
      setState(() {
        _timeoutAtivo = true;
        _timeoutSegundos = 30;
        _mostrarPedidos = true;
        _mostrarStock = true;
      });
    }
  }

  void _resetarTimer() {
    if (!_timeoutAtivo) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _timeoutSegundos), () {
      // Voltar para login
      Get.offAll(() => LoginPage());
      // Nota: Snackbar removido pois contexto não existe após navegação
    });
  }

  void _registrarAtividade() {
    if (_timeoutAtivo) {
      _resetarTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _registrarAtividade(),
      onPointerMove: (_) => _registrarAtividade(),
      onPointerUp: (_) => _registrarAtividade(),
      child: Focus(
        autofocus: true,
        onKey: (node, event) {
          if (event is RawKeyDownEvent) {
            _registrarAtividade(); // Registrar atividade no teclado
            final key = event.logicalKey;

            // F1 - Pesquisar
            if (key == LogicalKeyboardKey.f1) {
              _abrirPesquisa();
              return KeyEventResult.handled;
            }
            // F2 - Finalizar Venda
            else if (key == LogicalKeyboardKey.f2) {
              controller.finalizarVenda();
              return KeyEventResult.handled;
            }
            // F3 - Pedido/Mesas (se habilitado)
            else if (key == LogicalKeyboardKey.f3 && _mostrarPedidos) {
              controller.abrirSelecaoMesa();
              return KeyEventResult.handled;
            }
            // F4 - Despesas
            else if (key == LogicalKeyboardKey.f4) {
              controller.abrirDialogDespesas();
              return KeyEventResult.handled;
            }
            // F5 - Fecho Caixa
            else if (key == LogicalKeyboardKey.f5) {
              _fecharCaixa();
              return KeyEventResult.handled;
            }
            // F6 - Clientes
            else if (key == LogicalKeyboardKey.f6) {
              Get.to(() => TelaDevedores());
              return KeyEventResult.handled;
            }
            // F7 - Atualizar
            else if (key == LogicalKeyboardKey.f7) {
              controller.carregarDados();
              return KeyEventResult.handled;
            }
            // F8 - Limpar
            else if (key == LogicalKeyboardKey.f8) {
              controller.limparCarrinho();
              setState(() {
                _itemSelecionadoIndex = null;
              });
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          drawer: _buildDrawer(),
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Get.offAll(() => LoginPage());
              },
              tooltip: 'Voltar ao Login',
            ),
            actions: [
              // Botão do Menu Drawer
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    ),
                    child: Text(
                      'MENU',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              // Botão de Pesquisa
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: _abrirPesquisa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                  child: Text(
                    'PESQUISAR (F1)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // Botão LIMPAR/REMOVER
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () {
                    if (_itemSelecionadoIndex != null) {
                      // Remover apenas o item selecionado
                      controller.removerDoCarrinho(_itemSelecionadoIndex!);
                      setState(() {
                        _itemSelecionadoIndex = null;
                      });
                    } else {
                      // Limpar todo o carrinho
                      controller.limparCarrinho();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                  child: Text(
                    _itemSelecionadoIndex != null ? 'REMOVER' : 'LIMPAR (F8)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: [
              // LADO ESQUERDO: Produtos
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Filtro por área
                    _buildFiltroAreas(),
                    Divider(height: 1),
                    // Filtro por família
                    _buildFiltroFamilias(),
                    Divider(height: 1),
                    // Grid de produtos
                    Expanded(child: _buildGridProdutos()),
                  ],
                ),
              ),

              // LADO DIREITO: Carrinho
              Container(
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    // Campo de scan de código de barras (MOVIDO AQUI)
                    _buildBarcodeScannerField(),
                    Divider(height: 1),
                    _buildHeaderCarrinho(),
                    Expanded(child: _buildListaCarrinho()),
                    _buildTotalCarrinho(),
                    _buildBotoesAcao(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Get.theme.primaryColor, Get.theme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu, size: 48, color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Opções Adicionais',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.money_off, color: Colors.red[700], size: 32),
            title: Text(
              'Despesas',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Atalho: F4'),
            onTap: () {
              Navigator.pop(context);
              controller.abrirDialogDespesas();
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.point_of_sale, color: Colors.purple[700], size: 32),
            title: Text(
              'Fecho Caixa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Atalho: F5'),
            onTap: () async {
              Navigator.pop(context);
              await _fecharCaixa();
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.people, color: Colors.green[700], size: 32),
            title: Text(
              'Clientes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Atalho: F6'),
            onTap: () {
              Navigator.pop(context);
              Get.to(() => TelaDevedores());
            },
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.refresh, color: Colors.teal[700], size: 32),
            title: Text(
              'Atualizar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Atalho: F7'),
            onTap: () {
              Navigator.pop(context);
              controller.carregarDados();
            },
          ),
        ],
      ),
    );
  }

  void _abrirPesquisa() {
    Get.dialog(
      DialogPesquisaProduto(
        produtos: controller.produtos,
        onProdutoSelecionado: (produto) {
          controller.adicionarAoCarrinho(produto);
        },
      ),
    );
  }

  void _processarCodigoBarras(String codigo) {
    if (codigo.isEmpty) return;

    // Buscar produto por código ou código de barras
    final produto = controller.produtos.firstWhereOrNull(
      (p) => p.codigo == codigo || p.codigoBarras == codigo,
    );

    if (produto != null) {
      controller.adicionarAoCarrinho(produto);
      _barcodeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Produto Adicionado',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${produto.nome} - ${Formatters.formatarMoeda(produto.preco)}',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      _barcodeController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Produto Não Encontrado',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Código "$codigo" não encontrado',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildBarcodeScannerField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.qr_code_scanner, color: Colors.blue[700], size: 16),
          SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                hintText: 'Scan...',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.blue[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.blue[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: Colors.blue[600]!, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                isDense: true,
              ),
              style: TextStyle(fontSize: 11),
              onSubmitted: _processarCodigoBarras,
              textInputAction: TextInputAction.search,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroAreas() {
    return Container(
      height: 80,
      padding: EdgeInsets.all(12),
      color: Colors.grey[200],
      child: Obx(() {
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: controller.areas.length,
          separatorBuilder: (context, index) => SizedBox(width: 10),
          itemBuilder: (context, index) {
            final area = controller.areas[index];
            final isSelected = controller.areaSelecionadaId == area['id'];

            return ChoiceChip(
              label: Text(
                area['nome'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              selected: isSelected,
              onSelected: (_) =>
                  controller.selecionarArea(isSelected ? null : area['id']),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFiltroFamilias() {
    return Container(
      height: 160,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          bottom: BorderSide(color: Colors.grey[400]!, width: 2),
        ),
      ),
      child: Obx(() {
        if (controller.familiasFiltradas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 28, color: Colors.grey[400]),
                SizedBox(height: 6),
                Text(
                  controller.areaSelecionadaId == null
                      ? 'Selecione uma área para ver categorias'
                      : 'Nenhuma categoria nesta área',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsivo: ajusta quantidade de colunas baseado na largura
            int crossAxisCount = constraints.maxWidth > 1200 ? 8 :
                                 constraints.maxWidth > 900 ? 6 :
                                 constraints.maxWidth > 600 ? 4 : 3;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: controller.familiasFiltradas.length,
              itemBuilder: (context, index) {
                final familia = controller.familiasFiltradas[index];
                final isSelected = controller.familiaSelecionada?.id == familia.id;

                return InkWell(
                  onTap: () => controller.selecionarFamilia(isSelected ? null : familia),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [Colors.blue[700]!, Colors.blue[500]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.white, Colors.grey[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))]
                          : [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Center(
                      child: Text(
                        familia.nome,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[800],
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  Widget _buildGridProdutos() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      if (controller.produtosFiltrados.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey[300]),
              SizedBox(height: 16),
              Text('Nenhum produto encontrado', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              SizedBox(height: 12),
              ElevatedButton(
                onPressed: _abrirPesquisa,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: Text('PESQUISAR'),
              ),
            ],
          ),
        );
      }

      return Container(
        color: Colors.grey[100],
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsivo: ajusta quantidade de colunas baseado na largura
            int crossAxisCount = constraints.maxWidth > 1400 ? 6 :
                                 constraints.maxWidth > 1100 ? 5 :
                                 constraints.maxWidth > 800 ? 4 :
                                 constraints.maxWidth > 500 ? 3 : 2;

            return GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.15,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: controller.produtosFiltrados.length,
              itemBuilder: (context, index) {
                final produto = controller.produtosFiltrados[index];
                return _buildCardProduto(produto);
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildCardProduto(produto) {
    // Definir cor baseada no estoque
    Color corEstoque = produto.estoque > 10 ? Colors.green[600]! :
                       produto.estoque > 0 ? Colors.orange[600]! : Colors.red[600]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.adicionarAoCarrinho(produto),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nome do Produto
                Text(
                  produto.nome,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[900],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),
                // Preço
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    Formatters.formatarMoeda(produto.preco),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Estoque (condicional)
                if (_mostrarStock) ...[
                  SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: corEstoque,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Stock: ${produto.estoque}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogQuantidade(produto) {
    final quantidadeController = TextEditingController(text: '1');

    Get.dialog(
      AlertDialog(
        title: Text('Adicionar ${produto.nome}', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quantidade:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle, size: 32, color: Colors.red),
                  onPressed: () {
                    int valor = int.tryParse(quantidadeController.text) ?? 1;
                    if (valor > 1) {
                      quantidadeController.text = (valor - 1).toString();
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, size: 32, color: Colors.green),
                  onPressed: () {
                    int valor = int.tryParse(quantidadeController.text) ?? 1;
                    quantidadeController.text = (valor + 1).toString();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              int quantidade = int.tryParse(quantidadeController.text) ?? 1;
              if (quantidade > 0) {
                for (int i = 0; i < quantidade; i++) {
                  controller.adicionarAoCarrinho(produto);
                }
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('ADICIONAR', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCarrinho() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Carrinho',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${controller.carrinho.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Get.theme.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCarrinho() {
    return Obx(() {
      if (controller.carrinho.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Carrinho vazio',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.carrinho.length,
        itemBuilder: (context, index) {
          final item = controller.carrinho[index];
          final isSelected = _itemSelecionadoIndex == index;

          return GestureDetector(
            onDoubleTap: () => _mostrarDialogQuantidadeCarrinho(index, item),
            onTap: () {
              setState(() {
                if (_itemSelecionadoIndex == index) {
                  _itemSelecionadoIndex = null; // Desselecionar
                } else {
                  _itemSelecionadoIndex = index; // Selecionar
                }
              });
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: isSelected ? Colors.blue[50] : Colors.white,
              elevation: isSelected ? 4 : 1,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    // Quantidade
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantidade}x',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.blue[900] : Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Nome do produto
                    Expanded(
                      child: Text(
                        item.produto.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isSelected ? Colors.blue[900] : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Subtotal (sem "MT")
                    Text(
                      '${item.subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue[700] : Get.theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _mostrarDialogQuantidadeCarrinho(int index, item) {
    String quantidadeTexto = '${item.quantidade}';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 400,
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  Text(
                    item.produto.nome,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 20),

                  // Display da quantidade
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: Text(
                      quantidadeTexto.isEmpty ? '0' : quantidadeTexto,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Get.theme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Teclado numérico
                  TecladoNumerico(
                    onNumeroPressed: (numero) {
                      setState(() {
                        if (numero == '.' && quantidadeTexto.contains('.')) return;
                        quantidadeTexto += numero;
                      });
                    },
                    onBackspace: () {
                      setState(() {
                        if (quantidadeTexto.isNotEmpty) {
                          quantidadeTexto = quantidadeTexto.substring(0, quantidadeTexto.length - 1);
                        }
                      });
                    },
                    onClear: () {
                      setState(() {
                        quantidadeTexto = '';
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text('CANCELAR', style: TextStyle(fontSize: 16)),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            int novaQuantidade = int.tryParse(quantidadeTexto) ?? 0;
                            if (novaQuantidade > 0) {
                              controller.atualizarQuantidade(index, novaQuantidade);
                              Get.back();
                            } else {
                              Get.snackbar(
                                'Erro',
                                'Digite uma quantidade válida',
                                backgroundColor: Colors.red[700],
                                colorText: Colors.white,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text('CONFIRMAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCarrinho() {
    return Obx(
      () => Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOTAL:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              Formatters.formatarMoeda(controller.totalCarrinho),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Get.theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotoesAcao() {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          // Botão de Pedidos/Mesas - Condicional
          if (_mostrarPedidos) ...[
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton(
                  onPressed: controller.abrirSelecaoMesa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.temProdutosNoCarrinho
                        ? Colors.orange[700]
                        : Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(18),
                  ),
                  child: Text(
                    controller.textoBotaoPedido,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: controller.finalizarVenda,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 42, color: Colors.white),
                        SizedBox(width: 16),
                        Text(
                          'FINALIZAR VENDA (F2)',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre dialog de fecho de caixa diretamente
  Future<void> _fecharCaixa() async {
    // Verificar se há caixa aberto
    await caixaController.verificarCaixaAtual();

    if (caixaController.caixaAtual.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text('Não há caixa aberto.', style: TextStyle(fontSize: 16)),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final caixa = caixaController.caixaAtual.value!;

    // Abrir dialog de conferência
    final resultadoConferencia = await Get.dialog<Map<String, dynamic>>(
      DialogConferenciaManual(caixa: caixa),
      barrierDismissible: false,
    );

    if (resultadoConferencia == null ||
        resultadoConferencia['conferido'] != true) {
      return;
    }

    // Fechar caixa
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final resultado = await caixaController.fecharCaixa();

      // Sempre fechar o loading
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (resultado != null) {
        // Caixa fechado com sucesso - Imprimir e fechar sistema
        await _imprimirEFecharSistema(caixa);
      }
      // Se resultado == null, significa que houve erro (ex: mesas abertas)
      // O controller já mostrou o dialog de aviso
    } catch (e) {
      // Fechar loading em caso de erro
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text('Erro ao fechar caixa: $e', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Imprimir relatório e fechar sistema
  Future<void> _imprimirEFecharSistema(caixa) async {
    try {
      // Carregar detalhes do caixa
      await caixaController.carregarDetalhes();

      // Buscar empresa
      final empresa = await _empresaRepo.buscarDados();

      // Mostrar dialog de impressão
      Get.defaultDialog(
        title: 'Caixa Fechado',
        barrierDismissible: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text(
              'Caixa fechado com sucesso!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Imprimindo relatório...'),
          ],
        ),
      );

      // Imprimir relatório
      await CaixaPrinterService.imprimirFechoCaixa(
        caixa,
        empresa,
        caixaController.despesas,
        caixaController.pagamentosDividas,
        caixaController.produtosVendidos,
      );

      // Fechar dialog
      Get.back();

      // Mostrar mensagem de encerramento
      Get.defaultDialog(
        title: 'Encerrando Sistema',
        barrierDismissible: false,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('O sistema será encerrado em 3 segundos...'),
          ],
        ),
      );

      // Aguardar 3 segundos e fechar
      await Future.delayed(Duration(seconds: 3));
      exit(0);
    } catch (e) {
      Get.back(); // Fechar dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text('Erro ao imprimir relatório: $e', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      // Mesmo com erro na impressão, perguntar se quer fechar o sistema
      final fechar = await Get.defaultDialog<bool>(
        title: 'Fechar Sistema?',
        content: Text('Deseja fechar o sistema mesmo assim?'),
        textConfirm: 'SIM',
        textCancel: 'NÃO',
        onConfirm: () => Get.back(result: true),
        onCancel: () => Get.back(result: false),
      );

      if (fechar == true) {
        exit(0);
      }
    }
  }
}
