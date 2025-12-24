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

    // Mensagem de erro/sucesso
    final mensagemErro = RxnString();
    final mensagemSucesso = RxnString();
    final salvando = false.obs;

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
                // Mensagem de erro
                Obx(() {
                  if (mensagemErro.value != null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensagemErro.value!,
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                // Mensagem de sucesso
                Obx(() {
                  if (mensagemSucesso.value != null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mensagemSucesso.value!,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

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
            child: Text('FECHAR'),
          ),
          Obx(() => ElevatedButton(
            onPressed: salvando.value ? null : () async {
              // Limpar mensagens anteriores
              mensagemErro.value = null;
              mensagemSucesso.value = null;

              if (nomeController.text.isEmpty) {
                mensagemErro.value = 'O nome é obrigatório';
                return;
              }

              salvando.value = true;

              final novoCliente = ClienteModel(
                nome: nomeController.text.trim().toUpperCase(),
                contacto: contactoController.text.isEmpty
                    ? null
                    : contactoController.text.trim(),
                contacto2: contacto2Controller.text.isEmpty
                    ? null
                    : contacto2Controller.text.trim(),
                email: emailController.text.isEmpty
                    ? null
                    : emailController.text.trim(),
                endereco: enderecoController.text.isEmpty
                    ? null
                    : enderecoController.text.trim(),
                bairro: bairroController.text.isEmpty
                    ? null
                    : bairroController.text.trim(),
                cidade: cidadeController.text.isEmpty
                    ? null
                    : cidadeController.text.trim(),
                nuit: nuitController.text.isEmpty
                    ? null
                    : nuitController.text.trim(),
                observacoes: observacoesController.text.isEmpty
                    ? null
                    : observacoesController.text.trim(),
              );

              String? resultado;
              if (cliente == null) {
                resultado = await controller.adicionarCliente(novoCliente);
              } else {
                resultado = await controller.editarCliente(cliente.id!, novoCliente);
              }

              salvando.value = false;

              if (resultado != null) {
                // Erro - mostrar mensagem
                mensagemErro.value = resultado;
              } else {
                // Sucesso
                if (cliente == null) {
                  // Novo cliente - limpar campos para continuar registrando
                  mensagemSucesso.value = 'Cliente "${novoCliente.nome}" salvo com sucesso! Continue registrando...';
                  nomeController.clear();
                  contactoController.clear();
                  contacto2Controller.clear();
                  emailController.clear();
                  enderecoController.clear();
                  bairroController.clear();
                  cidadeController.clear();
                  nuitController.clear();
                  observacoesController.clear();
                } else {
                  // Edição - fechar dialog
                  Get.back();
                }
              }
            },
            child: salvando.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('SALVAR'),
          )),
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
