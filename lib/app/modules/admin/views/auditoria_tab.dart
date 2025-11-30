import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/auditoria_model.dart';
import '../../../data/repositories/auditoria_repository.dart';

class AuditoriaTab extends StatefulWidget {
  const AuditoriaTab({super.key});

  @override
  State<AuditoriaTab> createState() => _AuditoriaTabState();
}

class _AuditoriaTabState extends State<AuditoriaTab> with SingleTickerProviderStateMixin {
  late final AuditoriaRepository _repo;
  late TabController _tabController;

  // Listas reativas
  final RxList<AuditoriaModel> _auditorias = <AuditoriaModel>[].obs;
  final RxList<LogAcessoModel> _logsAcesso = <LogAcessoModel>[].obs;
  final RxList<HistoricoPrecoModel> _historicoPrecos = <HistoricoPrecoModel>[].obs;
  final RxBool _carregando = false.obs;

  // Filtros
  final RxString _filtroTabela = 'TODAS'.obs;
  final RxString _filtroOperacao = 'TODAS'.obs;
  final Rx<DateTime?> _filtroDataInicio = Rx<DateTime?>(null);
  final Rx<DateTime?> _filtroDataFim = Rx<DateTime?>(null);

  // Estatísticas
  final RxMap<String, dynamic> _estatisticas = <String, dynamic>{}.obs;

