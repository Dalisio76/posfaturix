import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/caixa_model.dart';
import '../../../data/models/caixa_detalhe_model.dart';
import '../../../data/repositories/caixa_repository.dart';
import '../../../data/repositories/pedido_repository.dart';
import '../../../../core/database/database_service.dart';

class CaixaController extends GetxController {
  final CaixaRepository _repository = CaixaRepository();
  final PedidoRepository _pedidoRepository = PedidoRepository();
  final DatabaseService _db = Get.find<DatabaseService>();

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
      print('🔍 Verificando caixa atual...');

      final caixa = await _repository.buscarCaixaAtual();

      if (caixa != null) {
        print('✅ Caixa encontrado: ${caixa.numero} - Saldo: ${caixa.saldoFinal}');
        caixaAtual.value = caixa;
        existeCaixaAberto.value = true;
      } else {
        print('⚠️ Nenhum caixa aberto encontrado');
        caixaAtual.value = null;
        existeCaixaAberto.value = false;
      }
    } catch (e) {
      print('❌ Erro ao verificar caixa atual: $e');
      Get.snackbar(
        'Erro',
        'Erro ao verificar caixa: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
        print('⚠️ Não é possível atualizar totais: caixa atual é null');
        Get.snackbar(
          'Atenção',
          'Nenhum caixa aberto para atualizar',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      isLoading.value = true;
      print('🔄 Atualizando totais do caixa ${caixaAtual.value!.numero}...');

      await _repository.calcularTotais(caixaAtual.value!.id!);

      // Recarregar dados do caixa
      final caixa = await _repository.buscarResumo(caixaAtual.value!.id!);
      if (caixa != null) {
        caixaAtual.value = caixa;
        print('✅ Totais atualizados - Saldo: ${caixa.saldoFinal}');
      }

      // Carregar detalhes
      await carregarDetalhes();

      Get.snackbar(
        'Sucesso',
        'Dados atualizados!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 1),
      );
    } catch (e) {
      print('❌ Erro ao atualizar totais: $e');
      Get.snackbar(
        'Erro',
        'Erro ao atualizar: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carregar detalhes do caixa (despesas, pagamentos, produtos)
  Future<void> carregarDetalhes() async {
    try {
      if (caixaAtual.value == null) {
        print('⚠️ Não é possível carregar detalhes: caixa atual é null');
        return;
      }

      final caixaId = caixaAtual.value!.id!;
      print('📊 Carregando detalhes do caixa ID: $caixaId');

      // Carregar em paralelo
      final results = await Future.wait([
        _repository.buscarDespesas(caixaId),
        _repository.buscarPagamentosDividas(caixaId),
        _repository.buscarProdutosVendidos(caixaId),
      ]);

      despesas.value = results[0] as List<DespesaDetalhe>;
      pagamentosDividas.value = results[1] as List<PagamentoDividaDetalhe>;
      produtosVendidos.value = results[2] as List<ResumoProdutoVendido>;

      print('✅ Detalhes carregados: ${despesas.length} despesas, ${pagamentosDividas.length} pagamentos, ${produtosVendidos.length} produtos');
    } catch (e) {
      print('❌ Erro ao carregar detalhes: $e');
      Get.snackbar(
        'Erro',
        'Erro ao carregar detalhes: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }

  /// Fechar o caixa atual
  Future<Map<String, dynamic>?> fecharCaixa({String? observacoes}) async {
    print('[CaixaController] Iniciando fechamento de caixa...');
    try {
      if (caixaAtual.value == null) {
        print('[CaixaController] ERRO: Caixa atual é null');
        Get.snackbar(
          'Atenção',
          'Não há caixa aberto para fechar.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      print('[CaixaController] Caixa ID: ${caixaAtual.value!.id}');

      // Verificar se há pedidos abertos (mesas ocupadas)
      print('[CaixaController] Verificando pedidos abertos...');
      final pedidosAbertos = await _db.query('''
        SELECT COUNT(*) as total FROM pedidos WHERE status = 'aberto'
      ''');

      final totalPedidosAbertos = pedidosAbertos.first['total'] as int;
      print('[CaixaController] Total de pedidos abertos: $totalPedidosAbertos');

      if (totalPedidosAbertos > 0) {
        print('[CaixaController] ERRO: Existem mesas ocupadas');
        Get.defaultDialog(
          title: 'Não é possível fechar o caixa',
          titleStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                'Existem $totalPedidosAbertos mesa(s) com pedidos abertos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'Finalize todos os pedidos antes de fechar o caixa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          textConfirm: 'ENTENDI',
          confirmTextColor: Colors.white,
          buttonColor: Colors.orange,
        );
        return null;
      }

      print('[CaixaController] Setando isLoading = true');
      isLoading.value = true;

      print('[CaixaController] Chamando repository.fecharCaixa...');
      final resultado = await _repository.fecharCaixa(
        caixaAtual.value!.id!,
        observacoes: observacoes,
      );
      print('[CaixaController] Repository retornou: $resultado');

      // Limpar caixa atual
      print('[CaixaController] Limpando caixa atual...');
      caixaAtual.value = null;
      existeCaixaAberto.value = false;

      print('[CaixaController] Caixa fechado com sucesso');
      return resultado;
    } catch (e, stackTrace) {
      print('[CaixaController] ERRO ao fechar caixa: $e');
      print('[CaixaController] StackTrace: $stackTrace');
      Get.snackbar(
        'Erro',
        'Erro ao fechar caixa: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      print('[CaixaController] Setando isLoading = false');
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
