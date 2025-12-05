import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/stock_baixo_controller.dart';

class StockBaixoTab extends StatelessWidget {
  const StockBaixoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StockBaixoController());

    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: const Text(
              'RELATORIO DE STOCK BAIXO',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    // Filtro Família
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FAMILIA',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            final items = [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('TODAS', style: TextStyle(fontSize: 11)),
                              ),
                              ...controller.familias.map((familia) {
                                return DropdownMenuItem(
                                  value: familia.id,
                                  child: Text(familia.nome, style: const TextStyle(fontSize: 11)),
                                );
                              }),
                            ];
                            return DropdownButtonFormField<int?>(
                              value: controller.familiaSelecionada.value?.id,
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
                              onChanged: (value) {
                                if (value == null) {
                                  controller.setFamilia(null);
                                } else {
                                  final familia = controller.familias.firstWhereOrNull((f) => f.id == value);
                                  controller.setFamilia(familia);
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filtro Setor
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SETOR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            final items = [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('TODOS', style: TextStyle(fontSize: 11)),
                              ),
                              ...controller.setores.map((setor) {
                                return DropdownMenuItem(
                                  value: setor.id,
                                  child: Text(setor.nome, style: const TextStyle(fontSize: 11)),
                                );
                              }),
                            ];
                            return DropdownButtonFormField<int?>(
                              value: controller.setorSelecionado.value?.id,
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
                              onChanged: (value) {
                                if (value == null) {
                                  controller.setSetor(null);
                                } else {
                                  final setor = controller.setores.firstWhereOrNull((s) => s.id == value);
                                  controller.setSetor(setor);
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Filtro Nível de Alerta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NIVEL',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            return DropdownButtonFormField<NivelAlerta>(
                              value: controller.nivelSelecionado.value,
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
                              items: NivelAlerta.values.map((nivel) {
                                return DropdownMenuItem(
                                  value: nivel,
                                  child: Text(nivel.label, style: const TextStyle(fontSize: 11)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.setNivel(value);
                                }
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botões
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: controller.carregarProdutosStockBaixo,
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
                            child: const Text('ATUALIZAR'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: controller.limparFiltros,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
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
                            child: const Text('LIMPAR'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Totais por nível
          Obx(() {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTotalChip(
                    'CRITICO',
                    controller.totalProdutosCritico.value,
                    Colors.red[700]!,
                  ),
                  _buildTotalChip(
                    'BAIXO',
                    controller.totalProdutosBaixo.value,
                    Colors.orange[700]!,
                  ),
                  _buildTotalChip(
                    'ALERTA',
                    controller.totalProdutosAlerta.value,
                    Colors.yellow[800]!,
                  ),
                  _buildTotalChip(
                    'TOTAL',
                    controller.produtosFiltrados.length,
                    Colors.blue[700]!,
                  ),
                ],
              ),
            );
          }),

          // Tabela
          Expanded(
            child: Obx(() {
              if (controller.carregando.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.produtosFiltrados.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum produto com stock baixo encontrado.',
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
                            'STATUS',
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
                            'CODIGO',
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
                            'STOCK ATUAL',
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
                            'STOCK MIN',
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
                            '% DO MIN',
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
                            'ULTIMA ENTRADA',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    rows: controller.produtosFiltrados.asMap().entries.map((entry) {
                      final index = entry.key;
                      final produto = entry.value;

                      Color corLinha = index % 2 == 0 ? Colors.white : Colors.grey[50]!;

                      if (controller.linhaSelecionada.value == index) {
                        corLinha = Colors.blue[200]!;
                      }

                      return DataRow(
                        color: WidgetStateProperty.all(corLinha),
                        onSelectChanged: (_) => controller.linhaSelecionada.value = index,
                        cells: [
                          // Status (icone colorido baseado no nível)
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: _buildStatusIndicator(produto.nivelAlerta),
                            ),
                          ),
                          // Código
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.codigo,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Produto
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.nome,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Família
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.familiaNome,
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Setor
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.setorNome ?? '-',
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          // Stock Atual
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.estoque.toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          // Stock Mínimo
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.estoqueMinimo.toString(),
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          // % do Mínimo
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                '${produto.percentualMinimo.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getCorPorcentagem(produto.nivelAlerta),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          // Última Entrada
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                produto.ultimaEntrada != null
                                    ? DateFormat('dd/MM/yyyy').format(produto.ultimaEntrada!)
                                    : 'Nunca',
                                style: const TextStyle(fontSize: 11),
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
                const Text(
                  'LEGENDAS: Critico < 30% | Baixo 30-60% | Alerta 60-100%',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
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

  Widget _buildTotalChip(String label, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            valor.toString(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(NivelAlerta nivel) {
    Color cor;
    String label;

    switch (nivel) {
      case NivelAlerta.critico:
        cor = Colors.red[700]!;
        label = 'CRITICO';
        break;
      case NivelAlerta.baixo:
        cor = Colors.orange[700]!;
        label = 'BAIXO';
        break;
      case NivelAlerta.alerta:
        cor = Colors.yellow[800]!;
        label = 'ALERTA';
        break;
      default:
        cor = Colors.grey;
        label = '-';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getCorPorcentagem(NivelAlerta nivel) {
    switch (nivel) {
      case NivelAlerta.critico:
        return Colors.red[700]!;
      case NivelAlerta.baixo:
        return Colors.orange[700]!;
      case NivelAlerta.alerta:
        return Colors.yellow[800]!;
      default:
        return Colors.grey;
    }
  }
}