  @override
  void initState() {
    super.initState();
    _repo = AuditoriaRepository();
    _tabController = TabController(length: 4, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    _carregando.value = true;
    try {
      await Future.wait([
        _carregarAuditorias(),
        _carregarLogsAcesso(),
        _carregarHistoricoPrecos(),
        _carregarEstatisticas(),
      ]);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _carregando.value = false;
    }
  }

  Future<void> _carregarAuditorias() async {
    final dados = await _repo.listar(
      tabela: _filtroTabela.value == 'TODAS' ? null : _filtroTabela.value,
      operacao: _filtroOperacao.value == 'TODAS' ? null : _filtroOperacao.value,
      dataInicio: _filtroDataInicio.value,
      dataFim: _filtroDataFim.value,
      limit: 100,
    );
    _auditorias.value = dados;
  }

  Future<void> _carregarLogsAcesso() async {
    final dados = await _repo.listarLogsAcesso(limit: 100);
    _logsAcesso.value = dados;
  }

  Future<void> _carregarHistoricoPrecos() async {
    final dados = await _repo.listarHistoricoPrecos(limit: 50);
    _historicoPrecos.value = dados;
  }

  Future<void> _carregarEstatisticas() async {
    final stats = await _repo.obterEstatisticas();
    _estatisticas.value = stats;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cabeçalho com estatísticas
        _buildEstatisticasCard(),
        const SizedBox(height: 16),

        // Tabs
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'Auditoria'),
            Tab(icon: Icon(Icons.login), text: 'Acessos'),
            Tab(icon: Icon(Icons.attach_money), text: 'Preços'),
            Tab(icon: Icon(Icons.analytics), text: 'Relatórios'),
          ],
        ),
        const SizedBox(height: 16),

        // Conteúdo das tabs
        Expanded(
          child: Obx(() {
            if (_carregando.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildAuditoriaTab(),
                _buildLogsAcessoTab(),
                _buildHistoricoPrecosTab(),
                _buildRelatoriosTab(),
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildEstatisticasCard() {
    return Obx(() {
      final stats = _estatisticas;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Operações',
                '${stats['total_operacoes'] ?? 0}',
                Icons.trending_up,
                Colors.blue,
              ),
              _buildStatItem(
                'Usuários Ativos',
                '${stats['usuarios_ativos'] ?? 0}',
                Icons.people,
                Colors.green,
              ),
              _buildStatItem(
                'Inserções',
                '${stats['total_inserts'] ?? 0}',
                Icons.add_circle,
                Colors.orange,
              ),
              _buildStatItem(
                'Atualizações',
                '${stats['total_updates'] ?? 0}',
                Icons.edit,
                Colors.purple,
              ),
              _buildStatItem(
                'Exclusões',
                '${stats['total_deletes'] ?? 0}',
                Icons.delete,
                Colors.red,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAuditoriaTab() {
    return Column(
      children: [
        // Filtros
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Filtro por tabela
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: _filtroTabela.value,
                        decoration: const InputDecoration(
                          labelText: 'Tabela',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TODAS', child: Text('Todas')),
                          DropdownMenuItem(value: 'produtos', child: Text('Produtos')),
                          DropdownMenuItem(value: 'vendas', child: Text('Vendas')),
                          DropdownMenuItem(value: 'usuarios', child: Text('Usuários')),
                          DropdownMenuItem(value: 'clientes', child: Text('Clientes')),
                          DropdownMenuItem(value: 'mesas', child: Text('Mesas')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _filtroTabela.value = value;
                            _carregarAuditorias();
                          }
                        },
                      )),
                ),
                const SizedBox(width: 16),

                // Filtro por operação
                Expanded(
                  child: Obx(() => DropdownButtonFormField<String>(
                        value: _filtroOperacao.value,
                        decoration: const InputDecoration(
                          labelText: 'Operação',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'TODAS', child: Text('Todas')),
                          DropdownMenuItem(value: 'INSERT', child: Text('Criação')),
                          DropdownMenuItem(value: 'UPDATE', child: Text('Atualização')),
                          DropdownMenuItem(value: 'DELETE', child: Text('Exclusão')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            _filtroOperacao.value = value;
                            _carregarAuditorias();
                          }
                        },
                      )),
                ),
                const SizedBox(width: 16),

                // Botão limpar filtros
                ElevatedButton.icon(
                  onPressed: () {
                    _filtroTabela.value = 'TODAS';
                    _filtroOperacao.value = 'TODAS';
                    _filtroDataInicio.value = null;
                    _filtroDataFim.value = null;
                    _carregarAuditorias();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                ),
                const SizedBox(width: 8),

                // Botão atualizar
                ElevatedButton.icon(
                  onPressed: _carregarAuditorias,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Lista de auditoria
        Expanded(
          child: Obx(() {
            if (_auditorias.isEmpty) {
              return const Center(child: Text('Nenhum registro encontrado'));
            }

            return ListView.builder(
              itemCount: _auditorias.length,
              itemBuilder: (context, index) {
                final auditoria = _auditorias[index];
                return _buildAuditoriaCard(auditoria);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAuditoriaCard(AuditoriaModel auditoria) {
    Color operacaoColor;
    IconData operacaoIcon;

    switch (auditoria.operacao) {
      case 'INSERT':
        operacaoColor = Colors.green;
        operacaoIcon = Icons.add_circle;
        break;
      case 'UPDATE':
        operacaoColor = Colors.orange;
        operacaoIcon = Icons.edit;
        break;
      case 'DELETE':
        operacaoColor = Colors.red;
        operacaoIcon = Icons.delete;
        break;
      default:
        operacaoColor = Colors.grey;
        operacaoIcon = Icons.circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(operacaoIcon, color: operacaoColor),
        title: Text(
          '${auditoria.tabelaLegivel} - ${auditoria.operacaoLegivel}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${auditoria.usuarioNome ?? 'Sistema'} • ${DateFormat('dd/MM/yyyy HH:mm:ss').format(auditoria.dataOperacao)}',
        ),
        trailing: auditoria.registroId != null
            ? Chip(
                label: Text('ID: ${auditoria.registroId}'),
                backgroundColor: Colors.grey[200],
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (auditoria.descricao != null) ...[
                  Text(
                    auditoria.descricao!,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const Divider(),
                ],
                if (auditoria.terminalNome != null)
                  _buildInfoRow('Terminal', auditoria.terminalNome!),
                if (auditoria.ipAddress != null)
                  _buildInfoRow('IP', auditoria.ipAddress!),
                if (auditoria.dadosAnteriores != null) ...[
                  const SizedBox(height: 8),
                  const Text('Antes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _formatJson(auditoria.dadosAnteriores!),
                    style: TextStyle(fontFamily: 'monospace', color: Colors.red[700]),
                  ),
                ],
                if (auditoria.dadosNovos != null) ...[
                  const SizedBox(height: 8),
                  const Text('Depois:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    _formatJson(auditoria.dadosNovos!),
                    style: TextStyle(fontFamily: 'monospace', color: Colors.green[700]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsAcessoTab() {
    return Obx(() {
      if (_logsAcesso.isEmpty) {
        return const Center(child: Text('Nenhum log de acesso encontrado'));
      }

      return ListView.builder(
        itemCount: _logsAcesso.length,
        itemBuilder: (context, index) {
          final log = _logsAcesso[index];
          return _buildLogAcessoCard(log);
        },
      );
    });
  }

  Widget _buildLogAcessoCard(LogAcessoModel log) {
    Color statusColor = log.sucesso ? Colors.green : Colors.red;
    IconData statusIcon = log.sucesso ? Icons.check_circle : Icons.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(
          '${log.tipoLegivel} - ${log.usuarioNome ?? log.usuarioCodigo ?? 'Desconhecido'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(log.dataHora)),
            if (log.terminalNome != null) Text('Terminal: ${log.terminalNome}'),
            if (log.ipAddress != null) Text('IP: ${log.ipAddress}'),
            if (!log.sucesso && log.motivoFalha != null)
              Text(
                'Motivo: ${log.motivoFalha}',
                style: const TextStyle(color: Colors.red),
              ),
            if (log.tentativasUltimaHora != null && log.tentativasUltimaHora! > 3)
              Text(
                'Tentativas na última hora: ${log.tentativasUltimaHora}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: Text(log.icone, style: const TextStyle(fontSize: 24)),
      ),
    );
  }

  Widget _buildHistoricoPrecosTab() {
    return Obx(() {
      if (_historicoPrecos.isEmpty) {
        return const Center(child: Text('Nenhuma alteração de preço encontrada'));
      }

      return ListView.builder(
        itemCount: _historicoPrecos.length,
        itemBuilder: (context, index) {
          final historico = _historicoPrecos[index];
          return _buildHistoricoPrecoCard(historico);
        },
      );
    });
  }

  Widget _buildHistoricoPrecoCard(HistoricoPrecoModel historico) {
    final aumentou = historico.diferenca > 0;
    final color = aumentou ? Colors.red : Colors.green;
    final icon = aumentou ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          historico.produtoNome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'De: ${NumberFormat.currency(symbol: 'MT ', decimalDigits: 2).format(historico.precoAnterior)} → '
              'Para: ${NumberFormat.currency(symbol: 'MT ', decimalDigits: 2).format(historico.precoNovo)}',
            ),
            Text(
              '${historico.tipoAlteracao}: ${NumberFormat.currency(symbol: 'MT ', decimalDigits: 2).format(historico.diferenca.abs())} '
              '(${historico.percentualAlteracao.toStringAsFixed(1)}%)',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text('Por: ${historico.usuarioNome ?? 'Sistema'}'),
            Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(historico.dataOperacao)),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatoriosTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Relatórios Disponíveis',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRelatorioButton(
              'Operações Suspeitas',
              'Detecta atividades incomuns no sistema',
              Icons.warning,
              Colors.orange,
              _mostrarOperacoesSuspeitas,
            ),
            _buildRelatorioButton(
              'Produtos Deletados',
              'Lista produtos que foram excluídos',
              Icons.delete_forever,
              Colors.red,
              _mostrarProdutosDeletados,
            ),
            _buildRelatorioButton(
              'Usuários Mais Ativos',
              'Ranking de usuários por número de operações',
              Icons.leaderboard,
              Colors.blue,
              _mostrarUsuariosMaisAtivos,
            ),
            _buildRelatorioButton(
              'Exportar Auditoria',
              'Exportar dados de auditoria (em breve)',
              Icons.download,
              Colors.green,
              null, // TODO: Implementar exportação
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatorioButton(
    String titulo,
    String descricao,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  String _formatJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    json.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });
    return buffer.toString();
  }

  Future<void> _mostrarOperacoesSuspeitas() async {
    try {
      final suspeitas = await _repo.listarOperacoesSuspeitas();

      Get.dialog(
        AlertDialog(
          title: const Text('Operações Suspeitas'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: suspeitas.isEmpty
                ? const Center(child: Text('Nenhuma operação suspeita detectada'))
                : ListView.builder(
                    itemCount: suspeitas.length,
                    itemBuilder: (context, index) {
                      final op = suspeitas[index];
                      return ListTile(
                        leading: const Icon(Icons.warning, color: Colors.orange),
                        title: Text('${op['usuario_nome']} - ${op['tabela']}'),
                        subtitle: Text(
                          '${op['total']} operações em ${(op['duracao_minutos'] as num).toStringAsFixed(1)} minutos',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar operações suspeitas: $e');
    }
  }

  Future<void> _mostrarProdutosDeletados() async {
    try {
      final deletados = await _repo.listarProdutosDeletados();

      Get.dialog(
        AlertDialog(
          title: const Text('Produtos Deletados'),
          content: SizedBox(
            width: 600,
            height: 400,
            child: deletados.isEmpty
                ? const Center(child: Text('Nenhum produto deletado'))
                : ListView.builder(
                    itemCount: deletados.length,
                    itemBuilder: (context, index) {
                      final prod = deletados[index];
                      return ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: Text('${prod['codigo']} - ${prod['nome']}'),
                        subtitle: Text(
                          'Preço: ${NumberFormat.currency(symbol: 'MT ', decimalDigits: 2).format(prod['preco'])}\n'
                          'Deletado por: ${prod['usuario_nome']} em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(prod['data_delecao']))}',
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar produtos deletados: $e');
    }
  }

  Future<void> _mostrarUsuariosMaisAtivos() async {
    try {
      final usuarios = await _repo.obterUsuariosMaisAtivos();

      Get.dialog(
        AlertDialog(
          title: const Text('Usuários Mais Ativos (Últimos 7 dias)'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: usuarios.isEmpty
                ? const Center(child: Text('Nenhum dado disponível'))
                : ListView.builder(
                    itemCount: usuarios.length,
                    itemBuilder: (context, index) {
                      final user = usuarios[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(user['nome'] as String),
                        subtitle: Text(user['codigo'] as String),
                        trailing: Chip(
                          label: Text('${user['total_operacoes']} ops'),
                          backgroundColor: Colors.blue[100],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar usuários: $e');
    }
  }
}
