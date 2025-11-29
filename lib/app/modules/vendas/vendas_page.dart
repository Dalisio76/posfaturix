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

  Timer? _inactivityTimer;
  bool _timeoutAtivo = true;
  int _timeoutSegundos = 30;
  bool _mostrarPedidos = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _carregarConfiguracoes() async {
    try {
      final definicoes = await DefinicoesService.carregar();
      setState(() {
        _timeoutAtivo = definicoes.timeoutAtivo;
        _timeoutSegundos = definicoes.timeoutSegundos;
        _mostrarPedidos = definicoes.mostrarBotaoPedidos;
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
      });
    }
  }

  void _resetarTimer() {
    if (!_timeoutAtivo) return;

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(seconds: _timeoutSegundos), () {
      // Voltar para login
      Get.offAll(() => LoginPage());
      Get.snackbar(
        'Sessão Expirada',
        'Você foi desconectado por inatividade',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
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
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          appBar: AppBar(
            actions: [
              // Botão DESPESAS
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: controller.abrirDialogDespesas,
                  icon: Icon(Icons.money_off, size: 24),
                  label: Text(
                    'DESPESAS (F4)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              // Botão FECHO DE CAIXA
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _fecharCaixa();
                  },
                  icon: Icon(Icons.point_of_sale, size: 24),
                  label: Text(
                    'FECHO CAIXA (F5)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              // Botão CLIENTES - Abre tela de devedores
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => TelaDevedores());
                  },
                  icon: Icon(Icons.people, size: 24),
                  label: Text(
                    'CLIENTES (F6)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              // Botão de Pesquisa
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: _abrirPesquisa,
                  icon: Icon(Icons.search, size: 24),
                  label: Text(
                    'PESQUISAR (F1)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              // Botão ATUALIZAR
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: controller.carregarDados,
                  icon: Icon(Icons.refresh, size: 24),
                  label: Text(
                    'ATUALIZAR (F7)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
              ),
              // Botão LIMPAR
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: controller.limparCarrinho,
                  icon: Icon(Icons.delete_sweep, size: 24),
                  label: Text(
                    'LIMPAR (F8)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                width: 380,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
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
      height: 150,
      padding: EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Obx(() {
        if (controller.familiasFiltradas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 32, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  controller.areaSelecionadaId == null
                      ? 'Selecione uma área acima para ver as famílias'
                      : 'Nenhuma família cadastrada nesta área',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.0,
          ),
          itemCount: controller.familiasFiltradas.length,
          itemBuilder: (context, index) {
            final familia = controller.familiasFiltradas[index];
            final isSelected = controller.familiaSelecionada?.id == familia.id;

            return FilterChip(
              label: Text(
                familia.nome,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
              selected: isSelected,
              onSelected: (_) =>
                  controller.selecionarFamilia(isSelected ? null : familia),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              selectedColor: Get.theme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
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
              Icon(Icons.inbox, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Nenhum produto encontrado', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _abrirPesquisa,
                icon: Icon(Icons.search),
                label: Text('PESQUISAR'),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio:
              1.2, // Aumentado para cards mais largos e baixos (sem ícone)
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: controller.produtosFiltrados.length,
        itemBuilder: (context, index) {
          final produto = controller.produtosFiltrados[index];
          return _buildCardProduto(produto);
        },
      );
    });
  }

  Widget _buildCardProduto(produto) {
    return InkWell(
      onTap: () => controller.adicionarAoCarrinho(produto),
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nome
              Text(
                produto.nome,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6),
              // Preço
              Text(
                Formatters.formatarMoeda(produto.preco),
                style: TextStyle(
                  color: Get.theme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 2),
              // Estoque
              Text(
                'Estoque: ${produto.estoque}',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCarrinho() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Get.theme.primaryColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.white, size: 22),
          SizedBox(width: 8),
          Text(
            'CARRINHO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.carrinho.length}',
                style: TextStyle(
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
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.produto.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => controller.removerDoCarrinho(index),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      // Controles de quantidade
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => controller.diminuirQuantidade(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.remove, size: 18),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                '${item.quantidade}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => controller.aumentarQuantidade(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.add, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      // Subtotal
                      Text(
                        Formatters.formatarMoeda(item.subtotal),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Get.theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
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
                child: ElevatedButton.icon(
                  onPressed: controller.abrirSelecaoMesa,
                  icon: Icon(
                    controller.temProdutosNoCarrinho
                        ? Icons.table_restaurant
                        : Icons.receipt_long,
                    size: 28,
                  ),
                  label: Text(
                    controller.textoBotaoPedido,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.temProdutosNoCarrinho
                        ? Colors.orange[700]
                        : Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(18),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 80,
            child: ElevatedButton.icon(
              onPressed: controller.finalizarVenda,
              icon: Icon(Icons.payment, size: 32),
              label: Text(
                'FINALIZAR VENDA (F2)',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(20),
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
      Get.snackbar(
        'Atenção',
        'Não há caixa aberto.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
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

      Get.snackbar(
        'Erro',
        'Erro ao fechar caixa: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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

      Get.snackbar(
        'Erro',
        'Erro ao imprimir relatório: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
