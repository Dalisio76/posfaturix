import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/fatura_entrada_repository.dart';
import '../../../data/repositories/fornecedor_repository.dart';
import '../../../data/models/fatura_entrada_model.dart';
import '../../../data/models/fornecedor_model.dart';

class RelatorioFaturasTab extends StatefulWidget {
  const RelatorioFaturasTab({Key? key}) : super(key: key);

  @override
  _RelatorioFaturasTabState createState() => _RelatorioFaturasTabState();
}

class _RelatorioFaturasTabState extends State<RelatorioFaturasTab> {
  final FaturaEntradaRepository _faturaRepo = Get.find<FaturaEntradaRepository>();
  final FornecedorRepository _fornecedorRepo = Get.find<FornecedorRepository>();

  final RxList<FaturaEntradaModel> faturas = <FaturaEntradaModel>[].obs;
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;
  final Rxn<FornecedorModel> fornecedorSelecionado = Rxn<FornecedorModel>();

  final Rxn<DateTime> dataInicio = Rxn<DateTime>(DateTime.now().subtract(const Duration(days: 30)));
  final Rxn<DateTime> dataFim = Rxn<DateTime>(DateTime.now());

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      fornecedores.value = await _fornecedorRepo.listarTodos();
      await consultar();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> consultar() async {
    try {
      faturas.value = await _faturaRepo.buscarPorPeriodo(
        dataInicio: DateTime(
          dataInicio.value!.year,
          dataInicio.value!.month,
          dataInicio.value!.day,
          0,
          0,
          0,
        ),
        dataFim: DateTime(
          dataFim.value!.year,
          dataFim.value!.month,
          dataFim.value!.day,
          23,
          59,
          59,
        ),
        fornecedorId: fornecedorSelecionado.value?.id,
      );

      Get.snackbar(
        'Sucesso',
        '${faturas.length} faturas encontradas',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao consultar faturas: $e');
    }
  }

  Future<void> verDetalhes(int faturaId) async {
    try {
      final dados = await _faturaRepo.buscarPorId(faturaId);

      if (dados == null) {
        Get.snackbar('Erro', 'Fatura não encontrada');
        return;
      }

      final fatura = dados['fatura'] as FaturaEntradaModel;
      final itens = dados['itens'] as List<ItemFaturaEntradaModel>;

      Get.dialog(
        AlertDialog(
          title: Text('Fatura: ${fatura.numeroFatura}'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fornecedor: ${fatura.fornecedorNome}'),
                Text('Data: ${DateFormat('dd/MM/yyyy').format(fatura.dataFatura)}'),
                if (fatura.observacoes != null) Text('Obs: ${fatura.observacoes}'),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Itens:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Table(
                      border: TableBorder.all(color: Colors.grey[300]!),
                      columnWidths: const {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(3),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.5),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey[200]),
                          children: const [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('PRODUTO', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('QUANT', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('PREÇO', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('SUBTOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        ...itens.map((item) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item.produtoCodigo ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item.produtoNome ?? ''),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(item.quantidade.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text('MT ${item.precoUnitario.toStringAsFixed(2)}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'MT ${item.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                Text(
                  'TOTAL: MT ${fatura.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('FECHAR'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar detalhes: $e');
    }
  }

  Future<void> confirmarExcluir(int id, String numeroFatura) async {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir a fatura $numeroFatura?\n\nO estoque dos produtos será revertido.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _faturaRepo.deletar(id);
                Get.back();
                Get.snackbar(
                  'Sucesso',
                  'Fatura excluída e estoque revertido',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                consultar();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao excluir fatura: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Faturas de Entrada'),
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => _selecionarData(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data Início',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(dataInicio.value!),
                          ),
                        ),
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => InkWell(
                        onTap: () => _selecionarData(context, false),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Data Fim',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(dataFim.value!),
                          ),
                        ),
                      )),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Obx(() => DropdownButtonFormField<FornecedorModel>(
                        value: fornecedorSelecionado.value,
                        decoration: const InputDecoration(
                          labelText: 'Fornecedor (Todos)',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<FornecedorModel>(
                            value: null,
                            child: Text('Todos os fornecedores'),
                          ),
                          ...fornecedores.map((fornecedor) {
                            return DropdownMenuItem(
                              value: fornecedor,
                              child: Text(fornecedor.nome),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) => fornecedorSelecionado.value = value,
                      )),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: consultar,
                  icon: const Icon(Icons.search),
                  label: const Text('CONSULTAR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),
              ],
            ),
          ),

          // Lista de faturas
          Expanded(
            child: Obx(() {
              if (faturas.isEmpty) {
                return const Center(
                  child: Text('Nenhuma fatura encontrada'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: faturas.length,
                itemBuilder: (context, index) {
                  final fatura = faturas[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Get.theme.primaryColor,
                        child: const Icon(Icons.receipt_long, color: Colors.white),
                      ),
                      title: Text(
                        'Fatura: ${fatura.numeroFatura}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fornecedor: ${fatura.fornecedorNome}'),
                          Text('Data: ${DateFormat('dd/MM/yyyy').format(fatura.dataFatura)}'),
                          Text(
                            'Total: MT ${fatura.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.blue),
                            onPressed: () => verDetalhes(fatura.id!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmarExcluir(fatura.id!, fatura.numeroFatura),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),

          // Rodapé com totais
          Obx(() {
            if (faturas.isEmpty) return const SizedBox.shrink();

            final totalGeral = faturas.fold<double>(
              0.0,
              (sum, fatura) => sum + fatura.total,
            );

            return Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[200],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de Faturas: ${faturas.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Total Geral: MT ${totalGeral.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio
          ? (dataInicio.value ?? DateTime.now())
          : (dataFim.value ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isInicio) {
        dataInicio.value = picked;
      } else {
        dataFim.value = picked;
      }
    }
  }
}
