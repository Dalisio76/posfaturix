import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/fatura_entrada_repository.dart';
import '../../../data/repositories/fornecedor_repository.dart';
import '../../../data/repositories/produto_repository.dart';
import '../../../data/models/fatura_entrada_model.dart';
import '../../../data/models/fornecedor_model.dart';
import '../../../data/models/produto_model.dart';
import 'relatorio_faturas_tab.dart';

class FaturasEntradaTab extends StatefulWidget {
  const FaturasEntradaTab({Key? key}) : super(key: key);

  @override
  _FaturasEntradaTabState createState() => _FaturasEntradaTabState();
}

class _FaturasEntradaTabState extends State<FaturasEntradaTab> {
  final FaturaEntradaRepository _faturaRepo = Get.put(
    FaturaEntradaRepository(),
  );
  final FornecedorRepository _fornecedorRepo = Get.put(FornecedorRepository());
  final ProdutoRepository _produtoRepo = Get.put(ProdutoRepository());

  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;
  final Rxn<FornecedorModel> fornecedorSelecionado = Rxn<FornecedorModel>();

  final TextEditingController numeroFaturaController = TextEditingController();
  final TextEditingController observacoesController = TextEditingController();
  final Rxn<DateTime> dataFatura = Rxn<DateTime>(DateTime.now());

  // Produtos na fatura
  final RxList<Map<String, dynamic>> itensFatura = <Map<String, dynamic>>[].obs;
  final RxDouble totalFatura = 0.0.obs;

  @override
  void initState() {
    super.initState();
    carregarFornecedores();
  }

  Future<void> carregarFornecedores() async {
    try {
      fornecedores.value = await _fornecedorRepo.listarTodos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar fornecedores: $e');
    }
  }

