import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/produto_model.dart';
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
                  child: Text(produto.codigo),
                ),
                title: Text(produto.nome),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Família: ${produto.familiaNome ?? "N/A"}'),
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

  void _mostrarDialogProduto(ProdutoModel? produto) {
    final codigoController = TextEditingController(text: produto?.codigo ?? '');
    final nomeController = TextEditingController(text: produto?.nome ?? '');
    final precoController = TextEditingController(
      text: produto?.preco.toString() ?? '',
    );
    final estoqueController = TextEditingController(
      text: produto?.estoque.toString() ?? '0',
    );

    int? familiaIdSelecionada = produto?.familiaId;

    Get.dialog(
      AlertDialog(
        title: Text(produto == null ? 'Novo Produto' : 'Editar Produto'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codigoController,
                decoration: InputDecoration(labelText: 'Código'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
              ),
              SizedBox(height: 10),
              Obx(() => DropdownButtonFormField<int>(
                    value: familiaIdSelecionada,
                    decoration: InputDecoration(labelText: 'Família'),
                    items: controller.familias.map((familia) {
                      return DropdownMenuItem<int>(
                        value: familia.id,
                        child: Text(familia.nome),
                      );
                    }).toList(),
                    onChanged: (value) {
                      familiaIdSelecionada = value;
                    },
                  )),
              SizedBox(height: 10),
              TextField(
                controller: precoController,
                decoration: InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                controller: estoqueController,
                decoration: InputDecoration(labelText: 'Estoque'),
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
              if (codigoController.text.isEmpty ||
                  nomeController.text.isEmpty ||
                  familiaIdSelecionada == null) {
                Get.snackbar('Erro', 'Preencha todos os campos obrigatórios');
                return;
              }

              final novoProduto = ProdutoModel(
                codigo: codigoController.text,
                nome: nomeController.text,
                familiaId: familiaIdSelecionada!,
                preco: double.tryParse(precoController.text) ?? 0,
                estoque: int.tryParse(estoqueController.text) ?? 0,
              );

              if (produto == null) {
                controller.adicionarProduto(novoProduto);
              } else {
                controller.editarProduto(produto.id!, novoProduto);
              }
            },
            child: Text('SALVAR'),
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
