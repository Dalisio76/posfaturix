import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/relatorio_stock_repository.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/models/setor_model.dart';
import '../../../../core/utils/stock_printer_service.dart';

class RelatorioStockTab extends StatefulWidget {
  const RelatorioStockTab({Key? key}) : super(key: key);

  @override
  _RelatorioStockTabState createState() => _RelatorioStockTabState();
}

class _RelatorioStockTabState extends State<RelatorioStockTab> {
  final RelatorioStockRepository _relatorioRepo = Get.put(RelatorioStockRepository());
  final SetorRepository _setorRepo = Get.put(SetorRepository());

  final RxList<SetorModel> setores = <SetorModel>[].obs;
  final Rxn<SetorModel> setorSelecionado = Rxn<SetorModel>();

  final TextEditingController produtoController = TextEditingController();

  final RxList<Map<String, dynamic>> produtos = <Map<String, dynamic>>[].obs;
  final Rxn<Map<String, dynamic>> totais = Rxn<Map<String, dynamic>>();
  final RxInt linhaSelecionada = (-1).obs;
  final RxBool carregando = false.obs;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      setores.value = await _setorRepo.listarTodos();
      // Carregar produtos automaticamente
      await pesquisar();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> pesquisar() async {
    try {
      carregando.value = true;

      produtos.value = await _relatorioRepo.buscarProdutosComStock(
        setorId: setorSelecionado.value?.id,
        produtoNome: produtoController.text.isNotEmpty ? produtoController.text : null,
      );

      totais.value = await _relatorioRepo.buscarTotais(
        setorId: setorSelecionado.value?.id,
        produtoNome: produtoController.text.isNotEmpty ? produtoController.text : null,
      );

      Get.snackbar(
        'Sucesso',
        '${produtos.length} produtos com stock encontrados',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> imprimir() async {
    if (produtos.isEmpty || totais.value == null) {
      Get.snackbar('Aviso', 'Nenhum produto para imprimir');
      return;
    }

    try {
      final sucesso = await StockPrinterService.imprimirRelatorio(
        produtos: produtos,
        totais: totais.value!,
        setor: setorSelecionado.value?.nome,
        filtroNome: produtoController.text.isNotEmpty ? produtoController.text : null,
      );

      if (sucesso) {
        Get.snackbar(
          'Sucesso',
          'Relatório impresso com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Erro',
          'Falha ao imprimir relatório',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao imprimir: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Text(
              'RELATORIO DE STOCK',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SECTOR',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Obx(() {
                        final items = [
                          const DropdownMenuItem<SetorModel>(
                            value: null,
                            child: Text('TODOS', style: TextStyle(fontSize: 11)),
                          ),
                          ...setores.map((setor) {
                            return DropdownMenuItem(
                              value: setor,
                              child: Text(setor.nome, style: const TextStyle(fontSize: 11)),
                            );
                          }),
                        ];
                        return DropdownButtonFormField<SetorModel>(
                          value: setorSelecionado.value,
                          style: const TextStyle(fontSize: 11, color: Colors.black),
                          isDense: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            isDense: true,
                          ),
                          items: items,
                          onChanged: (value) => setorSelecionado.value = value,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PRODUTO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: produtoController,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: ElevatedButton(
                    onPressed: pesquisar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('PESQUISAR'),
                  ),
                ),
              ],
            ),
          ),

          // Totais
          Obx(() {
            if (totais.value == null) return const SizedBox.shrink();

            final t = totais.value!;
            final totalProdutos = t['total_produtos'] ?? 0;
            final totalQtd = double.tryParse(t['total_quantidade']?.toString() ?? '0') ?? 0;
            final totalVenda = double.tryParse(t['total_valor_venda']?.toString() ?? '0') ?? 0;
            final totalCompra = double.tryParse(t['total_valor_compra']?.toString() ?? '0') ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'PRODUTOS: $totalProdutos',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'QTD TOTAL: ${totalQtd.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'VALOR VENDA: ${NumberFormat('#,##0.00').format(totalVenda)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  Text(
                    'VALOR COMPRA: ${NumberFormat('#,##0.00').format(totalCompra)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
            );
          }),

          // Tabela
          Expanded(
            child: Obx(() {
              if (carregando.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (produtos.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum produto com stock encontrado.',
                    style: TextStyle(fontSize: 12),
                  ),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                    headingRowHeight: 24,
                    dataRowMinHeight: 20,
                    dataRowMaxHeight: 22,
                    columnSpacing: 8,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'CÓDIGO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'PRODUTO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'FAMILIA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'SETOR',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'QUANTIDADE',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'PREÇO VENDA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'PREÇO COMPRA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'VALOR VENDA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'VALOR COMPRA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    rows: produtos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      final quantidade = double.tryParse(item['quantidade']?.toString() ?? '0') ?? 0;
                      final preco = double.tryParse(item['preco']?.toString() ?? '0') ?? 0;
                      final precoCompra = double.tryParse(item['preco_compra']?.toString() ?? '0') ?? 0;
                      final valorVenda = double.tryParse(item['valor_venda']?.toString() ?? '0') ?? 0;
                      final valorCompra = double.tryParse(item['valor_compra']?.toString() ?? '0') ?? 0;

                      Color corLinha = index % 2 == 0 ? Colors.yellow[100]! : Colors.white;

                      if (linhaSelecionada.value == index) {
                        corLinha = Colors.blue[200]!;
                      }

                      return DataRow(
                        color: WidgetStateProperty.all(corLinha),
                        onSelectChanged: (_) => linhaSelecionada.value = index,
                        cells: [
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item['codigo'] ?? '',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item['produto_nome'] ?? '',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item['familia_nome'] ?? '',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item['setor_nome'] ?? '',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                quantidade.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                NumberFormat('#,##0.00').format(preco),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                NumberFormat('#,##0.00').format(precoCompra),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                NumberFormat('#,##0.00').format(valorVenda),
                                style: const TextStyle(fontSize: 11, color: Colors.green),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                NumberFormat('#,##0.00').format(valorCompra),
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            }),
          ),

          // Rodapé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: imprimir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('IMPRIMIR'),
                ),
                ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                  child: const Text('VOLTAR'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    produtoController.dispose();
    super.dispose();
  }
}
