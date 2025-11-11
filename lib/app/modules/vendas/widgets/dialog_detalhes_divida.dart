import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/divida_model.dart';
import '../../../data/models/item_venda_model.dart';
import '../../../data/models/pagamento_divida_model.dart';
import '../../../data/repositories/venda_repository.dart';
import '../../../data/repositories/pagamento_divida_repository.dart';
import '../../../data/repositories/divida_repository.dart';
import 'dialog_pagamento_divida.dart';

class DialogDetalhesDivida extends StatefulWidget {
  final DividaModel divida;

  const DialogDetalhesDivida({
    Key? key,
    required this.divida,
  }) : super(key: key);

  @override
  State<DialogDetalhesDivida> createState() => _DialogDetalhesDividaState();
}

class _DialogDetalhesDividaState extends State<DialogDetalhesDivida> {
  final _vendaRepo = VendaRepository();
  final _pagamentoRepo = PagamentoDividaRepository();
  final _dividaRepo = DividaRepository();

  List<ItemVendaModel> itens = [];
  List<PagamentoDividaModel> pagamentos = [];
  bool isLoading = true;
  late DividaModel dividaAtual;

  @override
  void initState() {
    super.initState();
    dividaAtual = widget.divida;
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Atualizar dados da dívida
      final dividaAtualizada = await _dividaRepo.buscarPorId(widget.divida.id!);
      if (dividaAtualizada != null) {
        dividaAtual = dividaAtualizada;
      }

      // Carregar itens se houver venda associada
      if (dividaAtual.vendaId != null) {
        itens = await _vendaRepo.buscarItensPorVenda(dividaAtual.vendaId!);
      }

      // Carregar pagamentos
      pagamentos = await _pagamentoRepo.listarPorDivida(dividaAtual.id!);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar detalhes: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        height: 650,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getCorStatus(),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DETALHES DA DÍVIDA #${dividaAtual.id}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              dividaAtual.clienteNome ?? 'Cliente',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dividaAtual.status,
                          style: TextStyle(
                            color: _getCorStatus(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'TOTAL',
                          Formatters.formatarMoeda(dividaAtual.valorTotal),
                          Icons.shopping_cart,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'PAGO',
                          Formatters.formatarMoeda(dividaAtual.valorPago),
                          Icons.check_circle,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard(
                          'RESTANTE',
                          Formatters.formatarMoeda(dividaAtual.valorRestante),
                          Icons.pending,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Data: ${DateFormat('dd/MM/yyyy').format(dividaAtual.dataDivida)}',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        if (dividaAtual.vendaNumero != null)
                          Text(
                            'Venda: ${dividaAtual.vendaNumero}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Abas
            DefaultTabController(
              length: 2,
              child: Expanded(
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Get.theme.primaryColor,
                      tabs: [
                        Tab(
                          icon: Icon(Icons.shopping_bag),
                          text: 'PRODUTOS (${itens.length})',
                        ),
                        Tab(
                          icon: Icon(Icons.payment),
                          text: 'PAGAMENTOS (${pagamentos.length})',
                        ),
                      ],
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [
                                _buildListaProdutos(),
                                _buildListaPagamentos(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close),
                      label: Text('FECHAR'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: dividaAtual.status == 'PAGO'
                          ? null
                          : _registrarPagamento,
                      icon: Icon(Icons.payment),
                      label: Text('REGISTRAR PAGAMENTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String valor, IconData icon) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: _getCorStatus()),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _getCorStatus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProdutos() {
    if (itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum produto encontrado',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: itens.length,
      itemBuilder: (context, index) {
        final item = itens[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Get.theme.primaryColor,
              child: Text(
                '${item.quantidade}x',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(
              item.produtoNome ?? 'Produto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${Formatters.formatarMoeda(item.precoUnitario)} cada',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatarMoeda(item.subtotal),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Get.theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaPagamentos() {
    if (pagamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum pagamento registrado',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: pagamentos.length,
      itemBuilder: (context, index) {
        final pagamento = pagamentos[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: Text(
              pagamento.formaPagamentoNome ?? 'Pagamento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(pagamento.dataPagamento),
            ),
            trailing: Text(
              Formatters.formatarMoeda(pagamento.valor),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCorStatus() {
    switch (dividaAtual.status) {
      case 'PAGO':
        return Colors.green[700]!;
      case 'PARCIAL':
        return Colors.orange[700]!;
      default:
        return Colors.red[700]!;
    }
  }

  Future<void> _registrarPagamento() async {
    final resultado = await Get.dialog<bool>(
      DialogPagamentoDivida(
        divida: dividaAtual,
        onPagamentoRealizado: _carregarDetalhes,
      ),
      barrierDismissible: false,
    );

    // Se o pagamento foi registrado com sucesso, recarregar os detalhes
    if (resultado == true) {
      await _carregarDetalhes();
    }
  }
}
