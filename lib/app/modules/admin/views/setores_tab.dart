import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class SetoresTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.setores.isEmpty) {
          return Center(child: Text('Nenhum setor cadastrado'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.setores.length,
          itemBuilder: (context, index) {
            final setor = controller.setores[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(Icons.store, color: Colors.white),
                ),
                title: Text(
                  setor.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(setor.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(setor),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(setor.id!),
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

  void _mostrarDialog(setor) {
    final nomeController = TextEditingController(text: setor?.nome ?? '');
    final descController = TextEditingController(text: setor?.descricao ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(setor == null ? 'Novo Setor' : 'Editar Setor'),
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

              if (setor == null) {
                controller.adicionarSetor(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarSetor(
                  setor.id!,
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
        content: Text('Deseja realmente remover este setor?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarSetor(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
