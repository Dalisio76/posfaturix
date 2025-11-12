import 'package:get/get.dart';
import '../../../data/models/caixa_model.dart';
import '../../../data/models/caixa_detalhe_model.dart';
import '../../../data/repositories/caixa_repository.dart';

class CaixaController extends GetxController {
  final CaixaRepository _repository = CaixaRepository();

  final Rx<CaixaModel?> caixaAtual = Rx<CaixaModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool existeCaixaAberto = false.obs;

  // Detalhes do caixa
  final RxList<DespesaDetalhe> despesas = <DespesaDetalhe>[].obs;
  final RxList<PagamentoDividaDetalhe> pagamentosDividas = <PagamentoDividaDetalhe>[].obs;
  final RxList<ResumoProdutoVendido> produtosVendidos = <ResumoProdutoVendido>[].obs;

  @override
  void onInit() {
    super.onInit();
    verificarCaixaAtual();
  }

  /// Verificar se existe caixa aberto e carregá-lo
  Future<void> verificarCaixaAtual() async {
    try {
      isLoading.value = true;
      final caixa = await _repository.buscarCaixaAtual();

      if (caixa != null) {
        caixaAtual.value = caixa;
        existeCaixaAberto.value = true;
      } else {
        caixaAtual.value = null;
        existeCaixaAberto.value = false;
      }
    } catch (e) {
      print('Erro ao verificar caixa atual: $e');
      Get.snackbar(
        'Erro',
        'Erro ao verificar caixa: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Abrir um novo caixa
  Future<bool> abrirCaixa({
    String terminal = 'TERMINAL-01',
    String usuario = 'Sistema',
  }) async {
    try {
      isLoading.value = true;

      // Verificar se já existe caixa aberto
      if (existeCaixaAberto.value) {
        Get.snackbar(
          'Atenção',
          'Já existe um caixa aberto. Feche o caixa atual antes de abrir um novo.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      final caixaId = await _repository.abrirCaixa(
        terminal: terminal,
        usuario: usuario,
      );

      Get.snackbar(
        'Sucesso',
        'Caixa aberto com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recarregar caixa atual
      await verificarCaixaAtual();

      return true;
    } catch (e) {
      print('Erro ao abrir caixa: $e');
      Get.snackbar(
        'Erro',
        'Erro ao abrir caixa: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualizar totais do caixa atual
  Future<void> atualizarTotais() async {
    try {
      if (caixaAtual.value == null) {
        return;
      }

      isLoading.value = true;
      await _repository.calcularTotais(caixaAtual.value!.id!);

      // Recarregar dados do caixa
      final caixa = await _repository.buscarResumo(caixaAtual.value!.id!);
      if (caixa != null) {
        caixaAtual.value = caixa;
      }

      // Carregar detalhes
      await carregarDetalhes();
    } catch (e) {
      print('Erro ao atualizar totais: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carregar detalhes do caixa (despesas, pagamentos, produtos)
  Future<void> carregarDetalhes() async {
    try {
      if (caixaAtual.value == null) {
        return;
      }

      final caixaId = caixaAtual.value!.id!;

      // Carregar em paralelo
      final results = await Future.wait([
        _repository.buscarDespesas(caixaId),
        _repository.buscarPagamentosDividas(caixaId),
        _repository.buscarProdutosVendidos(caixaId),
      ]);

      despesas.value = results[0] as List<DespesaDetalhe>;
      pagamentosDividas.value = results[1] as List<PagamentoDividaDetalhe>;
      produtosVendidos.value = results[2] as List<ResumoProdutoVendido>;
    } catch (e) {
      print('Erro ao carregar detalhes: $e');
    }
  }

  /// Fechar o caixa atual
  Future<Map<String, dynamic>?> fecharCaixa({String? observacoes}) async {
    try {
      if (caixaAtual.value == null) {
        Get.snackbar(
          'Atenção',
          'Não há caixa aberto para fechar.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      isLoading.value = true;

      final resultado = await _repository.fecharCaixa(
        caixaAtual.value!.id!,
        observacoes: observacoes,
      );

      Get.snackbar(
        'Sucesso',
        'Caixa ${resultado['numero_caixa']} fechado com sucesso!',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Limpar caixa atual
      caixaAtual.value = null;
      existeCaixaAberto.value = false;

      return resultado;
    } catch (e) {
      print('Erro ao fechar caixa: $e');
      Get.snackbar(
        'Erro',
        'Erro ao fechar caixa: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar resumo do caixa com validação
  Future<CaixaModel?> buscarResumo() async {
    try {
      if (caixaAtual.value == null) {
        return null;
      }

      isLoading.value = true;
      final caixa = await _repository.buscarResumo(caixaAtual.value!.id!);

      if (caixa != null) {
        caixaAtual.value = caixa;
      }

      // Carregar detalhes
      await carregarDetalhes();

      return caixa;
    } catch (e) {
      print('Erro ao buscar resumo: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
