import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/vendedor_operador_controller.dart';

class VendedorOperadorTab extends StatelessWidget {
  const VendedorOperadorTab({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VendedorOperadorController());

    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Text(
              'RELATORIO VENDEDOR/OPERADOR',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[100],
            child: Row(
              children: [
                // Data Início
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATA INICIO',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => InkWell(
                        onTap: () => controller.selecionarDataInicio(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                controller.dataInicio.value != null
                                    ? controller.formatarData(controller.dataInicio.value!)
                                    : 'Selecione',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Data Fim
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DATA FIM',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => InkWell(
                        onTap: () => controller.selecionarDataFim(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                controller.dataFim.value != null
                                    ? controller.formatarData(controller.dataFim.value!)
                                    : 'Selecione',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Botão Filtrar
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: ElevatedButton(
                    onPressed: controller.filtrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
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
                    child: const Text('FILTRAR'),
                  ),
                ),
                const SizedBox(width: 16),

                // Total de vendedores
                Obx(() => Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Text(
                    'VENDEDORES: ${controller.estatisticas.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                )),
              ],
            ),
          ),

          // Tabela
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.estatisticas.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum vendedor encontrado no periodo.',
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
                    columnSpacing: 12,
                    horizontalMargin: 8,
                    columns: const [
                      DataColumn(
                        label: Padding(
                          padding: EdgeInsets.all(2),
                          child: Text(
                            'RANK',
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
                            'VENDEDOR',
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
                            'EMAIL',
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
                            'VENDAS',
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
                            'TOTAL',
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
                            'TICKET MEDIO',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    rows: controller.estatisticas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      // Cores alternadas com destaque para top 3
                      Color corLinha;
                      if (item.ranking == 1) {
                        corLinha = Colors.yellow[100]!; // Ouro
                      } else if (item.ranking == 2) {
                        corLinha = Colors.grey[300]!; // Prata
                      } else if (item.ranking == 3) {
                        corLinha = Colors.orange[100]!; // Bronze
                      } else {
                        corLinha = index % 2 == 0 ? Colors.white : Colors.grey[50]!;
                      }

                      return DataRow(
                        color: WidgetStateProperty.all(corLinha),
                        cells: [
                          // Ranking
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (item.ranking == 1)
                                    const Icon(Icons.emoji_events, size: 14, color: Colors.amber)
                                  else if (item.ranking == 2)
                                    const Icon(Icons.emoji_events, size: 14, color: Colors.grey)
                                  else if (item.ranking == 3)
                                    const Icon(Icons.emoji_events, size: 14, color: Colors.orange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${item.ranking}º',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: item.ranking! <= 3 ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Nome
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item.nome,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: item.ranking! <= 3 ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Email
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                item.email,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),

                          // Quantidade de Vendas
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                '${item.quantidadeVendas}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                maxLines: 1,
                              ),
                            ),
                          ),

                          // Valor Total
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                controller.formatarMoeda(item.valorTotal),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: item.ranking! <= 3 ? Colors.green[800] : Colors.green[600],
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),

                          // Ticket Médio
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                controller.formatarMoeda(item.ticketMedio),
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
                Obx(() {
                  if (controller.estatisticas.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final totalVendas = controller.estatisticas
                      .fold<int>(0, (sum, e) => sum + e.quantidadeVendas);
                  final totalValor = controller.estatisticas
                      .fold<double>(0, (sum, e) => sum + e.valorTotal);

                  return Row(
                    children: [
                      Text(
                        'TOTAL VENDAS: $totalVendas',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        'TOTAL VALOR: ${controller.formatarMoeda(totalValor)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  );
                }),
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
}
