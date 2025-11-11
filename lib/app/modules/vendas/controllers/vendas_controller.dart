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
import '../../../../core/utils/windows_printer_service.dart';
import '../widgets/dialog_pagamento.dart';
import '../widgets/dialog_despesas.dart';

class ItemCarrinho {
  final ProdutoModel produto;
  int quantidade;

  ItemCarrinho({required this.produto, this.quantidade = 1});

  double get subtotal => produto.preco * quantidade;
}

class VendasController extends GetxController {
  final FamiliaRepository _familiaRepo = FamiliaRepository();
  final ProdutoRepository _produtoRepo = ProdutoRepository();
  final VendaRepository _vendaRepo = VendaRepository();
  final FormaPagamentoRepository _formaPagamentoRepo = FormaPagamentoRepository();
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  final DividaRepository _dividaRepo = DividaRepository();

  final familias = <FamiliaModel>[].obs;
  final produtos = <ProdutoModel>[].obs;
  final produtosFiltrados = <ProdutoModel>[].obs;
  final carrinho = <ItemCarrinho>[].obs;
  final formasPagamento = <FormaPagamentoModel>[].obs;
  final formaPagamentoSelecionada = Rxn<FormaPagamentoModel>();
  final empresa = Rxn<EmpresaModel>();
  final isLoading = false.obs;

  FamiliaModel? familiaSelecionada;

  @override
  void onInit() {
    super.onInit();
    carregarDados();
  }

  Future<void> carregarDados() async {
    isLoading.value = true;
    try {
      familias.value = await _familiaRepo.listarTodas();
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

  void selecionarFamilia(FamiliaModel? familia) {
    familiaSelecionada = familia;
    if (familia == null) {
      produtosFiltrados.value = produtos;
    } else {
      produtosFiltrados.value =
          produtos.where((p) => p.familiaId == familia.id).toList();
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

    Get.snackbar(
      'Adicionado',
      '${produto.nome} adicionado ao carrinho',
      duration: Duration(seconds: 1),
    );
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
      final List<PagamentoVendaModel> pagamentos = resultado['pagamentos'] ?? [];
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
      final vendaId = await _vendaRepo.registrarVenda(vendaData, itens, pagamentos);

      // Se for venda a crédito, registrar dívida
      if (modoDivida && cliente != null && valorRestante > 0) {
        await _registrarDivida(vendaId, cliente.id!, valorRestante, pagamentos.fold(0.0, (sum, p) => sum + p.valor));
      }

      // Criar venda completa com ID
      final vendaCompleta = VendaModel(
        id: vendaId,
        numero: numero,
        total: totalCarrinho,
        dataVenda: DateTime.now(),
        terminal: 'CAIXA-01',
      );

      Get.snackbar(
        'Sucesso',
        'Venda #$vendaId registrada com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Perguntar se deseja imprimir
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              Icon(Icons.print, color: Colors.blue),
              SizedBox(width: 10),
              Text('Imprimir Cupom?'),
            ],
          ),
          content: Text('Deseja imprimir o cupom desta venda?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                _finalizarSemImprimir();
              },
              child: Text('NÃO'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Get.back();
                await _imprimirEFinalizar(vendaCompleta, itens, pagamentos);
              },
              icon: Icon(Icons.print),
              label: Text('SIM, IMPRIMIR'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ],
        ),
      );
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
                Text('Imprimindo cupom...'),
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

    if (sucesso) {
      Get.snackbar(
        'Sucesso',
        'Cupom impresso com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        'Aviso',
        'Erro ao imprimir. Venda registrada no sistema.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    }

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
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
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
  Future<void> _registrarDivida(int vendaId, int clienteId, double valorRestante, double valorPago) async {
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

      Get.snackbar(
        'Dívida Registrada',
        'Valor restante: MT ${valorRestante.toStringAsFixed(2)}',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao registrar dívida: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
