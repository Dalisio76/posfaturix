import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/impressora_model.dart';
import '../../../data/repositories/impressora_repository.dart';

class MapeamentoImpressorasTab extends StatefulWidget {
  const MapeamentoImpressorasTab({Key? key}) : super(key: key);

  @override
  State<MapeamentoImpressorasTab> createState() => _MapeamentoImpressorasTabState();
}

class _MapeamentoImpressorasTabState extends State<MapeamentoImpressorasTab> {
  late final ImpressoraRepository _repo;
  final RxList<TipoDocumentoModel> tiposDocumento = <TipoDocumentoModel>[].obs;
  final RxList<ImpressoraModel> impressoras = <ImpressoraModel>[].obs;
  final RxMap<int, int?> mapeamentos = <int, int?>{}.obs; // tipoDocId -> impressoraId
  final RxBool carregando = false.obs;

  @override
  void initState() {
    super.initState();
    _repo = ImpressoraRepository();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      carregando.value = true;

      // Carregar tipos de documento
      tiposDocumento.value = await _repo.listarTiposDocumento();

      // Carregar impressoras ativas
      impressoras.value = await _repo.listarAtivas();

      // Carregar mapeamentos existentes
      final maps = await _repo.listarMapeamentos();
      mapeamentos.clear();
      for (final map in maps) {
        if (map.impressoraId != null) {
          mapeamentos[map.tipoDocumentoId] = map.impressoraId;
        }
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            _buildHeader(),
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: Colors.purple[700],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.purple[700],
                tabs: const [
                  Tab(icon: Icon(Icons.description), text: 'Por Documento'),
                  Tab(icon: Icon(Icons.print), text: 'Por Impressora'),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (carregando.value && tiposDocumento.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (impressoras.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_disabled, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma impressora cadastrada',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cadastre impressoras primeiro para poder mapeá-las',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  children: [
                    _buildListaPorDocumento(),
                    _buildListaPorImpressora(),
                  ],
                );
              }),
            ),
            _buildFooter(),
          ],
        ),
      ),
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
                child: Icon(Icons.settings_ethernet, color: Colors.purple[700], size: 28),
              ),
              const SizedBox(width: 16),
              const Text(
                'MAPEAMENTO DE DOCUMENTOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Configure qual impressora usar para cada tipo de documento',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaPorDocumento() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: tiposDocumento.map((tipo) => _buildCard(tipo)).toList(),
    );
  }

  Widget _buildListaPorImpressora() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: impressoras.map((impressora) => _buildCardImpressora(impressora)).toList(),
    );
  }

  Widget _buildCard(TipoDocumentoModel tipo) {
    final Color corIcone = _getCorPorCodigo(tipo.codigo);
    final IconData icone = _getIconePorCodigo(tipo.codigo);

    return Obx(() {
      final impressoraIdSelecionada = mapeamentos[tipo.id];
      final impressoraSelecionada = impressoraIdSelecionada != null
          ? impressoras.firstWhereOrNull((i) => i.id == impressoraIdSelecionada)
          : null;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: corIcone.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Ícone do documento
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: corIcone.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: corIcone, size: 32),
              ),
              const SizedBox(width: 16),
              // Info do documento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo.nome,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tipo.codigo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (tipo.descricao != null && tipo.descricao!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        tipo.descricao!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Seletor de impressora
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Impressora:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      value: impressoraIdSelecionada,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        prefixIcon: Icon(
                          impressoraSelecionada != null ? Icons.print : Icons.print_disabled,
                          color: impressoraSelecionada != null ? Colors.green : Colors.grey,
                        ),
                      ),
                      hint: const Text('Nenhuma selecionada'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Nenhuma (sem impressão)'),
                        ),
                        ...impressoras.map((impressora) {
                          return DropdownMenuItem<int?>(
                            value: impressora.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTipoIcon(impressora.tipo),
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    impressora.nome,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (novaImpressoraId) async {
                        await _salvarMapeamento(tipo.id!, novaImpressoraId);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCardImpressora(ImpressoraModel impressora) {
    return Obx(() {
      // Encontrar quais documentos estão mapeados para esta impressora
      final documentosMapeados = mapeamentos.entries
          .where((entry) => entry.value == impressora.id)
          .map((entry) => entry.key)
          .toSet();

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.blue.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getTipoIcon(impressora.tipo),
                      color: Colors.blue[700],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          impressora.nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              impressora.tipo.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            if (impressora.caminhoRede != null && impressora.caminhoRede!.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.share, size: 14, color: Colors.purple[600]),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  impressora.caminhoRede!,
                                  style: TextStyle(fontSize: 12, color: Colors.purple[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: documentosMapeados.isEmpty ? Colors.grey[200] : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${documentosMapeados.length} documentos',
                      style: TextStyle(
                        color: documentosMapeados.isEmpty ? Colors.grey[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Documentos que usam esta impressora:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tiposDocumento.map((tipo) {
                  final estaMapeado = documentosMapeados.contains(tipo.id);
                  final cor = _getCorPorCodigo(tipo.codigo);

                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconePorCodigo(tipo.codigo),
                          size: 16,
                          color: estaMapeado ? Colors.white : cor,
                        ),
                        const SizedBox(width: 6),
                        Text(tipo.nome),
                      ],
                    ),
                    selected: estaMapeado,
                    onSelected: (selected) async {
                      if (selected) {
                        await _salvarMapeamento(tipo.id!, impressora.id);
                      } else {
                        await _salvarMapeamento(tipo.id!, null);
                      }
                    },
                    selectedColor: cor,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: estaMapeado ? Colors.white : Colors.black87,
                      fontWeight: estaMapeado ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _salvarMapeamento(int tipoDocumentoId, int? impressoraId) async {
    try {
      if (impressoraId == null) {
        // Remover mapeamento
        final impressoraAntiga = mapeamentos[tipoDocumentoId];
        if (impressoraAntiga != null) {
          await _repo.removerAssociacaoDocumentoImpressora(
            tipoDocumentoId: tipoDocumentoId,
            impressoraId: impressoraAntiga,
          );
        }
        mapeamentos[tipoDocumentoId] = null;
      } else {
        // Criar/atualizar mapeamento
        await _repo.associarDocumentoImpressora(
          tipoDocumentoId: tipoDocumentoId,
          impressoraId: impressoraId,
        );
        mapeamentos[tipoDocumentoId] = impressoraId;
      }

      Get.snackbar(
        'Sucesso',
        'Mapeamento atualizado',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao salvar mapeamento: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Reverter mudança
      _carregarDados();
    }
  }

  Color _getCorPorCodigo(String codigo) {
    switch (codigo) {
      case 'RECIBO_VENDA':
        return Colors.green;
      case 'CONTA_MESA':
        return Colors.blue;
      case 'PEDIDO_COZINHA':
        return Colors.orange;
      case 'PEDIDO_BAR':
        return Colors.purple;
      case 'COTACAO':
        return Colors.teal;
      case 'FECHO_CAIXA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconePorCodigo(String codigo) {
    switch (codigo) {
      case 'RECIBO_VENDA':
        return Icons.receipt;
      case 'CONTA_MESA':
        return Icons.restaurant_menu;
      case 'PEDIDO_COZINHA':
        return Icons.restaurant;
      case 'PEDIDO_BAR':
        return Icons.local_bar;
      case 'COTACAO':
        return Icons.request_quote;
      case 'FECHO_CAIXA':
        return Icons.point_of_sale;
      default:
        return Icons.description;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'termica':
        return Icons.receipt_long;
      case 'matricial':
        return Icons.print;
      case 'laser':
        return Icons.print_outlined;
      default:
        return Icons.print;
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
          Obx(() {
            final totalMapeados = mapeamentos.values.where((id) => id != null).length;
            final total = tiposDocumento.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$totalMapeados de $total documentos mapeados',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _carregarDados,
            icon: const Icon(Icons.refresh),
            label: const Text('ATUALIZAR'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              side: BorderSide(color: Colors.blue[300]!),
            ),
          ),
        ],
      ),
    );
  }
}
