import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/local_mesa_model.dart';
import '../../../data/models/mesa_model.dart';
import '../../../data/repositories/local_mesa_repository.dart';
import '../../../data/repositories/mesa_repository.dart';

class MesasTab extends StatefulWidget {
  @override
  State<MesasTab> createState() => _MesasTabState();
}

class _MesasTabState extends State<MesasTab> {
  final _localRepo = LocalMesaRepository();
  final _mesaRepo = MesaRepository();

  final RxList<LocalMesaModel> locais = <LocalMesaModel>[].obs;
  final RxList<MesaModel> mesas = <MesaModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      isLoading.value = true;
      locais.value = await _localRepo.listarTodos();
      mesas.value = await _mesaRepo.listarTodas();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho
          Row(
            children: [
              Icon(Icons.table_restaurant, size: 32, color: Get.theme.primaryColor),
              SizedBox(width: 12),
              Text(
                'CONFIGURAÇÃO DE MESAS',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: _adicionarLocal,
                icon: Icon(Icons.add),
                label: Text('NOVO LOCAL'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _carregarDados,
                icon: Icon(Icons.refresh),
                label: Text('ATUALIZAR'),
              ),
            ],
          ),
          Divider(height: 32),

          // Conteúdo
          Expanded(
            child: Obx(() {
              if (isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (locais.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum local cadastrado'),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _adicionarLocal,
                        icon: Icon(Icons.add),
                        label: Text('ADICIONAR LOCAL'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: locais.length,
                itemBuilder: (context, index) {
                  final local = locais[index];
                  final mesasDoLocal = mesas.where((m) => m.localId == local.id).toList();

                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Icon(Icons.location_on, color: Get.theme.primaryColor),
                          SizedBox(width: 12),
                          Text(
                            local.nome,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 12),
                          Chip(
                            label: Text('${mesasDoLocal.length} mesas'),
                            backgroundColor: Colors.blue[50],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _adicionarMesasEmLote(local),
                            tooltip: 'Adicionar mesas em lote',
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarLocal(local),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (local.descricao != null && local.descricao!.isNotEmpty)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    local.descricao!,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              if (mesasDoLocal.isEmpty)
                                Center(
                                  child: Column(
                                    children: [
                                      Text('Nenhuma mesa cadastrada neste local'),
                                      SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _adicionarMesasEmLote(local),
                                        icon: Icon(Icons.add),
                                        label: Text('ADICIONAR MESAS'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: mesasDoLocal.map((mesa) {
                                    return Chip(
                                      label: Text('Mesa ${mesa.numero}'),
                                      avatar: Icon(
                                        Icons.table_restaurant,
                                        size: 18,
                                        color: mesa.isLivre ? Colors.green : Colors.orange,
                                      ),
                                      deleteIcon: Icon(Icons.delete, size: 18),
                                      onDeleted: () => _deletarMesa(mesa),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _adicionarLocal() {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Adicionar Local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex: BALCAO, SALA, ESPLANADA',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição',
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
            onPressed: () async {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }

              try {
                final local = LocalMesaModel(
                  nome: nomeController.text.toUpperCase(),
                  descricao: descricaoController.text,
                  ordem: locais.length + 1,
                );

                await _localRepo.inserir(local);
                Get.back();
                _carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao adicionar local: $e');
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _editarLocal(LocalMesaModel local) {
    final nomeController = TextEditingController(text: local.nome);
    final descricaoController = TextEditingController(text: local.descricao);

    Get.dialog(
      AlertDialog(
        title: Text('Editar Local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome *'),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
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
            onPressed: () async {
              try {
                final localAtualizado = LocalMesaModel(
                  nome: nomeController.text.toUpperCase(),
                  descricao: descricaoController.text,
                  ordem: local.ordem,
                );

                await _localRepo.atualizar(local.id!, localAtualizado);
                Get.back();
                _carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao atualizar local: $e');
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _adicionarMesasEmLote(LocalMesaModel local) {
    final numeroInicialController = TextEditingController();
    final quantidadeController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('Adicionar Mesas - ${local.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: numeroInicialController,
              decoration: InputDecoration(
                labelText: 'Número Inicial *',
                hintText: 'Ex: 1',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: quantidadeController,
              decoration: InputDecoration(
                labelText: 'Quantidade *',
                hintText: 'Ex: 10',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              final numeroInicial = int.tryParse(numeroInicialController.text);
              final quantidade = int.tryParse(quantidadeController.text);

              if (numeroInicial == null || quantidade == null || quantidade < 1) {
                Get.snackbar('Erro', 'Valores inválidos');
                return;
              }

              try {
                await _mesaRepo.criarMesasLote(
                  localId: local.id!,
                  quantidadeMesas: quantidade,
                  numeroInicial: numeroInicial,
                );
                Get.back();
                _carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao criar mesas: $e');
              }
            },
            child: Text('CRIAR'),
          ),
        ],
      ),
    );
  }

  void _deletarMesa(MesaModel mesa) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja realmente excluir a Mesa ${mesa.numero}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _mesaRepo.deletar(mesa.id!);
                Get.back();
                _carregarDados();
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao excluir mesa: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}
