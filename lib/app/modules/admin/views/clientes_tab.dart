import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/cliente_model.dart';
import '../controllers/admin_controller.dart';

class ClientesTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }

        if (controller.clientes.isEmpty) {
          return Center(
            child: Text('Nenhum cliente cadastrado'),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: controller.clientes.length,
          itemBuilder: (context, index) {
            final cliente = controller.clientes[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: CircleAvatar(
                  radius: 16,
                  child: Text(
                    cliente.nome.substring(0, 1).toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  backgroundColor: Colors.blue,
                ),
                title: Text(
                  cliente.nome,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  [
                    if (cliente.contacto != null) cliente.contacto,
                    if (cliente.email != null) cliente.email,
                  ].join(' • '),
                  style: TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue, size: 16),
                      onPressed: () => _mostrarDialogCliente(cliente),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 16),
                      onPressed: () => _confirmarDelete(cliente.id!),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogCliente(null),
        child: Icon(Icons.add),
      ),
    );
  }

  void _mostrarDialogCliente(ClienteModel? cliente) {
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final contactoController =
        TextEditingController(text: cliente?.contacto ?? '');
    final contacto2Controller =
        TextEditingController(text: cliente?.contacto2 ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final enderecoController =
        TextEditingController(text: cliente?.endereco ?? '');
    final bairroController =
        TextEditingController(text: cliente?.bairro ?? '');
    final cidadeController =
        TextEditingController(text: cliente?.cidade ?? '');
    final nuitController = TextEditingController(text: cliente?.nuit ?? '');
    final observacoesController =
        TextEditingController(text: cliente?.observacoes ?? '');

    Get.dialog(
      AlertDialog(
        title:
            Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: contactoController,
                        decoration: InputDecoration(
                          labelText: 'Contacto',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: contacto2Controller,
                        decoration: InputDecoration(
                          labelText: 'Contacto 2',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 10),
                TextField(
                  controller: enderecoController,
                  decoration: InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bairroController,
                        decoration: InputDecoration(
                          labelText: 'Bairro',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cidadeController,
                        decoration: InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
                  controller: nuitController,
                  decoration: InputDecoration(
                    labelText: 'NUIT',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
                Get.snackbar('Erro', 'O nome é obrigatório');
                return;
              }

              final novoCliente = ClienteModel(
                nome: nomeController.text,
                contacto: contactoController.text.isEmpty
                    ? null
                    : contactoController.text,
                contacto2: contacto2Controller.text.isEmpty
                    ? null
                    : contacto2Controller.text,
                email: emailController.text.isEmpty
                    ? null
                    : emailController.text,
                endereco: enderecoController.text.isEmpty
                    ? null
                    : enderecoController.text,
                bairro: bairroController.text.isEmpty
                    ? null
                    : bairroController.text,
                cidade: cidadeController.text.isEmpty
                    ? null
                    : cidadeController.text,
                nuit: nuitController.text.isEmpty
                    ? null
                    : nuitController.text,
                observacoes: observacoesController.text.isEmpty
                    ? null
                    : observacoesController.text,
              );

              if (cliente == null) {
                controller.adicionarCliente(novoCliente);
              } else {
                controller.editarCliente(cliente.id!, novoCliente);
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
        content: Text('Deseja realmente remover este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarCliente(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
