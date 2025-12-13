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

  // Seleção múltipla
  final RxSet<int> mesasSelecionadas = <int>{}.obs;
  final RxBool modoSelecao = false.obs;

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
      // Erro silencioso
    } finally {
      isLoading.value = false;
    }
  }

  void _toggleSelecaoMesa(int mesaId) {
    if (mesasSelecionadas.contains(mesaId)) {
      mesasSelecionadas.remove(mesaId);
    } else {
      mesasSelecionadas.add(mesaId);
    }
    modoSelecao.value = mesasSelecionadas.isNotEmpty;
  }

  void _selecionarTodasDoLocal(int localId) {
    final mesasDoLocal = mesas.where((m) => m.localId == localId).toList();
    for (var mesa in mesasDoLocal) {
      if (mesa.id != null) {
        mesasSelecionadas.add(mesa.id!);
      }
    }
    modoSelecao.value = mesasSelecionadas.isNotEmpty;
  }

  void _limparSelecao() {
    mesasSelecionadas.clear();
    modoSelecao.value = false;
  }

  Future<void> _deletarMesasSelecionadas() async {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja remover ${mesasSelecionadas.length} mesa(s)?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              for (var id in mesasSelecionadas.toList()) {
                await _mesaRepo.deletar(id);
              }
              _limparSelecao();
              _carregarDados();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
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
              ElevatedButton(
                onPressed: _adicionarLocal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Get.theme.primaryColor,
                ),
                child: Text('NOVO LOCAL'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _carregarDados,
                child: Text('ATUALIZAR'),
              ),
            ],
          ),

          // Barra de seleção
          Obx(() {
            if (modoSelecao.value) {
              return Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red[50],
                child: Row(
                  children: [
                    Text(
                      '${mesasSelecionadas.length} mesa(s) selecionada(s)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _deletarMesasSelecionadas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('APAGAR SELECIONADAS'),
                    ),
                    SizedBox(width: 8),
                    TextButton(
                      onPressed: _limparSelecao,
                      child: Text('CANCELAR'),
                    ),
                  ],
                ),
              );
            }
            return SizedBox.shrink();
          }),

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
                      ElevatedButton(
                        onPressed: _adicionarLocal,
                        child: Text('ADICIONAR LOCAL'),
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
                          if (mesasDoLocal.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.select_all, color: Colors.orange),
                              onPressed: () => _selecionarTodasDoLocal(local.id!),
                              tooltip: 'Selecionar todas',
                            ),
                          IconButton(
                            icon: Icon(Icons.add, color: Colors.green),
                            onPressed: () => _adicionarMesasEmLote(local),
                            tooltip: 'Adicionar mesas',
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editarLocal(local),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deletarLocal(local),
                            tooltip: 'Remover local',
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
                                      ElevatedButton(
                                        onPressed: () => _adicionarMesasEmLote(local),
                                        child: Text('ADICIONAR MESAS'),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Obx(() => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: mesasDoLocal.map((mesa) {
                                    final isSelected = mesasSelecionadas.contains(mesa.id);
                                    return FilterChip(
                                      label: Text('Mesa ${mesa.numero}'),
                                      avatar: Icon(
                                        Icons.table_restaurant,
                                        size: 18,
                                        color: isSelected ? Colors.white : (mesa.isLivre ? Colors.green : Colors.orange),
                                      ),
                                      selected: isSelected,
                                      selectedColor: Colors.red[300],
                                      onSelected: (_) => _toggleSelecaoMesa(mesa.id!),
                                    );
                                  }).toList(),
                                )),
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
              if (nomeController.text.isEmpty) return;

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
                // Erro silencioso
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
                // Erro silencioso
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }

  void _deletarLocal(LocalMesaModel local) {
    final mesasDoLocal = mesas.where((m) => m.localId == local.id).toList();

    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text(
          mesasDoLocal.isNotEmpty
            ? 'Este local possui ${mesasDoLocal.length} mesa(s). Deseja remover o local e todas as mesas?'
            : 'Deseja remover o local "${local.nome}"?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Deletar mesas primeiro
                for (var mesa in mesasDoLocal) {
                  await _mesaRepo.deletar(mesa.id!);
                }
                await _localRepo.deletar(local.id!);
                Get.back();
                _carregarDados();
              } catch (e) {
                // Erro silencioso
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
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
                // Erro silencioso
              }
            },
            child: Text('CRIAR'),
          ),
        ],
      ),
    );
  }
}
