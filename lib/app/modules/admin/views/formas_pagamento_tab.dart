import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class FormasPagamentoTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.formasPagamento.isEmpty) {
          return Center(child: Text('Nenhuma forma de pagamento cadastrada'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.formasPagamento.length,
          itemBuilder: (context, index) {
            final forma = controller.formasPagamento[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(_getIcon(forma.nome), color: Colors.white),
                ),
                title: Text(
                  forma.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(forma.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(forma),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(forma.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }

  IconData _getIcon(String nome) {
    switch (nome.toUpperCase()) {
      case 'CASH': return Icons.money;
      case 'EMOLA': return Icons.phone_android;
      case 'MPESA': return Icons.phone_iphone;
      case 'POS': return Icons.credit_card;
      default: return Icons.payment;
    }
  }

  void _mostrarDialog(forma) {
    final nomeController = TextEditingController(text: forma?.nome ?? '');
    final descController = TextEditingController(text: forma?.descricao ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(forma == null ? 'Nova Forma de Pagamento' : 'Editar Forma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }

              if (forma == null) {
                controller.adicionarFormaPagamento(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarFormaPagamento(
                  forma.id!,
                  nomeController.text,
                  descController.text,
                );
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
        content: Text('Deseja realmente remover esta forma de pagamento?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarFormaPagamento(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
