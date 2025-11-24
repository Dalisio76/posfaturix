import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/familia_model.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/venda_model.dart';
import '../../../data/models/item_venda_model.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/models/empresa_model.dart';
import '../../../data/models/pagamento_venda_model.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/models/divida_model.dart';
import '../../../data/repositories/familia_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/venda_repository.dart';
import '../../../data/repositories/forma_pagamento_repository.dart';
import '../../../data/repositories/empresa_repository.dart';
import '../../../data/repositories/divida_repository.dart';
import '../../../data/repositories/area_repository.dart';
import '../../../data/repositories/pedido_repository.dart';
import '../../../data/repositories/mesa_repository.dart';
import '../../../data/models/pedido_model.dart';
import '../../../data/models/item_pedido_model.dart';
import '../../../data/models/mesa_model.dart';
import '../../../../core/utils/windows_printer_service.dart';
import '../../../../core/services/definicoes_service.dart';
import '../../../../core/services/auth_service.dart';
import '../widgets/dialog_pagamento.dart';
import '../widgets/dialog_despesas.dart';
import '../widgets/dialog_selecao_mesa.dart';
import '../widgets/dialog_gerenciar_pedidos.dart';
import '../../caixa/controllers/caixa_controller.dart';

class ItemCarrinho {
  final ProdutoModel produto;
  int quantidade;

  ItemCarrinho({required this.produto, this.quantidade = 1});

  double get subtotal => produto.preco * quantidade;
}

class VendasController extends GetxController {
  final AreaRepository _areaRepo = AreaRepository();
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final VendaRepository _vendaRepo = VendaRepository();
  final FormaPagamentoRepository _formaPagamentoRepo =
      FormaPagamentoRepository();
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final DividaRepository _dividaRepo = DividaRepository();
  final PedidoRepository _pedidoRepo = PedidoRepository();
  final MesaRepository _mesaRepo = MesaRepository();

  // Referência ao CaixaController para validação de caixa aberto
  final CaixaController _caixaController = Get.put(CaixaController());
  final AuthService _authService = Get.find<AuthService>();

  // Pedido/Mesa atual
  final Rxn<PedidoModel> pedidoAtual = Rxn<PedidoModel>();
  final Rxn<MesaModel> mesaAtual = Rxn<MesaModel>();

  final areas = <Map<String, dynamic>>[].obs;
  final familias = <FamiliaModel>[].obs;
  final familiasFiltradas = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
  final produtosFiltrados = <ProdutoModel>[].obs;
  final carrinho = <ItemCarrinho>[].obs;
  final formasPagamento = <FormaPagamentoModel>[].obs;
  final formaPagamentoSelecionada = Rxn<FormaPagamentoModel>();
  final empresa = Rxn<EmpresaModel>();
  final isLoading = false.obs;

  int? areaSelecionadaId;
  FamiliaModel? familiaSelecionada;

  @override
  void onInit() {
    super.onInit();
    carregarDados();
  }

