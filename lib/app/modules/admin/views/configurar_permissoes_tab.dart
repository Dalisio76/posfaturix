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
  final RxBool carregando = false.obs;
  final RxString modoVisualizacao = 'perfil'.obs; // 'perfil' ou 'permissao'
  final Rxn<PerfilUsuarioModel> perfilSelecionado = Rxn<PerfilUsuarioModel>();
  final RxMap<int, bool> permissoesPerfil = <int, bool>{}.obs;

  // Cores das categorias (matching admin dashboard)
  final Map<String, Color> coresCategorias = {
    'VENDAS': Colors.blue,
    'STOCK': Colors.green,
    'CADASTROS': Colors.blue,
    'FINANCEIRO': Colors.orange,
    'RELATORIOS': Colors.orange,
    'ADMIN': Colors.purple,
    'NOTIFICACOES': Colors.teal,
    'DIVERSOS': Colors.grey,
  };

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

      // Seleciona primeiro perfil por padrão
      if (perfis.isNotEmpty) {
        perfilSelecionado.value = perfis.first;
        await _carregarPermissoesDoPerfil(perfis.first);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar dados: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _carregarPermissoesDoPerfil(PerfilUsuarioModel perfil) async {
    try {
      carregando.value = true;
      permissoesPerfil.clear();

      final permissoesDoPerfil = await _permissaoRepo.listarPermissoesPerfil(perfil.id!);

      for (final permissao in permissoes) {
        permissoesPerfil[permissao.id!] = permissoesDoPerfil.any((p) => p.id == permissao.id);
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao carregar permissões do perfil: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Future<void> _salvarPermissoes() async {
    if (perfilSelecionado.value == null) {
      Get.snackbar(
        'Atenção',
        'Selecione um perfil',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    try {
      carregando.value = true;

      for (final permissao in permissoes) {
        final temPermissao = permissoesPerfil[permissao.id!] ?? false;

        if (temPermissao) {
          await _permissaoRepo.atribuirPermissao(
            perfilSelecionado.value!.id!,
            permissao.id!,
          );
        } else {
          await _permissaoRepo.removerPermissao(
            perfilSelecionado.value!.id!,
            permissao.id!,
          );
        }
      }

      Get.snackbar(
        'Sucesso',
        'Permissões salvas com sucesso',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar permissões: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      carregando.value = false;
    }
  }

  Map<String, List<PermissaoModel>> _agruparPermissoesPorCategoria() {
    final Map<String, List<PermissaoModel>> grupos = {};

    for (final permissao in permissoes) {
      final categoria = (permissao.categoria ?? 'DIVERSOS').toUpperCase();
      if (!grupos.containsKey(categoria)) {
        grupos[categoria] = [];
      }
      grupos[categoria]!.add(permissao);
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Obx(() {
        if (carregando.value && permissoes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(),
            ),
            _buildFooter(),
          ],
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: Colors.purple[700],
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'GESTÃO DE PERMISSÕES',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // Seletor de Perfil
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, color: Colors.purple[700], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'PERFIL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<PerfilUsuarioModel>(
                      value: perfilSelecionado.value,
                      underline: const SizedBox(),
                      items: perfis.map((perfil) {
                        return DropdownMenuItem(
                          value: perfil,
                          child: Text(
                            perfil.nome.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (perfil) async {
                        if (perfil != null) {
                          perfilSelecionado.value = perfil;
                          await _carregarPermissoesDoPerfil(perfil);
                        }
                      },
                    ),
                  ],
                ),
              )),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final total = permissoes.length;
            final ativas = permissoesPerfil.values.where((v) => v).length;
            return Row(
              children: [
                _buildStatChip(
                  icon: Icons.check_circle_outline,
                  label: 'Ativas',
                  value: '$ativas',
                  color: Colors.green,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.cancel_outlined,
                  label: 'Inativas',
                  value: '${total - ativas}',
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.apps,
                  label: 'Total',
                  value: '$total',
                  color: Colors.blue,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (perfilSelecionado.value == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Selecione um perfil para gerenciar permissões',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      final permissoesAgrupadas = _agruparPermissoesPorCategoria();

      return ListView(
        padding: const EdgeInsets.all(20),
        children: permissoesAgrupadas.entries.map((entry) {
          return _buildCategoriaCard(entry.key, entry.value);
        }).toList(),
      );
    });
  }

  Widget _buildCategoriaCard(String categoria, List<PermissaoModel> permissoesCategoria) {
    final cor = coresCategorias[categoria] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da categoria
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoriaIcon(categoria),
                    color: cor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  categoria,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
                const Spacer(),
                Obx(() {
                  final total = permissoesCategoria.length;
                  final ativas = permissoesCategoria.where((p) => permissoesPerfil[p.id!] ?? false).length;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$ativas/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // Lista de permissões
          Padding(
            padding: const EdgeInsets.all(8),
            child: Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: permissoesCategoria.map((permissao) {
                return _buildPermissaoChip(permissao, cor);
              }).toList(),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissaoChip(PermissaoModel permissao, Color cor) {
    return Obx(() {
      final ativa = permissoesPerfil[permissao.id!] ?? false;

      return InkWell(
        onTap: () {
          permissoesPerfil[permissao.id!] = !ativa;
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ativa ? cor.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: ativa ? cor : Colors.grey[300]!,
              width: ativa ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ativa ? Icons.check_box : Icons.check_box_outline_blank,
                color: ativa ? cor : Colors.grey[400],
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      permissao.nome.toUpperCase(),
                      style: TextStyle(
                        fontWeight: ativa ? FontWeight.bold : FontWeight.w600,
                        color: ativa ? cor : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    if (permissao.descricao != null && permissao.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        permissao.descricao!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'VENDAS':
        return Icons.point_of_sale;
      case 'STOCK':
        return Icons.inventory_2_outlined;
      case 'CADASTROS':
        return Icons.app_registration;
      case 'FINANCEIRO':
        return Icons.attach_money;
      case 'RELATORIOS':
        return Icons.assessment;
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'NOTIFICACOES':
        return Icons.notifications_outlined;
      default:
        return Icons.settings;
    }
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              if (perfilSelecionado.value != null) {
                _carregarPermissoesDoPerfil(perfilSelecionado.value!);
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('RESETAR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              side: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Selecionar todas
              for (final permissao in permissoes) {
                permissoesPerfil[permissao.id!] = true;
              }
            },
            icon: const Icon(Icons.select_all),
            label: const Text('SELECIONAR TODAS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              side: BorderSide(color: Colors.blue[300]!),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Desselecionar todas
              for (final permissao in permissoes) {
                permissoesPerfil[permissao.id!] = false;
              }
            },
            icon: const Icon(Icons.deselect),
            label: const Text('DESMARCAR TODAS'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              side: BorderSide(color: Colors.orange[300]!),
            ),
          ),
          const Spacer(),
          Obx(() => ElevatedButton.icon(
            onPressed: carregando.value ? null : _salvarPermissoes,
            icon: carregando.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(carregando.value ? 'SALVANDO...' : 'SALVAR PERMISSÕES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              elevation: 2,
            ),
          )),
        ],
      ),
    );
  }
}
