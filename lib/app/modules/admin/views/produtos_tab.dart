import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/produto_model.dart';
import '../../../data/models/produto_composicao_model.dart';
import '../controllers/admin_controller.dart';

class ProdutosTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.produtos.isEmpty) {
          return Center(
            child: Text('Nenhum produto cadastrado'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.produtos.length,
          itemBuilder: (context, index) {
            final produto = controller.produtos[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(
                    produto.codigo,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                title: Text(produto.nome),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Família: ${produto.familiaNome ?? "N/A"}'),
                    if (produto.setorNome != null)
                      Row(
                        children: [
                          Icon(Icons.store, size: 12, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Setor: ${produto.setorNome}',
                            style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    if (produto.areaNome != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.orange),
                          SizedBox(width: 4),
                          Text(
                            'Área: ${produto.areaNome}',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                          ),
                        ],
                      ),
                    Text('Estoque: ${produto.estoque}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.formatarMoeda(produto.preco),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _mostrarDialogProduto(produto),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _confirmarDelete(produto.id!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogProduto(null),
        child: Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogProduto(ProdutoModel? produto) async {
    // Não precisa mais do campo código - será gerado automaticamente
    final nomeController = TextEditingController(text: produto?.nome ?? '');
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<int>(
                            value: familiaIdSelecionada.value,
                            decoration: InputDecoration(
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
                    SizedBox(width: 15),
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<int>(
                            value: setorIdSelecionado.value,
                            decoration: InputDecoration(
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
                SizedBox(height: 15),

                Obx(() => DropdownButtonFormField<int>(
                      value: areaIdSelecionada.value,
                      decoration: InputDecoration(
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
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: precoCompraController,
                        decoration: InputDecoration(
                          labelText: 'Preço de Compra *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: precoController,
                        decoration: InputDecoration(
                          labelText: 'Preço de Venda *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                Row(
                  children: [
                    Expanded(
                      child: Obx(() => DropdownButtonFormField<String>(
                            value: iva.value,
                            decoration: InputDecoration(
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
                    SizedBox(width: 15),
                    Expanded(
                      child: Obx(() => TextField(
                            controller: estoqueController,
                            decoration: InputDecoration(
                              labelText: 'Estoque',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            enabled: contavel.value,
                          )),
                    ),
                  ],
                ),
                SizedBox(height: 15),

                // Switch Contável
                Obx(() => SwitchListTile(
                      title: Text('Produto Contável'),
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
                SizedBox(height: 15),

                // Seção de Composição (só aparece se não-contável)
                Obx(() {
                  if (contavel.value) return SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(thickness: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Composição do Produto (Menu)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _adicionarComponente(composicoes),
                            icon: Icon(Icons.add, size: 18),
                            label: Text('Adicionar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Obx(() {
                        if (composicoes.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Nenhum componente adicionado.\nClique em "Adicionar" para incluir produtos.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
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
                                  icon: Icon(Icons.delete, color: Colors.red),
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
            child: Text('CANCELAR'),
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
            child: Text('SALVAR'),
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
        title: Text('Adicionar Componente'),
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
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: pesquisaController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            pesquisaController.clear();
                            filtrarProdutos('');
                          },
                        )
                      : null,
                ),
                onChanged: filtrarProdutos,
              ),
              SizedBox(height: 15),

              // Lista de produtos filtrados (máximo 5 visíveis)
              Obx(() {
                if (produtosFiltrados.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
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
                                style: TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                            title: Text(produto.nome),
                            subtitle: Text('Estoque: ${produto.estoque}'),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Colors.blue)
                                : null,
                            onTap: () {
                              produtoSelecionado.value = produto;
                            },
                          );
                        },
                      )),

                );
              }),
              SizedBox(height: 15),

              TextField(
                controller: quantidadeController,
                decoration: InputDecoration(
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
            child: Text('CANCELAR'),
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
            child: Text('ADICIONAR'),
          ),
        ],
      ),
    );
  }

  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja realmente remover este produto?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarProduto(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
