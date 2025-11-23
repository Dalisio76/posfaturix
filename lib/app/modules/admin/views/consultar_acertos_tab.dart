import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/repositories/setor_repository.dart';
import '../../../data/repositories/acerto_stock_repository.dart';
import '../../../data/models/setor_model.dart';
import '../../../data/models/acerto_stock_model.dart';

class ConsultarAcertosTab extends StatefulWidget {
  const ConsultarAcertosTab({Key? key}) : super(key: key);

  @override
  _ConsultarAcertosTabState createState() => _ConsultarAcertosTabState();
}

class _ConsultarAcertosTabState extends State<ConsultarAcertosTab> {
  final SetorRepository _setorRepo = Get.find<SetorRepository>();
  final AcertoStockRepository _acertoRepo = Get.put(AcertoStockRepository());

  final RxList<SetorModel> setores = <SetorModel>[].obs;
  final Rxn<SetorModel> setorSelecionado = Rxn<SetorModel>();

  final TextEditingController produtoController = TextEditingController();

  // Datas de calendário
  final Rxn<DateTime> dataInicio = Rxn<DateTime>(DateTime.now().subtract(const Duration(days: 30)));
  final Rxn<DateTime> dataFim = Rxn<DateTime>(DateTime.now());

  // Lista de acertos
  final RxList<AcertoStockModel> acertos = <AcertoStockModel>[].obs;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      setores.value = await _setorRepo.listarTodos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    }
  }

  Future<void> consultar() async {
    try {
      // Ajustar datas para incluir o dia inteiro
      final inicio = DateTime(
        dataInicio.value!.year,
        dataInicio.value!.month,
        dataInicio.value!.day,
        0, 0, 0,
      );
      final fim = DateTime(
        dataFim.value!.year,
        dataFim.value!.month,
        dataFim.value!.day,
        23, 59, 59,
      );

      print('Consultando acertos de $inicio até $fim');

      // Buscar acertos do banco de dados
      final resultado = await _acertoRepo.buscarPorPeriodo(
        dataInicio: inicio,
        dataFim: fim,
        produtoNome: produtoController.text.isNotEmpty ? produtoController.text : null,
        setorId: setorSelecionado.value?.id,
      );

      print('Encontrados ${resultado.length} acertos');

      acertos.value = resultado;

      Get.snackbar(
        'Sucesso',
        'Consulta realizada. ${acertos.length} itens encontrados',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e, stackTrace) {
      print('Erro ao consultar acertos: $e');
      print('StackTrace: $stackTrace');
      Get.snackbar(
        'Erro',
        'Erro ao consultar acertos: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> selecionarData(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio
          ? (dataInicio.value ?? DateTime.now())
          : (dataFim.value ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      if (isInicio) {
        dataInicio.value = picked;
      } else {
        dataFim.value = picked;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONSULTAR ACERTOS DE STOCK'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          _buildFiltros(context),
          Expanded(
            child: Obx(() => acertos.isEmpty
                ? const Center(child: Text('Nenhum acerto encontrado. Use CONSULTAR para pesquisar.'))
                : _buildTabela()),
          ),
          _buildRodape(),
        ],
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              // Data PESQUISAR DE
              const Text('PESQUISAR DE', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Obx(() => InkWell(
                      onTap: () => selecionarData(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy', 'en_US').format(dataInicio.value ?? DateTime.now()),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )),
              ),
              const SizedBox(width: 32),

              // Data ATÉ
              const Text('ATÉ', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Obx(() => InkWell(
                      onTap: () => selecionarData(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: Text(
                          DateFormat('EEEE, MMMM d, yyyy', 'en_US').format(dataFim.value ?? DateTime.now()),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Campo PRODUTO
              const Text('PRODUTO', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: produtoController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 32),

              // Dropdown SECTOR
              const Text('SECTOR', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Obx(() => DropdownButtonFormField<SetorModel>(
                      value: setorSelecionado.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: setores
                          .map((setor) => DropdownMenuItem(
                                value: setor,
                                child: Text(setor.nome),
                              ))
                          .toList(),
                      onChanged: (value) => setorSelecionado.value = value,
                    )),
              ),
              const SizedBox(width: 32),

              // Botão CONSULTAR
              ElevatedButton(
                onPressed: consultar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
                child: const Text('CONSULTAR', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    return Column(
      children: [
        // Cabeçalho
        Container(
          color: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              _buildCabecalho('AREA', flex: 1),
              _buildCabecalho('TIPO', flex: 2),
              _buildCabecalho('COD.', flex: 1),
              _buildCabecalho('DESIGNACAO', flex: 3),
              _buildCabecalho('Q.INI', flex: 1),
              _buildCabecalho('Q.REAL', flex: 1),
              _buildCabecalho('JUSTIFICACAO', flex: 2),
              _buildCabecalho('DATA', flex: 2),
              _buildCabecalho('REGISTO/ACTUALIZACAO', flex: 2),
              _buildCabecalho('USUARIO', flex: 1),
            ],
          ),
        ),
        // Linhas
        Expanded(
          child: ListView.builder(
            itemCount: acertos.length,
            itemBuilder: (context, index) {
              final acerto = acertos[index];
              return _buildLinha(acerto, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho(String texto, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLinha(AcertoStockModel acerto, int index) {
    final corFundo = index % 2 == 0 ? Colors.yellow[100]! : Colors.white;

    // Formatar data
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(acerto.data);
    final registoFormatada = acerto.createdAt != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(acerto.createdAt!)
        : '-';

    return Container(
      color: corFundo,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          _buildCelula(acerto.areaNome ?? '-', flex: 1),
          _buildCelula(acerto.familiaNome ?? '-', flex: 2),
          _buildCelula(acerto.produtoCodigo ?? '-', flex: 1),
          _buildCelula(acerto.produtoNome ?? '-', flex: 3, align: TextAlign.left),
          _buildCelula(acerto.estoqueAnterior.toString(), flex: 1),
          _buildCelula(acerto.estoqueNovo.toString(), flex: 1),
          _buildCelula(acerto.motivo, flex: 2),
          _buildCelula(dataFormatada, flex: 2),
          _buildCelula(registoFormatada, flex: 2),
          _buildCelula(acerto.usuario ?? '-', flex: 1),
        ],
      ),
    );
  }

  Widget _buildCelula(String texto, {int flex = 1, TextAlign align = TextAlign.center}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          texto,
          style: const TextStyle(fontSize: 10),
          textAlign: align,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildRodape() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[400]!, width: 2)),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar impressão
              Get.snackbar('Info', 'Funcionalidade em desenvolvimento');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            child: const Text('IMPRIMIR'),
          ),
          const SizedBox(width: 32),
          Obx(() => Text(
                'Nº DE ITENS: ${acertos.length}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              )),
          const SizedBox(width: 32),
          Obx(() {
            // Calcular diferença de valor a partir dos acertos
            final diferenca = acertos.fold<double>(
              0.0,
              (sum, acerto) => sum + (acerto.valorDiferenca ?? 0.0),
            );
            return Text(
              'DIFERENÇA (VALOR): ${NumberFormat('#,##0.00').format(diferenca)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            );
          }),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            ),
            child: const Text('VOLTAR', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    produtoController.dispose();
    super.dispose();
  }
}
