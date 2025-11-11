import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class FamiliasTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.familias.isEmpty) {
          return Center(
            child: Text('Nenhuma família cadastrada'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.familias.length,
          itemBuilder: (context, index) {
            final familia = controller.familias[index];
            return Card(
              child: ListTile(
                title: Text(familia.nome),
                subtitle: Text(familia.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialogFamilia(familia),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(familia.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogFamilia(null),
        child: Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogFamilia(familia) {
    final nomeController = TextEditingController(text: familia?.nome ?? '');
    final descController = TextEditingController(text: familia?.descricao ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(familia == null ? 'Nova Família' : 'Editar Família'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Descrição'),
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

              if (familia == null) {
                controller.adicionarFamilia(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarFamilia(
                  familia.id!,
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
        content: Text('Deseja realmente remover esta família?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarFamilia(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
