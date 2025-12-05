import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/produtos_pedidos_controller.dart';
import '../../../../core/utils/formatters.dart';

class ProdutosPedidosTab extends StatelessWidget {
  const ProdutosPedidosTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProdutosPedidosController());

    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Text(
              'PRODUTOS PEDIDOS',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // Filtros
          _buildFiltros(controller, context),

          // Contador de resultados
          Obx(() {
            final total = controller.pedidos.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    'Total: $total produto${total != 1 ? 's' : ''} pedido${total != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),

          // Tabela
          Expanded(
            child: _buildTabela(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros(ProdutosPedidosController controller, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[100],
      child: Column(
        children: [
          // Primeira linha: Produto, Operador, Mesa
          Row(
            children: [
              // Dropdown Produto
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
                    Obx(() {
                      final items = [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('TODOS', style: TextStyle(fontSize: 11)),
                        ),
                        ...controller.produtos.map((produto) {
                          return DropdownMenuItem(
                            value: produto,
                            child: Text(
                              produto.nome,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ];
                      return DropdownButtonFormField(
                        initialValue: controller.produtoSelecionado.value,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        items: items,
                        onChanged: (value) => controller.produtoSelecionado.value = value,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Dropdown Operador
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OPERADOR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final items = [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('TODOS', style: TextStyle(fontSize: 11)),
                        ),
                        ...controller.operadores.map((operador) {
                          return DropdownMenuItem(
                            value: operador,
                            child: Text(
                              operador.nome,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ];
                      return DropdownButtonFormField(
                        initialValue: controller.operadorSelecionado.value,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        items: items,
                        onChanged: (value) => controller.operadorSelecionado.value = value,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // TextField Mesa
            ],
          ),
          const SizedBox(height: 8),

          // Segunda linha: Caixa e Botões
          Row(
            children: [
              // Dropdown Caixa
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAIXA (ABERTURA/FECHO)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Obx(() {
                      final items = [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('TODOS OS CAIXAS', style: TextStyle(fontSize: 11)),
                        ),
                        ...controller.caixas.map((caixa) {
                          final abertura = DateFormat('dd/MM/yy HH:mm').format(caixa.dataAbertura);
                          final fecho = caixa.dataFechamento != null
                              ? DateFormat('dd/MM/yy HH:mm').format(caixa.dataFechamento!)
                              : 'ABERTO';
                          final statusIcon = caixa.status == 'ABERTO' ? '🟢' : '🔴';

                          return DropdownMenuItem(
                            value: caixa,
                            child: Text(
                              '$statusIcon ${caixa.numero} - $abertura → $fecho',
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ];
                      return DropdownButtonFormField(
                        value: controller.caixaSelecionado.value,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        items: items,
                        onChanged: (value) => controller.caixaSelecionado.value = value,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Botão Filtrar
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ElevatedButton.icon(
                  onPressed: () => controller.aplicarFiltros(),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('FILTRAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Limpar
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: ElevatedButton.icon(
                  onPressed: () => controller.limparFiltros(),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('LIMPAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabela(ProdutosPedidosController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (controller.pedidos.isEmpty) {
        return const Center(
          child: Text(
            'Nenhum produto pedido encontrado.',
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
                    'DATA/HORA',
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
                    'QTD',
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
                    'PREÇO',
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
                    'OPERADOR',
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
                    'VENDA',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            rows: controller.pedidos.asMap().entries.map((entry) {
              final index = entry.key;
              final pedido = entry.value;

              final Color corLinha = index % 2 == 0 ? Colors.yellow[100]! : Colors.white;

              return DataRow(
                color: WidgetStateProperty.all(corLinha),
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(pedido.dataHora),
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
                        pedido.produtoNome,
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
                        pedido.quantidade.toString(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        Formatters.formatarMoeda(pedido.preco),
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                      ),
                    ),
                  ),
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.all(2),
                      child: Text(
                        pedido.operadorNome,
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
                        pedido.vendaNumero,
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
    });
  }
}
