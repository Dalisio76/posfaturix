import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';

class AreasTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.areas.isEmpty) {
          return Center(child: Text('Nenhuma área cadastrada'));
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.areas.length,
          itemBuilder: (context, index) {
            final area = controller.areas[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(Icons.location_on, color: Colors.white),
                ),
                title: Text(
                  area.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(area.descricao ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(area),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(area.id!),
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

  void _mostrarDialog(area) {
    final nomeController = TextEditingController(text: area?.nome ?? '');
    final descController = TextEditingController(text: area?.descricao ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(area == null ? 'Nova Área' : 'Editar Área'),
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

              if (area == null) {
                controller.adicionarArea(
                  nomeController.text,
                  descController.text,
                );
              } else {
                controller.editarArea(
                  area.id!,
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
        content: Text('Deseja realmente remover esta área?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarArea(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
