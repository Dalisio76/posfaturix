import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/venda_repository.dart';

class EstatisticaVendedor {
  final int usuarioId;
  final String nome;
  final String email;
  final int quantidadeVendas;
  final double valorTotal;
  final double ticketMedio;
  int? ranking;

  EstatisticaVendedor({
    required this.usuarioId,
    required this.nome,
    required this.email,
    required this.quantidadeVendas,
    required this.valorTotal,
    required this.ticketMedio,
    this.ranking,
  });
}

class VendedorOperadorController extends GetxController {
  final VendaRepository _vendaRepo = VendaRepository();

  final RxList<EstatisticaVendedor> estatisticas = <EstatisticaVendedor>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime?> dataInicio = Rx<DateTime?>(null);
  final Rx<DateTime?> dataFim = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    // Inicializar com últimos 30 dias
    final hoje = DateTime.now();
    dataInicio.value = DateTime(hoje.year, hoje.month, hoje.day - 30);
    dataFim.value = DateTime(hoje.year, hoje.month, hoje.day, 23, 59, 59);
    carregarEstatisticas();
  }

  Future<void> carregarEstatisticas() async {
    try {
      isLoading.value = true;

      final resultado = await _vendaRepo.buscarEstatisticasVendedores(
        dataInicio.value!,
        dataFim.value!,
      );

      // Converter resultado em objetos EstatisticaVendedor
      final lista = resultado.map((row) {
        return EstatisticaVendedor(
          usuarioId: row['usuario_id'] as int,
          nome: row['nome'] as String,
          email: row['email'] as String,
          quantidadeVendas: row['quantidade_vendas'] as int,
          valorTotal: row['valor_total'] as double,
          ticketMedio: row['ticket_medio'] as double,
        );
      }).toList();

      estatisticas.value = lista;

      // Atribuir ranking
      for (int i = 0; i < estatisticas.length; i++) {
        estatisticas[i].ranking = i + 1;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar estatísticas: $e',
        backgroundColor: Colors.red[700],
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selecionarDataInicio(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataInicio.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );

    if (data != null) {
      dataInicio.value = DateTime(data.year, data.month, data.day, 0, 0, 0);
    }
  }

  Future<void> selecionarDataFim(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: dataFim.value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );

    if (data != null) {
      dataFim.value = DateTime(data.year, data.month, data.day, 23, 59, 59);
    }
  }

  void filtrar() {
    carregarEstatisticas();
  }

  String formatarMoeda(double valor) {
    return NumberFormat.currency(locale: 'pt_PT', symbol: '€', decimalDigits: 2).format(valor);
  }

  String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }
}
