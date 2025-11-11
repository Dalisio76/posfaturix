import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/divida_model.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/repositories/divida_repository.dart';
import '../../../data/repositories/cliente_repository.dart';
import '../widgets/dialog_detalhes_divida.dart';

class TelaDevedores extends StatefulWidget {
  const TelaDevedores({Key? key}) : super(key: key);

  @override
  State<TelaDevedores> createState() => _TelaDevedoresState();
}

class _TelaDevedoresState extends State<TelaDevedores> {
  final _dividaRepo = DividaRepository();
  final _clienteRepo = ClienteRepository();

  List<DividaModel> dividas = [];
  List<ClienteModel> clientes = [];
  ClienteModel? clienteSelecionado;
  DateTime? dataFiltro;
  bool isLoading = true;
  String filtroStatus = 'TODAS'; // TODAS, PENDENTE, PARCIAL, PAGO

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      isLoading = true;
    });

    try {
      clientes = await _clienteRepo.listarTodos();
      await _aplicarFiltros();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dados: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _aplicarFiltros() async {
    try {
      List<DividaModel> todasDividas;

      if (clienteSelecionado != null) {
        // Filtrar por cliente
        todasDividas =
            await _dividaRepo.listarPorCliente(clienteSelecionado!.id!);
      } else {
        // Todas as dívidas
        todasDividas = await _dividaRepo.listarTodas();
      }

      // Filtrar por data
      if (dataFiltro != null) {
        todasDividas = todasDividas.where((d) {
          return DateFormat('yyyy-MM-dd').format(d.dataDivida) ==
              DateFormat('yyyy-MM-dd').format(dataFiltro!);
        }).toList();
      }

      // Filtrar por status
      if (filtroStatus != 'TODAS') {
        todasDividas = todasDividas.where((d) => d.status == filtroStatus).toList();
      }

      setState(() {
        dividas = todasDividas;
      });
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao aplicar filtros: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEVEDORES'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),
          Divider(height: 1),

          // Resumo
          _buildResumo(),
          Divider(height: 1),

          // Lista de dívidas
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : dividas.isEmpty
                    ? _buildVazio()
                    : _buildListaDividas(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FILTROS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Filtro por Cliente
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  value: clienteSelecionado?.id,
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Todos os clientes'),
                    ),
                    ...clientes.map((c) => DropdownMenuItem<int?>(
                          value: c.id,
                          child: Text(c.nome),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      clienteSelecionado =
                          clientes.firstWhereOrNull((c) => c.id == value);
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
              SizedBox(width: 12),

              // Filtro por Data
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final data = await showDatePicker(
                      context: context,
                      initialDate: dataFiltro ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (data != null) {
                      setState(() {
                        dataFiltro = data;
                      });
                      _aplicarFiltros();
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: dataFiltro != null
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  dataFiltro = null;
                                });
                                _aplicarFiltros();
                              },
                            )
                          : null,
                    ),
                    child: Text(
                      dataFiltro != null
                          ? DateFormat('dd/MM/yyyy').format(dataFiltro!)
                          : 'Todas as datas',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),

              // Filtro por Status
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filtroStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.filter_list),
                  ),
                  items: [
                    DropdownMenuItem(value: 'TODAS', child: Text('Todas')),
                    DropdownMenuItem(value: 'PENDENTE', child: Text('Pendente')),
                    DropdownMenuItem(value: 'PARCIAL', child: Text('Parcial')),
                    DropdownMenuItem(value: 'PAGO', child: Text('Pago')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filtroStatus = value!;
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumo() {
    final totalGeral = dividas.fold(0.0, (sum, d) => sum + d.valorTotal);
    final totalPago = dividas.fold(0.0, (sum, d) => sum + d.valorPago);
    final totalRestante = dividas.fold(0.0, (sum, d) => sum + d.valorRestante);

    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            child: _buildCardResumo(
              'TOTAL EM DÍVIDAS',
              Formatters.formatarMoeda(totalGeral),
              Icons.receipt_long,
              Colors.blue[700]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildCardResumo(
              'TOTAL PAGO',
              Formatters.formatarMoeda(totalPago),
              Icons.check_circle,
              Colors.green[700]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildCardResumo(
              'TOTAL RESTANTE',
              Formatters.formatarMoeda(totalRestante),
              Icons.pending,
              Colors.red[700]!,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildCardResumo(
              'Nº DE DÍVIDAS',
              '${dividas.length}',
              Icons.numbers,
              Colors.orange[700]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardResumo(
      String label, String valor, IconData icon, Color cor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cor, size: 24),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma dívida encontrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Ajuste os filtros ou adicione novas dívidas',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildListaDividas() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: dividas.length,
      itemBuilder: (context, index) {
        final divida = dividas[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _abrirDetalhes(divida),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _getCorStatus(divida.status),
                        child: Text(
                          '#${divida.id}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              divida.clienteNome ?? 'Cliente',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(divida.dataDivida),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCorStatus(divida.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          divida.status,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              Formatters.formatarMoeda(divida.valorTotal),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAGO',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              Formatters.formatarMoeda(divida.valorPago),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RESTANTE',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              Formatters.formatarMoeda(divida.valorRestante),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _abrirDetalhes(DividaModel divida) {
    Get.dialog(
      DialogDetalhesDivida(divida: divida),
    ).then((_) {
      // Recarregar após fechar o dialog
      _aplicarFiltros();
    });
  }

  Color _getCorStatus(String status) {
    switch (status) {
      case 'PAGO':
        return Colors.green[700]!;
      case 'PARCIAL':
        return Colors.orange[700]!;
      default:
        return Colors.red[700]!;
    }
  }
}
