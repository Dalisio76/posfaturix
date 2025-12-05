import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/venda_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/repositories/usuario_repository.dart';
import '../../../data/repositories/caixa_repository.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/usuario_model.dart';
import '../../../data/models/caixa_model.dart';

class ProdutoPedido {
  final int vendaId;
  final String vendaNumero;
  final String produtoNome;
  final int quantidade;
  final double preco;
  final String operadorNome;
  final DateTime dataHora;

  ProdutoPedido({
    required this.vendaId,
    required this.vendaNumero,
    required this.produtoNome,
    required this.quantidade,
    required this.preco,
    required this.operadorNome,
    required this.dataHora,
  });
}

class ProdutosPedidosController extends GetxController {
  final VendaRepository _vendaRepo = VendaRepository();
  final ProdutoRepository _produtoRepo = Get.put(ProdutoRepository());
  final UsuarioRepository _usuarioRepo = Get.put(UsuarioRepository());
  final CaixaRepository _caixaRepo = CaixaRepository();

  final RxList<ProdutoPedido> pedidos = <ProdutoPedido>[].obs;
  final RxBool isLoading = false.obs;

  // Filtros
  final Rxn<ProdutoModel> produtoSelecionado = Rxn<ProdutoModel>();
  final Rxn<UsuarioModel> operadorSelecionado = Rxn<UsuarioModel>();
  final Rxn<CaixaModel> caixaSelecionado = Rxn<CaixaModel>();

  // Listas para dropdowns
  final RxList<ProdutoModel> produtos = <ProdutoModel>[].obs;
  final RxList<UsuarioModel> operadores = <UsuarioModel>[].obs;
  final RxList<CaixaModel> caixas = <CaixaModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    carregarDadosIniciais();
  }

  Future<void> carregarDadosIniciais() async {
    try {
      isLoading.value = true;

      // Carregar produtos, operadores e caixas para os dropdowns
      produtos.value = await _produtoRepo.listarTodos();
      operadores.value = await _usuarioRepo.listarAtivos();
      caixas.value = await _caixaRepo.listarCaixas(limit: 100);

      // Carregar pedidos
      await carregarPedidos();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados iniciais: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> carregarPedidos() async {
    try {
      isLoading.value = true;

      // Obter datas de início e fim do caixa selecionado
      DateTime? dataInicio;
      DateTime? dataFim;

      if (caixaSelecionado.value != null) {
        dataInicio = caixaSelecionado.value!.dataAbertura;
        dataFim = caixaSelecionado.value!.dataFechamento ?? DateTime.now();
      }

      final resultado = await _vendaRepo.buscarProdutosPedidos(
        produtoId: produtoSelecionado.value?.id,
        operadorId: operadorSelecionado.value?.id,
        dataInicio: dataInicio,
        dataFim: dataFim,
      );

      pedidos.value = resultado.map((map) {
        return ProdutoPedido(
          vendaId: map['venda_id'] as int,
          vendaNumero: map['venda_numero']?.toString() ?? 'N/A',
          produtoNome: map['produto_nome'] as String,
          quantidade: map['quantidade'] as int,
          preco: double.parse(map['preco_unitario'].toString()),
          operadorNome: map['operador_nome'] as String,
          dataHora: DateTime.parse(map['data_hora'].toString()),
        );
      }).toList();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar pedidos: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void limparFiltros() {
    produtoSelecionado.value = null;
    operadorSelecionado.value = null;
    caixaSelecionado.value = null;
    carregarPedidos();
  }

  void aplicarFiltros() {
    carregarPedidos();
  }
}
