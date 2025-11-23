import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/fornecedor_repository.dart';
import '../../../data/models/fornecedor_model.dart';

class FornecedoresTab extends StatefulWidget {
  const FornecedoresTab({Key? key}) : super(key: key);

  @override
  _FornecedoresTabState createState() => _FornecedoresTabState();
}

class _FornecedoresTabState extends State<FornecedoresTab> {
  final FornecedorRepository _repo = Get.put(FornecedorRepository());
  final RxList<FornecedorModel> fornecedores = <FornecedorModel>[].obs;
  final RxBool isLoading = false.obs;
  final TextEditingController pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarFornecedores();
  }

  Future<void> carregarFornecedores() async {
    try {
      isLoading.value = true;
      fornecedores.value = await _repo.listarTodos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar fornecedores: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pesquisar() async {
    if (pesquisaController.text.isEmpty) {
      carregarFornecedores();
      return;
    }

    try {
      isLoading.value = true;
      fornecedores.value = await _repo.pesquisar(pesquisaController.text);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barra de pesquisa
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pesquisaController,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar fornecedor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => pesquisar(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: pesquisar,
                  icon: const Icon(Icons.search),
                  label: const Text('PESQUISAR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: carregarFornecedores,
                  icon: const Icon(Icons.refresh),
                  label: const Text('LIMPAR'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (fornecedores.isEmpty) {
                return const Center(
                  child: Text('Nenhum fornecedor cadastrado'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: fornecedores.length,
                itemBuilder: (context, index) {
                  final fornecedor = fornecedores[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Get.theme.primaryColor,
                        child: const Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(
                        fornecedor.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fornecedor.nif != null)
                            Text('NIF: ${fornecedor.nif}'),
                          if (fornecedor.telefone != null)
                            Text('Tel: ${fornecedor.telefone}'),
                          if (fornecedor.email != null)
                            Text('Email: ${fornecedor.email}'),
                          if (fornecedor.cidade != null)
                            Text('Cidade: ${fornecedor.cidade}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => mostrarDialog(fornecedor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => confirmarDelete(fornecedor.id!),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => mostrarDialog(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void mostrarDialog(FornecedorModel? fornecedor) {
    final nomeController = TextEditingController(text: fornecedor?.nome ?? '');
    final nifController = TextEditingController(text: fornecedor?.nif ?? '');
    final emailController = TextEditingController(text: fornecedor?.email ?? '');
    final telefoneController = TextEditingController(text: fornecedor?.telefone ?? '');
    final moradaController = TextEditingController(text: fornecedor?.morada ?? '');
    final cidadeController = TextEditingController(text: fornecedor?.cidade ?? '');
    final codigoPostalController = TextEditingController(text: fornecedor?.codigoPostal ?? '');
    final paisController = TextEditingController(text: fornecedor?.pais ?? 'Portugal');
    final contactoController = TextEditingController(text: fornecedor?.contacto ?? '');
    final observacoesController = TextEditingController(text: fornecedor?.observacoes ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(fornecedor == null ? 'Novo Fornecedor' : 'Editar Fornecedor'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: nifController,
                        decoration: const InputDecoration(
                          labelText: 'NIF',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: telefoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: moradaController,
                  decoration: const InputDecoration(
                    labelText: 'Morada',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cidadeController,
                        decoration: const InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: codigoPostalController,
                        decoration: const InputDecoration(
                          labelText: 'Código Postal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: paisController,
                        decoration: const InputDecoration(
                          labelText: 'País',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: contactoController,
                        decoration: const InputDecoration(
                          labelText: 'Pessoa de Contacto',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: observacoesController,
                  decoration: const InputDecoration(
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
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }

              final novoFornecedor = FornecedorModel(
                id: fornecedor?.id,
                nome: nomeController.text,
                nif: nifController.text.isEmpty ? null : nifController.text,
                email: emailController.text.isEmpty ? null : emailController.text,
                telefone: telefoneController.text.isEmpty ? null : telefoneController.text,
                morada: moradaController.text.isEmpty ? null : moradaController.text,
                cidade: cidadeController.text.isEmpty ? null : cidadeController.text,
                codigoPostal: codigoPostalController.text.isEmpty ? null : codigoPostalController.text,
                pais: paisController.text.isEmpty ? 'Portugal' : paisController.text,
                contacto: contactoController.text.isEmpty ? null : contactoController.text,
                observacoes: observacoesController.text.isEmpty ? null : observacoesController.text,
              );

              try {
                if (fornecedor == null) {
                  await _repo.inserir(novoFornecedor);
                  Get.snackbar('Sucesso', 'Fornecedor adicionado com sucesso',
                      backgroundColor: Colors.green, colorText: Colors.white);
                } else {
                  await _repo.atualizar(fornecedor.id!, novoFornecedor);
                  Get.snackbar('Sucesso', 'Fornecedor atualizado com sucesso',
                      backgroundColor: Colors.green, colorText: Colors.white);
                }

                Get.back();
                carregarFornecedores();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao salvar fornecedor: $e');
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Deseja realmente excluir este fornecedor?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _repo.deletar(id);
                Get.back();
                Get.snackbar('Sucesso', 'Fornecedor excluído com sucesso',
                    backgroundColor: Colors.green, colorText: Colors.white);
                carregarFornecedores();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao excluir fornecedor: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }
}
