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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (familia.descricao != null && familia.descricao!.isNotEmpty)
                      Text(familia.descricao!),
                    if (familia.setoresTexto != null && familia.setoresTexto!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.store, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Setores: ${familia.setoresTexto}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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

    // Lista de setores selecionados (inicializar com setores da família se estiver editando)
    final setoresSelecionados = RxList<int>(familia?.setorIds ?? []);

    Get.dialog(
      AlertDialog(
        title: Text(familia == null ? 'Nova Família' : 'Editar Família'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              SizedBox(height: 20),
              Text(
                'Setores *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Selecione os setores onde esta família estará disponível:',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),
              Obx(() {
                if (controller.setores.isEmpty) {
                  return Text(
                    'Nenhum setor cadastrado. Cadastre setores primeiro.',
                    style: TextStyle(color: Colors.red),
                  );
                }

                return Column(
                  children: controller.setores.map((setor) {
                    return Obx(() => CheckboxListTile(
                      title: Text(setor.nome),
                      subtitle: setor.descricao != null
                          ? Text(setor.descricao!, style: TextStyle(fontSize: 12))
                          : null,
                      value: setoresSelecionados.contains(setor.id),
                      onChanged: (bool? value) {
                        if (value == true) {
                          setoresSelecionados.add(setor.id!);
                        } else {
                          setoresSelecionados.remove(setor.id);
                        }
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    ));
                  }).toList(),
                );
              }),
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
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }

              if (setoresSelecionados.isEmpty) {
                Get.snackbar('Erro', 'Selecione pelo menos um setor');
                return;
              }

              if (familia == null) {
                controller.adicionarFamilia(
                  nomeController.text,
                  descController.text,
                  setoresSelecionados.toList(),
                );
              } else {
                controller.editarFamilia(
                  familia.id!,
                  nomeController.text,
                  descController.text,
                  setoresSelecionados.toList(),
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
