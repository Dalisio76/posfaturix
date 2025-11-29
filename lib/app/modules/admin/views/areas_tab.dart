import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/impressora_model.dart';
import '../../../data/repositories/impressora_repository.dart';
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
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (area.descricao != null) Text(area.descricao!),
                    if (area.impressoraNome != null) ...[
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.print, size: 14, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Impressora: ${area.impressoraNome}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
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

  void _mostrarDialog(area) async {
    final nomeController = TextEditingController(text: area?.nome ?? '');
    final descController = TextEditingController(text: area?.descricao ?? '');
    final RxnInt impressoraSelecionada = RxnInt(area?.impressoraId);

    // Mostrar loading
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    // Carregar impressoras
    final impressoraRepo = ImpressoraRepository();
    List<ImpressoraModel> impressoras = [];

    try {
      impressoras = await impressoraRepo.listarAtivas();
    } catch (e) {
      Get.back(); // Fechar loading
      Get.snackbar(
        'Erro',
        'Erro ao carregar impressoras: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Fechar loading
    Get.back();

    // Mostrar dialog
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 12),
            Text(area == null ? 'Nova Área' : 'Editar Área'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome *',
                    hintText: 'Ex: Cozinha, Bar, Esplanada',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  autofocus: true,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descrição da área',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 16),
                Text(
                  'Impressora para Pedidos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Obx(() => DropdownButtonFormField<int?>(
                  value: impressoraSelecionada.value,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: Icon(
                      impressoraSelecionada.value != null ? Icons.print : Icons.print_disabled,
                      color: impressoraSelecionada.value != null ? Colors.green : Colors.grey,
                    ),
                  ),
                  hint: Text('Nenhuma (sem impressão automática)'),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nenhuma'),
                    ),
                    ...impressoras.map((imp) {
                      return DropdownMenuItem<int?>(
                        value: imp.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print, size: 16, color: Colors.blue),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                imp.nome,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (valor) {
                    impressoraSelecionada.value = valor;
                  },
                )),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Quando adicionar produtos desta área em pedidos, será impresso automaticamente na impressora selecionada',
                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar(
                  'Atenção',
                  'Nome é obrigatório',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }

              if (area == null) {
                controller.adicionarArea(
                  nomeController.text,
                  descController.text,
                  impressoraSelecionada.value,
                );
              } else {
                controller.editarArea(
                  area.id!,
                  nomeController.text,
                  descController.text,
                  impressoraSelecionada.value,
                );
              }
            },
            icon: Icon(Icons.save),
            label: Text('SALVAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Confirmar Exclusão'),
          ],
        ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('SIM, REMOVER'),
          ),
        ],
      ),
    );
  }
}
