import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/empresa_model.dart';

class EmpresaTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: CircularProgressIndicator());
      }

      final empresa = controller.empresa.value;

      if (empresa == null) {
        return Center(child: Text('Dados da empresa não encontrados'));
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.business, size: 40, color: Get.theme.primaryColor),
                    SizedBox(width: 16),
                    Text(
                      'DADOS DA EMPRESA',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _mostrarDialogEmpresa(empresa),
                      icon: Icon(Icons.edit),
                      label: Text('EDITAR'),
                    ),
                  ],
                ),
                Divider(height: 30),
                _buildInfoRow('Nome:', empresa.nome),
                _buildInfoRow('NUIT:', empresa.nuit ?? 'N/A'),
                _buildInfoRow('Endereço:', empresa.endereco ?? 'N/A'),
                _buildInfoRow('Cidade:', empresa.cidade ?? 'N/A'),
                _buildInfoRow('Email:', empresa.email ?? 'N/A'),
                _buildInfoRow('Contacto:', empresa.contacto ?? 'N/A'),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogEmpresa(empresa) {
    final nomeController = TextEditingController(text: empresa.nome);
    final nuitController = TextEditingController(text: empresa.nuit ?? '');
    final enderecoController = TextEditingController(text: empresa.endereco ?? '');
    final cidadeController = TextEditingController(text: empresa.cidade ?? '');
    final emailController = TextEditingController(text: empresa.email ?? '');
    final contactoController = TextEditingController(text: empresa.contacto ?? '');

    Get.dialog(
      AlertDialog(
        title: Text('Editar Dados da Empresa'),
        content: SingleChildScrollView(
          child: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome da Empresa *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: nuitController,
                  decoration: InputDecoration(
                    labelText: 'NUIT',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: enderecoController,
                  decoration: InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: cidadeController,
                  decoration: InputDecoration(
                    labelText: 'Cidade',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: contactoController,
                  decoration: InputDecoration(
                    labelText: 'Contacto',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
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
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }

              final empresaAtualizada = EmpresaModel(
                nome: nomeController.text,
                nuit: nuitController.text,
                endereco: enderecoController.text,
                cidade: cidadeController.text,
                email: emailController.text,
                contacto: contactoController.text,
              );

              controller.atualizarEmpresa(empresaAtualizada);
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}