  Future<void> carregarDados() async {
    isLoading.value = true;
    try {
      final areasData = await _areaRepo.listarTodas();
      areas.value = areasData.map((a) => {
        'id': a.id,
        'nome': a.nome,
      }).toList();

      familias.value = await _familiaRepo.listarTodas();
      // Não mostrar famílias até selecionar uma área
      familiasFiltradas.value = [];
      produtos.value = await _produtoRepo.listarTodos();
      formasPagamento.value = await _formaPagamentoRepo.listarTodas();
      empresa.value = await _empresaRepo.buscarDados();
      produtosFiltrados.value = produtos;
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selecionarArea(int? areaId) {
    areaSelecionadaId = areaId;
    familiaSelecionada = null;

    if (areaId == null) {
      // Não mostrar famílias quando desseleciona área
      familiasFiltradas.value = [];
      produtosFiltrados.value = produtos;
    } else {
      // Filtrar produtos por área
      final produtosDaArea = produtos.where((p) => p.areaId == areaId).toList();

      // Extrair IDs únicos das famílias desses produtos
      final familiaIds = produtosDaArea
          .where((p) => p.familiaId != null)
          .map((p) => p.familiaId!)
          .toSet()
          .toList();

      // Filtrar famílias que têm produtos nesta área
      familiasFiltradas.value = familias
          .where((f) => familiaIds.contains(f.id))
          .toList();

      // Mostrar produtos da área selecionada
      produtosFiltrados.value = produtosDaArea;
    }
  }

  void selecionarFamilia(FamiliaModel? familia) {
    familiaSelecionada = familia;

    if (familia == null) {
      // Se desselecionar família, volta a mostrar todos os produtos da área
      if (areaSelecionadaId != null) {
        produtosFiltrados.value = produtos
            .where((p) => p.areaId == areaSelecionadaId)
            .toList();
      } else {
        produtosFiltrados.value = produtos;
      }
    } else {
      // Mostrar produtos da família E da área selecionada
      if (areaSelecionadaId != null) {
        produtosFiltrados.value = produtos
            .where((p) => p.familiaId == familia.id && p.areaId == areaSelecionadaId)
            .toList();
      } else {
        produtosFiltrados.value = produtos
            .where((p) => p.familiaId == familia.id)
            .toList();
      }
    }
  }

  void adicionarAoCarrinho(ProdutoModel produto) {
    // Verificar se já está no carrinho
    final index = carrinho.indexWhere((item) => item.produto.id == produto.id);

    if (index >= 0) {
      // Aumentar quantidade
      carrinho[index].quantidade++;
      carrinho.refresh();
    } else {
      // Adicionar novo item
      carrinho.add(ItemCarrinho(produto: produto));
    }
  }

  void removerDoCarrinho(int index) {
    carrinho.removeAt(index);
  }

  void aumentarQuantidade(int index) {
    carrinho[index].quantidade++;
    carrinho.refresh();
  }

  void diminuirQuantidade(int index) {
    if (carrinho[index].quantidade > 1) {
      carrinho[index].quantidade--;
      carrinho.refresh();
    }
  }

  double get totalCarrinho {
    return carrinho.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> finalizarVenda() async {
    if (carrinho.isEmpty) {
      Get.snackbar('Erro', 'Carrinho vazio');
      return;
    }

    // FASE 1: Validar e abrir caixa automaticamente se necessário
    if (!_caixaController.existeCaixaAberto.value) {
      // Mostrar dialog de confirmação
      final confirmar = await Get.dialog<bool>(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text('Abrir Caixa'),
            ],
          ),
          content: Text(
            'Não há caixa aberto. Deseja abrir o caixa automaticamente para realizar esta venda?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('SIM, ABRIR CAIXA'),
            ),
          ],
        ),
      );

      if (confirmar != true) {
        return; // Usuário cancelou
      }

      // Abrir caixa automaticamente
      final sucesso = await _caixaController.abrirCaixa(
        terminal: 'CAIXA-01',
        usuario: 'Sistema',
      );

      if (!sucesso) {
        Get.snackbar(
          'Erro',
          'Não foi possível abrir o caixa. Tente novamente.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Mostrar dialog de pagamento
    final result = await Get.dialog<Map<String, dynamic>>(
      DialogPagamento(
        formasPagamento: formasPagamento,
        valorTotal: totalCarrinho,
      ),
      barrierDismissible: false,
    );

    if (result != null) {
      await _processarVenda(result);
    }
  }

  Future<void> _processarVenda(Map<String, dynamic> resultado) async {
    try {
      final List<PagamentoVendaModel> pagamentos =
          resultado['pagamentos'] ?? [];
      final bool modoDivida = resultado['modoDivida'] ?? false;
      final ClienteModel? cliente = resultado['cliente'];
      final double valorRestante = resultado['valorRestante'] ?? 0;

      // Gerar número da venda
      final numero = 'VD${DateTime.now().millisecondsSinceEpoch}';

      // Criar venda
      final vendaData = VendaModel(
        numero: numero,
        total: totalCarrinho,
        dataVenda: DateTime.now(),
        terminal: 'CAIXA-01',
      );

      // Criar itens
      final itens = carrinho.map((item) {
        return ItemVendaModel(
          produtoId: item.produto.id!,
          quantidade: item.quantidade,
          precoUnitario: item.produto.preco,
          subtotal: item.subtotal,
          produtoNome: item.produto.nome,
        );
      }).toList();

      // Registrar venda no banco
      final vendaId = await _vendaRepo.registrarVenda(
        vendaData,
        itens,
        pagamentos,
      );

      // Se for venda a crédito, registrar dívida
      if (modoDivida && cliente != null && valorRestante > 0) {
        await _registrarDivida(
          vendaId,
          cliente.id!,
          valorRestante,
          pagamentos.fold(0.0, (sum, p) => sum + p.valor),
        );
      }

      // Criar venda completa com ID
      final vendaCompleta = VendaModel(
        id: vendaId,
        numero: numero,
        total: totalCarrinho,
        dataVenda: DateTime.now(),
        terminal: 'CAIXA-01',
      );

      // Verificar configuração de impressão
      final definicoes = await DefinicoesService.carregar();

      if (definicoes.perguntarAntesDeImprimir) {
        // Perguntar se deseja imprimir
        final resultado = await Get.dialog<bool>(
          AlertDialog(
            title: Row(
              children: [
                Icon(Icons.print, color: Colors.blue),
                SizedBox(width: 10),
                Text('Imprimir Recibo?'),
              ],
            ),
            content: Text('Deseja imprimir o recibo desta venda?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('NÃO'),
              ),
              ElevatedButton.icon(
                onPressed: () => Get.back(result: true),
                icon: Icon(Icons.print),
                label: Text('SIM, IMPRIMIR'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
        );

        if (resultado == true) {
          await _imprimirEFinalizar(vendaCompleta, itens, pagamentos);
        } else {
          _finalizarSemImprimir();
        }
      } else {
        // Imprimir automaticamente
        await _imprimirEFinalizar(vendaCompleta, itens, pagamentos);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao finalizar venda: $e');
    }
  }

  Future<void> _imprimirEFinalizar(
    VendaModel venda,
    List<ItemVendaModel> itens,
    List<PagamentoVendaModel> pagamentos,
  ) async {
    // Mostrar loading
    Get.dialog(
      Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Imprimindo recibo...'),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // Tentar imprimir
    final sucesso = await WindowsPrinterService.imprimirCupom(
      venda,
      itens,
      empresa.value,
      pagamentos,
    );

    Get.back(); // Fechar loading

    _finalizarSemImprimir();
  }

  void _finalizarSemImprimir() {
    // Limpar carrinho
    carrinho.clear();

    // Atualizar produtos (estoque mudou)
    carregarDados();
  }

  void limparCarrinho() {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja limpar o carrinho?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              carrinho.clear();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('LIMPAR'),
          ),
        ],
      ),
    );
  }

  // ===== DESPESAS =====
  void abrirDialogDespesas() {
    Get.dialog(
      DialogDespesas(formasPagamento: formasPagamento),
      barrierDismissible: false,
    );
  }

  // ===== DÍVIDAS =====
  Future<void> _registrarDivida(
    int vendaId,
    int clienteId,
    double valorRestante,
    double valorPago,
  ) async {
    try {
      final divida = DividaModel(
        clienteId: clienteId,
        vendaId: vendaId,
        valorTotal: totalCarrinho,
        valorPago: valorPago,
        valorRestante: valorRestante,
        dataDivida: DateTime.now(),
      );

      await _dividaRepo.inserir(divida);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao registrar dívida: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ===== PEDIDOS / MESAS =====

  /// Abre dialog para selecionar mesa ou gerenciar pedidos
  Future<void> abrirSelecaoMesa() async {
    if (carrinho.isEmpty) {
      // Sem produtos no carrinho = abrir gerenciamento de pedidos
      await abrirGerenciamentoPedidos();
    } else {
      // Com produtos no carrinho = selecionar mesa para criar pedido
      final mesa = await Get.dialog<MesaModel>(
        DialogSelecaoMesa(),
        barrierDismissible: false,
      );

      if (mesa != null) {
        await _criarPedidoNaMesa(mesa);
      }
    }
  }

  /// Abre dialog de gerenciamento de pedidos
  Future<void> abrirGerenciamentoPedidos() async {
    final resultado = await Get.dialog<Map<String, dynamic>>(
      DialogGerenciarPedidos(),
      barrierDismissible: false,
    );

    if (resultado != null) {
      // Usuário selecionou finalizar um pedido
      await _processarPagamentoPedido(resultado);
    }
  }

  /// Cria pedido na mesa selecionada ou adiciona itens ao pedido existente
  Future<void> _criarPedidoNaMesa(MesaModel mesa) async {
    try {
      final usuarioId = _authService.usuarioLogado.value?.id;
      if (usuarioId == null) {
        Get.snackbar('Erro', 'Usuário não autenticado');
        return;
      }

      int pedidoId;

      // Verificar se a mesa já tem um pedido aberto
      if (mesa.isOcupada && mesa.pedidoId != null) {
        // Mesa já tem pedido - adicionar itens ao pedido existente
        pedidoId = mesa.pedidoId!;

        Get.snackbar(
          'Adicionando',
          'Adicionando itens ao pedido existente da Mesa ${mesa.numero}',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      } else {
        // Mesa livre - criar novo pedido
        final numeroPedido = 'PD${DateTime.now().millisecondsSinceEpoch}';

        final pedido = PedidoModel(
          numero: numeroPedido,
          mesaId: mesa.id!,
          usuarioId: usuarioId,
          status: 'aberto',
        );

        pedidoId = await _pedidoRepo.criar(pedido);

        Get.snackbar(
          'Sucesso',
          'Pedido criado na Mesa ${mesa.numero}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 2),
        );
      }

      // Adicionar itens do carrinho ao pedido
      final itens = carrinho.map((item) {
        return ItemPedidoModel(
          pedidoId: pedidoId,
          produtoId: item.produto.id!,
          produtoNome: item.produto.nome,
          quantidade: item.quantidade,
          precoUnitario: item.produto.preco,
          subtotal: item.subtotal,
        );
      }).toList();

      await _pedidoRepo.adicionarItens(itens);

      // Limpar carrinho
      carrinho.clear();

      // Atualizar dados para refletir mudanças
      await carregarDados();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao processar pedido: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Verifica se deve mostrar "PEDIDOS" ou "MESA"
  String get textoBotaoPedido {
    return carrinho.isEmpty ? 'PEDIDOS' : 'MESA';
  }

  /// Getter para saber se tem produtos no carrinho
  bool get temProdutosNoCarrinho => carrinho.isNotEmpty;

  /// Processa pagamento de pedido de mesa
  Future<void> _processarPagamentoPedido(Map<String, dynamic> dados) async {
    try {
      final MesaModel mesa = dados['mesa'];
      final PedidoModel pedido = dados['pedido'];
      final List<ItemPedidoModel> itens = dados['itens'];

      // Abrir dialog de pagamento
      final resultadoPagamento = await Get.dialog<Map<String, dynamic>>(
        DialogPagamento(
          formasPagamento: formasPagamento,
          valorTotal: pedido.total,
        ),
        barrierDismissible: false,
      );

      if (resultadoPagamento == null) return;

      final List<PagamentoVendaModel> pagamentos =
          resultadoPagamento['pagamentos'] ?? [];
      final bool modoDivida = resultadoPagamento['modoDivida'] ?? false;
      final ClienteModel? cliente = resultadoPagamento['cliente'];
      final double valorRestante = resultadoPagamento['valorRestante'] ?? 0;

      // Gerar número da venda
      final numeroVenda = 'VD${DateTime.now().millisecondsSinceEpoch}';

      // Criar venda
      final vendaData = VendaModel(
        numero: numeroVenda,
        total: pedido.total,
        dataVenda: DateTime.now(),
        terminal: 'CAIXA-01',
      );

      // Converter itens do pedido em itens de venda
      final itensVenda = itens.map((item) {
        return ItemVendaModel(
          produtoId: item.produtoId,
          quantidade: item.quantidade,
          precoUnitario: item.precoUnitario,
          subtotal: item.subtotal,
          produtoNome: item.produtoNome,
        );
      }).toList();

      // Registrar venda no banco
      final vendaId = await _vendaRepo.registrarVenda(
        vendaData,
        itensVenda,
        pagamentos,
      );

      // Se for venda a crédito, registrar dívida
      if (modoDivida && cliente != null && valorRestante > 0) {
        await _registrarDivida(
          vendaId,
          cliente.id!,
          valorRestante,
          pagamentos.fold(0.0, (sum, p) => sum + p.valor),
        );
      }

      // Fechar pedido
      await _pedidoRepo.fechar(pedido.id!);

      Get.snackbar(
        'Sucesso',
        'Pedido da Mesa ${mesa.numero} finalizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Recarregar dados
      await carregarDados();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao finalizar pedido: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
