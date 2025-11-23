import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/perfil_usuario_repository.dart';
import '../../../data/models/perfil_usuario_model.dart';

class PerfisUsuarioTab extends StatefulWidget {
  const PerfisUsuarioTab({Key? key}) : super(key: key);

  @override
  _PerfisUsuarioTabState createState() => _PerfisUsuarioTabState();
}

class _PerfisUsuarioTabState extends State<PerfisUsuarioTab> {
  final PerfilUsuarioRepository _repository = Get.put(PerfilUsuarioRepository());
  final RxList<PerfilUsuarioModel> perfis = <PerfilUsuarioModel>[].obs;
  final RxInt linhaSelecionada = (-1).obs;

  final TextEditingController pesquisaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    carregarPerfis();
  }

  Future<void> carregarPerfis() async {
    try {
      perfis.value = await _repository.listarTodos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar perfis: $e');
    }
  }

  Future<void> pesquisar() async {
    try {
      if (pesquisaController.text.isEmpty) {
        await carregarPerfis();
      } else {
        perfis.value = await _repository.pesquisar(pesquisaController.text);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    }
  }

  void adicionarPerfil() {
    _mostrarDialog(null);
  }

  void editarPerfil(PerfilUsuarioModel perfil) {
    _mostrarDialog(perfil);
  }

  void _mostrarDialog(PerfilUsuarioModel? perfil) {
    final nomeController = TextEditingController(text: perfil?.nome ?? '');
    final descricaoController = TextEditingController(text: perfil?.descricao ?? '');
    final RxBool ativo = (perfil?.ativo ?? true).obs;

    Get.dialog(
      AlertDialog(
        title: Text(perfil == null ? 'Novo Perfil' : 'Editar Perfil'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Obx(() => CheckboxListTile(
                    title: const Text('Ativo'),
                    value: ativo.value,
                    onChanged: (value) => ativo.value = value ?? true,
                  )),
            ],
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

              try {
                final perfilData = PerfilUsuarioModel(
                  id: perfil?.id,
                  nome: nomeController.text,
                  descricao: descricaoController.text,
                  ativo: ativo.value,
                );

                if (perfil == null) {
                  await _repository.inserir(perfilData);
                  Get.snackbar('Sucesso', 'Perfil criado com sucesso');
                } else {
                  await _repository.atualizar(perfilData);
                  Get.snackbar('Sucesso', 'Perfil atualizado com sucesso');
                }

                Get.back();
                await carregarPerfis();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao salvar perfil: $e');
              }
            },
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void deletarPerfil(PerfilUsuarioModel perfil) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente deletar o perfil "${perfil.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _repository.deletar(perfil.id!);
                Get.back();
                Get.snackbar('Sucesso', 'Perfil deletado com sucesso');
                await carregarPerfis();
              } catch (e) {
                Get.back();
                Get.snackbar('Erro', 'Erro ao deletar perfil: $e\n\nVerifique se não há usuários com este perfil.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: pesquisaController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar perfil...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => pesquisar(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: pesquisar,
                  icon: const Icon(Icons.search),
                  label: const Text('PESQUISAR'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: adicionarPerfil,
                  icon: const Icon(Icons.add),
                  label: const Text('NOVO'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),

          // Tabela
          Expanded(
            child: Obx(() => SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.grey[300]),
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('NOME')),
                      DataColumn(label: Text('DESCRIÇÃO')),
                      DataColumn(label: Text('ATIVO')),
                      DataColumn(label: Text('AÇÕES')),
                    ],
                    rows: perfis.asMap().entries.map((entry) {
                      final index = entry.key;
                      final perfil = entry.value;

                      return DataRow(
                        selected: linhaSelecionada.value == index,
                        onSelectChanged: (_) => linhaSelecionada.value = index,
                        cells: [
                          DataCell(Text(perfil.id.toString())),
                          DataCell(Text(perfil.nome)),
                          DataCell(Text(perfil.descricao ?? '')),
                          DataCell(
                            Icon(
                              perfil.ativo ? Icons.check_circle : Icons.cancel,
                              color: perfil.ativo ? Colors.green : Colors.red,
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editarPerfil(perfil),
                                tooltip: 'Editar',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deletarPerfil(perfil),
                                tooltip: 'Deletar',
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                )),
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
