import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/services/stock_printer_service.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/produto_composicao_model.dart';
import '../controllers/admin_controller.dart';

class ProdutosTab extends GetView<AdminController> {
  final RxList<int> produtosSelecionados = <int>[].obs;
  final RxBool selecionarTodos = false.obs;

  // Controle de ordenação
  final RxString campoOrdenacao = 'nome'.obs;
  final RxBool ordemCrescente = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.produtos.isEmpty) {
                return const Center(
                  child: Text('Nenhum produto cadastrado. Clique em ADICIONAR PRODUTO para criar.'),
                );
              }

              return _buildTabela();
            }),
          ),
          _buildRodape(),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'PESQUISAR PRODUTO',
                hintText: 'Digite o código ou nome...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search, size: 16),
                contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
              onChanged: (value) {
                // TODO: Implementar filtro de pesquisa
              },
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Chip(
                avatar: const Icon(Icons.inventory, size: 14, color: Colors.white),
                label: Text('${controller.produtos.length}'),
                backgroundColor: Colors.blue[700],
                labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
              )),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    return Column(
      children: [
        // Cabeçalho
        Container(
          color: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Obx(
                  () => Transform.scale(
                    scale: 0.85,
                    child: Checkbox(
                      value: selecionarTodos.value,
                      onChanged: (_) => toggleSelecionarTodos(),
                      tristate: false,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
              _buildCabecalho('ID', 'id', flex: 1),
              _buildCabecalho('NOME', 'nome', flex: 4),
              _buildCabecalho('FAMÍLIA', 'familia', flex: 2),
              _buildCabecalho('SETOR', 'setor', flex: 2),
              _buildCabecalho('ÁREA', 'area', flex: 2),
              _buildCabecalho('COMPRA', 'compra', flex: 2),
              _buildCabecalho('VENDA', 'venda', flex: 2),
              _buildCabecalho('ESTOQUE', 'estoque', flex: 1),
              _buildCabecalhoFixo('AÇÕES', flex: 1),
            ],
          ),
        ),
        // Linhas
        Expanded(
          child: Obx(
            () {
              final produtosOrdenados = _obterProdutosOrdenados();
              return ListView.builder(
                itemCount: produtosOrdenados.length,
                itemBuilder: (context, index) {
                  final produto = produtosOrdenados[index];
                  return _buildLinha(produto, index);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(String texto, String campo, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Obx(() => InkWell(
        onTap: () => ordenarPor(campo),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  texto,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: campoOrdenacao.value == campo ? Colors.blue[700] : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (campoOrdenacao.value == campo) ...[
                const SizedBox(width: 2),
                Icon(
                  ordemCrescente.value ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: Colors.blue[700],
                ),
              ],
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildCabecalhoFixo(String texto, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLinha(ProdutoModel produto, int index) {
    final produtoId = produto.id!;
    final corFundo = index % 2 == 0 ? Colors.white : Colors.grey[50];

    return Obx(
      () => Container(
        color: produtosSelecionados.contains(produtoId)
            ? Colors.blue[50]
            : corFundo,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: produtosSelecionados.contains(produtoId),
                  onChanged: (_) => toggleProduto(produtoId),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            _buildCelula(produto.id.toString(), flex: 1),
            _buildCelula(produto.nome, flex: 4, align: TextAlign.left),
            _buildCelula(produto.familiaNome ?? '-', flex: 2),
            _buildCelula(produto.setorNome ?? '-', flex: 2),
            _buildCelula(produto.areaNome ?? '-', flex: 2),
            _buildCelula(Formatters.formatarMoeda(produto.precoCompra), flex: 2),
            _buildCelula(Formatters.formatarMoeda(produto.preco), flex: 2),
            _buildCelula(produto.estoque.toString(), flex: 1),
            Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                    onPressed: () => _mostrarDialogProduto(produto),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Editar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    onPressed: () => _confirmarDelete(produto.id!),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCelula(
    String texto, {
    int flex = 1,
    TextAlign align = TextAlign.center,
    Color? cor,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          texto,
          style: TextStyle(fontSize: 11, color: cor, fontWeight: cor != null ? FontWeight.bold : null),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 1)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogProduto(null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ADICIONAR', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogImpressaoStock(),
            icon: const Icon(Icons.print, size: 18),
            label: const Text('IMPRIMIR STOCK', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            if (produtosSelecionados.isEmpty) return const SizedBox.shrink();
            return ElevatedButton.icon(
              onPressed: () => _deletarSelecionados(),
              icon: const Icon(Icons.delete, size: 18),
              label: Text('DELETAR (${produtosSelecionados.length})', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            );
          }),
          const Spacer(),
          Obx(() {
            // Calcular totais
            final totalVenda = controller.produtos.fold(0.0, (sum, p) => sum + (p.preco * p.estoque));
            final totalCompra = controller.produtos.fold(0.0, (sum, p) => sum + (p.precoCompra * p.estoque));
            final lucro = totalVenda - totalCompra;

            return Row(
              children: [
                Text(
                  'Total Venda: ${Formatters.formatarMoeda(totalVenda)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  '|',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  'Total Compra: ${Formatters.formatarMoeda(totalCompra)}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 12),
                Text(
                  '|',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  'Lucro: ${Formatters.formatarMoeda(lucro)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: lucro >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void toggleSelecionarTodos() {
    selecionarTodos.value = !selecionarTodos.value;
    if (selecionarTodos.value) {
      produtosSelecionados.value = controller.produtos.map((p) => p.id!).toList();
    } else {
      produtosSelecionados.clear();
    }
  }

  void toggleProduto(int produtoId) {
    if (produtosSelecionados.contains(produtoId)) {
      produtosSelecionados.remove(produtoId);
    } else {
      produtosSelecionados.add(produtoId);
    }
    selecionarTodos.value = produtosSelecionados.length == controller.produtos.length;
  }

  void ordenarPor(String campo) {
    if (campoOrdenacao.value == campo) {
      // Inverte a ordem se clicar no mesmo campo
      ordemCrescente.value = !ordemCrescente.value;
    } else {
      // Novo campo, começa crescente
      campoOrdenacao.value = campo;
      ordemCrescente.value = true;
    }
  }

  List<ProdutoModel> _obterProdutosOrdenados() {
    final lista = List<ProdutoModel>.from(controller.produtos);

    lista.sort((a, b) {
      int comparacao = 0;

      switch (campoOrdenacao.value) {
        case 'id':
          comparacao = (a.id ?? 0).compareTo(b.id ?? 0);
          break;
        case 'nome':
          comparacao = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
          break;
        case 'familia':
          final famA = a.familiaNome ?? '';
          final famB = b.familiaNome ?? '';
          comparacao = famA.toLowerCase().compareTo(famB.toLowerCase());
          // Se famílias iguais, ordena por nome do produto
          if (comparacao == 0) {
            comparacao = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
          }
          break;
        case 'setor':
          final setA = a.setorNome ?? '';
          final setB = b.setorNome ?? '';
          comparacao = setA.toLowerCase().compareTo(setB.toLowerCase());
          // Se setores iguais, ordena por família e depois nome
          if (comparacao == 0) {
            final famA = a.familiaNome ?? '';
            final famB = b.familiaNome ?? '';
            comparacao = famA.toLowerCase().compareTo(famB.toLowerCase());
            if (comparacao == 0) {
              comparacao = a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
            }
          }
          break;
        case 'area':
          final areaA = a.areaNome ?? '';
          final areaB = b.areaNome ?? '';
          comparacao = areaA.toLowerCase().compareTo(areaB.toLowerCase());
          break;
        case 'compra':
          comparacao = a.precoCompra.compareTo(b.precoCompra);
          break;
        case 'venda':
          comparacao = a.preco.compareTo(b.preco);
          break;
        case 'estoque':
          comparacao = a.estoque.compareTo(b.estoque);
          break;
      }

      return ordemCrescente.value ? comparacao : -comparacao;
    });

    return lista;
  }

  void _deletarSelecionados() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar'),
        content: Text('Deseja realmente remover ${produtosSelecionados.length} produtos selecionados?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              for (var id in produtosSelecionados.toList()) {
                await controller.deletarProduto(id);
              }
              produtosSelecionados.clear();
              selecionarTodos.value = false;
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogProduto(ProdutoModel? produto) async {
    // Não precisa mais do campo código - será gerado automaticamente
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final codigoBarrasController = TextEditingController(text: produto?.codigoBarras ?? '');
    final precoController = TextEditingController(
      text: produto?.preco.toString() ?? '',
    );
    final precoCompraController = TextEditingController(
      text: produto?.precoCompra.toString() ?? '0',
    );
    final estoqueController = TextEditingController(
      text: produto?.estoque.toString() ?? '0',
    );

    // Usar últimas seleções como padrão se estiver criando um novo produto
    final familiaIdSelecionada = Rxn<int>(
      produto?.familiaId ?? controller.ultimaFamiliaSelecionada.value
    );
    final setorIdSelecionado = Rxn<int>(
      produto?.setorId ?? controller.ultimoSetorSelecionado.value
    );
    final areaIdSelecionada = Rxn<int>(
      produto?.areaId ?? controller.ultimaAreaSelecionada.value
    );

    // Novos campos
    final contavel = (produto?.contavel ?? true).obs;
    final iva = (produto?.iva ?? 'Incluso').obs;

    // Lista de composição
    final composicoes = <ProdutoComposicaoModel>[].obs;

    // Carregar composição se estiver editando
    if (produto?.id != null) {
      composicoes.value = await controller.buscarComposicaoProduto(produto!.id!);
    }

    Get.dialog(
      AlertDialog(
        title: Text(produto == null ? 'Novo Produto' : 'Editar Produto'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Código automático - só mostrar se estiver editando
                if (produto != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Text(
                      'Código: ${produto.codigo}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: codigoBarrasController,
                  decoration: const InputDecoration(
                    labelText: 'Código de Barras',
                    hintText: 'EAN-13, EAN-8, UPC-A ou UPC-E',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<int>(
                            value: familiaIdSelecionada.value,
                            decoration: const InputDecoration(
                              labelText: 'Família *',
                              border: OutlineInputBorder(),
                            ),
                            items: controller.familias.map((familia) {
                              return DropdownMenuItem<int>(
                                value: familia.id,
                                child: Text(familia.nome),
                              );
                            }).toList(),
                            onChanged: (value) {
                              familiaIdSelecionada.value = value;
                            },
                          )),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<int>(
                            value: setorIdSelecionado.value,
                            decoration: const InputDecoration(
                              labelText: 'Setor',
                              border: OutlineInputBorder(),
                            ),
                            items: controller.setores.map((setor) {
                              return DropdownMenuItem<int>(
                                value: setor.id,
                                child: Text(setor.nome),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setorIdSelecionado.value = value;
                            },
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Obx(() => DropdownButtonFormField<int>(
                      value: areaIdSelecionada.value,
                      decoration: const InputDecoration(
                        labelText: 'Área',
                        border: OutlineInputBorder(),
                      ),
                      items: controller.areas.map((area) {
                        return DropdownMenuItem<int>(
                          value: area.id,
                          child: Text(area.nome),
                        );
                      }).toList(),
                      onChanged: (value) {
                        areaIdSelecionada.value = value;
                      },
                    )),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: precoCompraController,
                        decoration: const InputDecoration(
                          labelText: 'Preço de Compra *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: precoController,
                        decoration: const InputDecoration(
                          labelText: 'Preço de Venda *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<String>(
                            value: iva.value,
                            decoration: const InputDecoration(
                              labelText: 'IVA *',
                              border: OutlineInputBorder(),
                            ),
                            items: ['Incluso', 'Isento'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) iva.value = value;
                            },
                          )),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Obx(() => TextField(
                            controller: estoqueController,
                            decoration: const InputDecoration(
                              labelText: 'Estoque',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: contavel.value,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // Switch Contável
                Obx(() => SwitchListTile(
                      title: const Text('Produto Contável'),
                      subtitle: Text(contavel.value
                          ? 'Este produto tem estoque próprio'
                          : 'Este produto é composto por outros (Menu)'),
                      value: contavel.value,
                      onChanged: (value) {
                        contavel.value = value;
                        if (!value) estoqueController.text = '0';
                      },
                      activeColor: Colors.green,
                    )),
                const SizedBox(height: 15),

                // Seção de Composição (só aparece se não-contável)
                Obx(() {
                  if (contavel.value) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(thickness: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Composição do Produto (Menu)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _adicionarComponente(composicoes),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Adicionar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        if (composicoes.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Nenhum componente adicionado.\nClique em "Adicionar" para incluir produtos.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: composicoes.length,
                          itemBuilder: (context, index) {
                            final comp = composicoes[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('${comp.quantidade.toInt()}'),
                                ),
                                title: Text(comp.componenteNome ?? 'Produto'),
                                subtitle: Text(
                                  'Estoque: ${comp.componenteEstoque ?? 0}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => composicoes.removeAt(index),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty ||
                  familiaIdSelecionada.value == null) {
                Get.snackbar('Erro', 'Preencha todos os campos obrigatórios');
                return;
              }

              final novoProduto = ProdutoModel(
                codigo: produto?.codigo ?? '', // Será gerado automaticamente se vazio
                nome: nomeController.text,
                codigoBarras: codigoBarrasController.text.isEmpty ? null : codigoBarrasController.text,
                familiaId: familiaIdSelecionada.value!,
                preco: double.tryParse(precoController.text) ?? 0,
                precoCompra: double.tryParse(precoCompraController.text) ?? 0,
                estoque: int.tryParse(estoqueController.text) ?? 0,
                contavel: contavel.value,
                iva: iva.value,
                setorId: setorIdSelecionado.value,
                areaId: areaIdSelecionada.value,
              );

              if (produto == null) {
                controller.adicionarProduto(novoProduto, composicoes.toList());
              } else {
                controller.editarProduto(produto.id!, novoProduto, composicoes.toList());
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _adicionarComponente(RxList<ProdutoComposicaoModel> composicoes) {
    final produtoSelecionado = Rxn<ProdutoModel>();
    final quantidadeController = TextEditingController(text: '1');
    final pesquisaController = TextEditingController();
    final produtosFiltrados = <ProdutoModel>[].obs;

    // Inicializar lista de produtos contáveis
    produtosFiltrados.value = controller.produtos
        .where((p) => p.contavel)
        .toList();

    // Função para filtrar produtos
    void filtrarProdutos(String pesquisa) {
      if (pesquisa.isEmpty) {
        produtosFiltrados.value = controller.produtos
            .where((p) => p.contavel)
            .toList();
      } else {
        produtosFiltrados.value = controller.produtos
            .where((p) =>
                p.contavel &&
                (p.nome.toLowerCase().contains(pesquisa.toLowerCase()) ||
                    p.codigo.toLowerCase().contains(pesquisa.toLowerCase())))
            .toList();
      }
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Adicionar Componente'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de pesquisa
              TextField(
                controller: pesquisaController,
                decoration: InputDecoration(
                  labelText: 'Pesquisar produto',
                  hintText: 'Digite o código ou nome...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: pesquisaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            pesquisaController.clear();
                            filtrarProdutos('');
                          },
                        )
                      : null,
                ),
                onChanged: filtrarProdutos,
              ),
              const SizedBox(height: 15),

              // Lista de produtos filtrados (máximo 5 visíveis)
              Obx(() {
                if (produtosFiltrados.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Nenhum produto encontrado',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Obx(() => ListView.builder(
                        shrinkWrap: true,
                        itemCount: produtosFiltrados.length,
                        itemBuilder: (context, index) {
                          final produto = produtosFiltrados[index];
                          final isSelected = produtoSelecionado.value?.id == produto.id;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.blue : Colors.grey,
                              child: Text(
                                produto.codigo,
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                            title: Text(produto.nome),
                            subtitle: Text('Estoque: ${produto.estoque}'),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.blue)
                                : null,
                            onTap: () {
                              produtoSelecionado.value = produto;
                            },
                          );
                        },
                      )),

                );
              }),
              const SizedBox(height: 15),

              TextField(
                controller: quantidadeController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (produtoSelecionado.value == null) {
                Get.snackbar('Erro', 'Selecione um produto');
                return;
              }

              final quantidade = double.tryParse(quantidadeController.text) ?? 0;
              if (quantidade <= 0) {
                Get.snackbar('Erro', 'Quantidade deve ser maior que zero');
                return;
              }

              // Verificar se já existe na lista
              final jaExiste = composicoes.any(
                (c) => c.produtoComponenteId == produtoSelecionado.value!.id,
              );

              if (jaExiste) {
                Get.snackbar('Atenção', 'Este produto já está na composição');
                return;
              }

              // Adicionar à lista
              composicoes.add(ProdutoComposicaoModel(
                produtoId: 0, // Será definido ao salvar
                produtoComponenteId: produtoSelecionado.value!.id!,
                quantidade: quantidade,
                componenteCodigo: produtoSelecionado.value!.codigo,
                componenteNome: produtoSelecionado.value!.nome,
                componenteEstoque: produtoSelecionado.value!.estoque,
              ));

              Get.back();
              Get.snackbar('Sucesso', 'Componente adicionado!');
            },
            child: const Text('ADICIONAR'),
          ),
        ],
      ),
    );
  }

  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar'),
        content: const Text('Deseja realmente remover este produto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await controller.deletarProduto(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('REMOVER'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogImpressaoStock() {
    Get.dialog(
      AlertDialog(
        title: const Text('Imprimir Lista de Stock', style: TextStyle(fontSize: 14)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha o formato:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            // Botão A4
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  _imprimirStockA4();
                },
                icon: const Icon(Icons.description, size: 32),
                label: const Text(
                  'A4',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Botão TÉRMICA
            SizedBox(
              width: double.infinity,
              height: 80,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  _imprimirStockTermica();
                },
                icon: const Icon(Icons.receipt, size: 32),
                label: const Text(
                  'TÉRMICA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
        ],
      ),
    );
  }

  void _imprimirStockA4() async {
    try {
      // Verificar se há produtos
      if (controller.produtos.isEmpty) {
        Get.snackbar(
          'Aviso',
          'Não há produtos para imprimir',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Verificar se há dados da empresa
      if (controller.empresa.value == null) {
        Get.snackbar(
          'Erro',
          'Dados da empresa não encontrados',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Mostrar loading
      Get.snackbar(
        'Aguarde',
        'Preparando impressão em formato A4...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue[700],
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Chamar o serviço de impressão
      await StockPrinterService.imprimirStockA4(
        controller.produtos.toList(),
        controller.empresa.value!,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao preparar impressão: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _imprimirStockTermica() {
    // TODO: Implementar impressão térmica
    Get.snackbar(
      'Sucesso',
      'Preparando impressão em formato térmico...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[700],
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}