  void adicionarProduto() async {
    final produtos = await _produtoRepo.listarTodos();

    if (produtos.isEmpty) {
      Get.snackbar('Aviso', 'Nenhum produto cadastrado');
      return;
    }

    final TextEditingController pesquisaController = TextEditingController();
    final RxList<ProdutoModel> produtosFiltrados = <ProdutoModel>[].obs;
    produtosFiltrados.value = produtos;

    Get.dialog(
      AlertDialog(
        title: const Text('Adicionar Produto', style: TextStyle(fontSize: 13)),
        content: SizedBox(
          width: 600,
          height: 500,
          child: Column(
            children: [
              TextField(
                controller: pesquisaController,
                decoration: const InputDecoration(
                  labelText: 'Pesquisar produto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 11),
                onChanged: (value) {
                  if (value.isEmpty) {
                    produtosFiltrados.value = produtos;
                  } else {
                    produtosFiltrados.value = produtos
                        .where(
                          (p) =>
                              p.nome.toLowerCase().contains(
                                value.toLowerCase(),
                              ) ||
                              p.codigo.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                        )
                        .toList();
                  }
                },
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(
                  () => ListView.builder(
                    itemCount: produtosFiltrados.length,
                    itemBuilder: (context, index) {
                      final produto = produtosFiltrados[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        title: Text(
                          produto.nome,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Código: ${produto.codigo}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        trailing: Text(
                          'Estoque: ${produto.estoque}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        onTap: () {
                          Get.back();
                          _mostrarDialogQuantidade(produto);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogQuantidade(ProdutoModel produto) {
    final quantidadeController = TextEditingController(text: '1');
    final precoController = TextEditingController(
      text: produto.precoCompra > 0
          ? produto.precoCompra.toStringAsFixed(2)
          : '0.00',
    );

    Get.dialog(
      AlertDialog(
        title: Text(
          'Adicionar: ${produto.nome}',
          style: const TextStyle(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantidadeController,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: precoController,
              decoration: const InputDecoration(
                labelText: 'Preço de Compra Unitário',
                border: OutlineInputBorder(),
                prefixText: 'MT ',
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR', style: TextStyle(fontSize: 12)),
          ),
          ElevatedButton(
            onPressed: () {
              final quantidade = int.tryParse(quantidadeController.text) ?? 1;
              final preco = double.tryParse(precoController.text) ?? 0.0;

              if (quantidade <= 0 || preco <= 0) {
                Get.snackbar(
                  'Erro',
                  'Quantidade e preço devem ser maiores que zero',
                );
                return;
              }

              final subtotal = quantidade * preco;

              // Verificar se produto já está na lista
              final index = itensFatura.indexWhere(
                (item) => item['produto_id'] == produto.id,
              );

              if (index >= 0) {
                // Atualizar item existente
                itensFatura[index] = {
                  'produto_id': produto.id,
                  'produto_codigo': produto.codigo,
                  'produto_nome': produto.nome,
                  'quantidade': quantidade,
                  'preco_unitario': preco,
                  'subtotal': subtotal,
                };
              } else {
                // Adicionar novo item
                itensFatura.add({
                  'produto_id': produto.id,
                  'produto_codigo': produto.codigo,
                  'produto_nome': produto.nome,
                  'quantidade': quantidade,
                  'preco_unitario': preco,
                  'subtotal': subtotal,
                });
              }

              calcularTotal();
              Get.back();
            },
            child: const Text('ADICIONAR', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void calcularTotal() {
    totalFatura.value = itensFatura.fold(
      0.0,
      (sum, item) => sum + (item['subtotal'] as double),
    );
  }

  void removerItem(int index) {
    itensFatura.removeAt(index);
    calcularTotal();
  }

  Future<void> salvarFatura() async {
    if (fornecedorSelecionado.value == null) {
      Get.snackbar('Erro', 'Selecione um fornecedor');
      return;
    }

    if (numeroFaturaController.text.isEmpty) {
      Get.snackbar('Erro', 'Informe o número da fatura');
      return;
    }

    if (itensFatura.isEmpty) {
      Get.snackbar('Erro', 'Adicione pelo menos um produto');
      return;
    }

    try {
      final fatura = FaturaEntradaModel(
        fornecedorId: fornecedorSelecionado.value!.id!,
        numeroFatura: numeroFaturaController.text,
        dataFatura: dataFatura.value!,
        total: totalFatura.value,
        observacoes: observacoesController.text.isEmpty
            ? null
            : observacoesController.text,
        usuario: 'Admin',
      );

      final itens = itensFatura.map((item) {
        return ItemFaturaEntradaModel(
          faturaId: 0, // Será preenchido pelo banco
          produtoId: item['produto_id'],
          quantidade: item['quantidade'],
          precoUnitario: item['preco_unitario'],
          subtotal: item['subtotal'],
        );
      }).toList();

      await _faturaRepo.inserirFatura(fatura: fatura, itens: itens);

      Get.snackbar(
        'Sucesso',
        'Fatura registrada com sucesso! Estoque atualizado.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Limpar formulário
      limparFormulario();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao salvar fatura: $e');
    }
  }

  void limparFormulario() {
    fornecedorSelecionado.value = null;
    numeroFaturaController.clear();
    observacoesController.clear();
    dataFatura.value = DateTime.now();
    itensFatura.clear();
    totalFatura.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Obx(
                    () => DropdownButtonFormField<FornecedorModel>(
                      value: fornecedorSelecionado.value,
                      decoration: const InputDecoration(
                        labelText: 'Fornecedor *',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 11),
                      items: fornecedores.map((fornecedor) {
                        return DropdownMenuItem(
                          value: fornecedor,
                          child: Text(
                            fornecedor.nome,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => fornecedorSelecionado.value = value,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: numeroFaturaController,
                    decoration: const InputDecoration(
                      labelText: 'Nº Fatura *',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(
                    () => InkWell(
                      onTap: () => _selecionarData(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data da Fatura',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          isDense: true,
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(dataFatura.value!),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Botão adicionar produto
            ElevatedButton.icon(
              onPressed: adicionarProduto,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('ADICIONAR PRODUTO', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tabela de produtos
            Expanded(
              child: Obx(() {
                if (itensFatura.isEmpty) {
                  return const Center(child: Text('Nenhum produto adicionado'));
                }

                return SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey[300]!),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1.5),
                      4: FlexColumnWidth(1.5),
                      5: FixedColumnWidth(40),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey[200]),
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'CÓDIGO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'PRODUTO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'QUANT',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'PREÇO UNI.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              'SUBTOTAL',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Text(
                              '',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      ...itensFatura.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                item['produto_codigo'],
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                item['produto_nome'],
                                style: const TextStyle(fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                item['quantidade'].toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'MT ${item['preco_unitario'].toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Text(
                                'MT ${item['subtotal'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => removerItem(index),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // Observações
            TextField(
              controller: observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
            ),
            const SizedBox(height: 8),

            // Rodapé: Total e Botões
            Row(
              children: [
                Obx(
                  () => Text(
                    'TOTAL: MT ${totalFatura.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.to(() => const RelatorioFaturasTab());
                  },
                  icon: const Icon(Icons.list, size: 16),
                  label: const Text('VER RELATÓRIO', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: limparFormulario,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('LIMPAR', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: salvarFatura,
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('SALVAR FATURA', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataFatura.value!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      dataFatura.value = picked;
    }
  }

  @override
  void dispose() {
    numeroFaturaController.dispose();
    observacoesController.dispose();
    super.dispose();
  }
}
