import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/permissao_repository.dart';
import '../../../data/repositories/perfil_usuario_repository.dart';
import '../../../data/models/perfil_usuario_model.dart';
import '../../../data/models/permissao_model.dart';

class ConfigurarPermissoesTab extends StatefulWidget {
  const ConfigurarPermissoesTab({Key? key}) : super(key: key);

  @override
  State<ConfigurarPermissoesTab> createState() =>
      _ConfigurarPermissoesTabState();
}

class _ConfigurarPermissoesTabState extends State<ConfigurarPermissoesTab> {
  final PermissaoRepository _permissaoRepo = Get.put(PermissaoRepository());
  final PerfilUsuarioRepository _perfilRepo = Get.put(PerfilUsuarioRepository());

  final RxList<PermissaoModel> permissoes = <PermissaoModel>[].obs;
  final RxList<PerfilUsuarioModel> perfis = <PerfilUsuarioModel>[].obs;
  final Rxn<PermissaoModel> permissaoSelecionada = Rxn<PermissaoModel>();
  final RxMap<int, bool> perfisPermissao = <int, bool>{}.obs;
  final RxBool carregando = false.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      carregando.value = true;
      permissoes.value = await _permissaoRepo.listarTodas();
      perfis.value = await _perfilRepo.listarAtivos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _carregarPermissoesDaOperacao(PermissaoModel permissao) async {
    try {
      carregando.value = true;
      perfisPermissao.clear();

      for (final perfil in perfis) {
        final permissoesPerfil =
            await _permissaoRepo.listarPermissoesPerfil(perfil.id!);
        final temPermissao = permissoesPerfil.any((p) => p.id == permissao.id);
        perfisPermissao[perfil.id!] = temPermissao;
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar permissões: $e');
    } finally {
      carregando.value = false;
    }
  }

  void _selecionarTodosPerfis(bool valor) {
    for (final perfil in perfis) {
      perfisPermissao[perfil.id!] = valor;
    }
  }

  Future<void> _gravarPermissoes() async {
    if (permissaoSelecionada.value == null) {
      Get.snackbar('Atenção', 'Selecione uma operação');
      return;
    }

    try {
      carregando.value = true;

      for (final perfil in perfis) {
        final temPermissao = perfisPermissao[perfil.id!] ?? false;

        if (temPermissao) {
          await _permissaoRepo.atribuirPermissao(
            perfil.id!,
            permissaoSelecionada.value!.id!,
          );
        } else {
          await _permissaoRepo.removerPermissao(
            perfil.id!,
            permissaoSelecionada.value!.id!,
          );
        }
      }

      Get.snackbar(
        'Sucesso',
        'Permissões gravadas com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao gravar permissões: $e');
    } finally {
      carregando.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (carregando.value && permissoes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[100],
              child: Row(
                children: [
                  const Icon(Icons.security, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'CONFIGURAR OPERAÇÕES POR PERFIL',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coluna da Operação (Permissão)
                    Expanded(
                      flex: 2,
                      child: _buildOperacaoPanel(),
                    ),

                    const SizedBox(width: 24),

                    // Coluna dos Perfis
                    Expanded(
                      flex: 1,
                      child: _buildPerfisPanel(),
                    ),
                  ],
                ),
              ),
            ),

            // Rodapé com botões
            _buildFooter(),
          ],
        );
      }),
    );
  }

  Widget _buildOperacaoPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OPERAÇÃO',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Obx(() => DropdownButtonFormField<PermissaoModel>(
                value: permissaoSelecionada.value,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                isExpanded: true,
                items: permissoes.map((permissao) {
                  return DropdownMenuItem(
                    value: permissao,
                    child: Text(
                      permissao.nome.toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  permissaoSelecionada.value = value;
                  if (value != null) {
                    await _carregarPermissoesDaOperacao(value);
                  }
                },
              )),
          const SizedBox(height: 16),
          if (permissaoSelecionada.value != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categoria: ${permissaoSelecionada.value!.categoria ?? "N/A"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descrição: ${permissaoSelecionada.value!.descricao ?? "Sem descrição"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerfisPanel() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PERFIL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(() => Text(
                    '[${perfisPermissao.values.where((v) => v).length}/${perfis.length}]',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount: perfis.length,
                  itemBuilder: (context, index) {
                    final perfil = perfis[index];
                    final temPermissao = perfisPermissao[perfil.id] ?? false;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: temPermissao ? Colors.blue[50] : Colors.white,
                        border: Border.all(
                          color: temPermissao ? Colors.blue : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: CheckboxListTile(
                        title: Text(
                          perfil.nome.toUpperCase(),
                          style: TextStyle(
                            fontWeight:
                                temPermissao ? FontWeight.bold : FontWeight.normal,
                            color: temPermissao ? Colors.blue[900] : Colors.black,
                          ),
                        ),
                        value: temPermissao,
                        onChanged: permissaoSelecionada.value != null
                            ? (value) {
                                perfisPermissao[perfil.id!] = value ?? false;
                              }
                            : null,
                        activeColor: Colors.blue,
                      ),
                    );
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Obx(() => Checkbox(
                value: perfisPermissao.values.isNotEmpty &&
                    perfisPermissao.values.every((v) => v),
                tristate: true,
                onChanged: permissaoSelecionada.value != null
                    ? (value) {
                        _selecionarTodosPerfis(value ?? false);
                      }
                    : null,
              )),
          const Text(
            'SELECCIONAR TODOS PERFIS',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _gravarPermissoes,
            icon: const Icon(Icons.save),
            label: const Text('GRAVAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              permissaoSelecionada.value = null;
              perfisPermissao.clear();
            },
            icon: const Icon(Icons.close),
            label: const Text('VOLTAR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}
