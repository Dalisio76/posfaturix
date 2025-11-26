import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/forma_pagamento_model.dart';
import '../../../data/models/pagamento_venda_model.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/repositories/cliente_repository.dart';
import 'teclado_numerico.dart';
import 'dialog_divida_rapida.dart';

class DialogPagamento extends StatefulWidget {
  final List<FormaPagamentoModel> formasPagamento;
  final double valorTotal;

  const DialogPagamento({
    Key? key,
    required this.formasPagamento,
    required this.valorTotal,
  }) : super(key: key);

  @override
  State<DialogPagamento> createState() => _DialogPagamentoState();
}

class _DialogPagamentoState extends State<DialogPagamento> {
  final RxString valorDigitado = '0'.obs;
  final RxList<PagamentoVendaModel> pagamentosAdicionados = <PagamentoVendaModel>[].obs;
  final _clienteRepo = ClienteRepository();
  final RxList<ClienteModel> clientes = <ClienteModel>[].obs;
  final Rxn<ClienteModel> clienteSelecionado = Rxn<ClienteModel>();
  final RxBool modoDivida = false.obs;
  final TextEditingController _valorController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _carregarClientes();

    // Sincronizar controller com valorDigitado
    _valorController.addListener(() {
      valorDigitado.value = _valorController.text.isEmpty ? '0' : _valorController.text;
    });
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _carregarClientes() async {
    try {
      clientes.value = await _clienteRepo.listarTodos();
    } catch (e) {
      print('Erro ao carregar clientes: $e');
    }
  }

  double get totalPago {
    return pagamentosAdicionados.fold(0, (sum, p) => sum + p.valor);
  }

  double get restante {
    return widget.valorTotal - totalPago;
  }

  double get troco {
    return totalPago > widget.valorTotal ? totalPago - widget.valorTotal : 0;
  }

  bool get pagamentoCompleto {
    // Se está em modo dívida, não precisa pagar tudo
    if (modoDivida.value && clienteSelecionado.value != null) {
      return true; // Pode finalizar mesmo sem pagar tudo
    }
    return totalPago >= widget.valorTotal;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKey: (node, event) {
        if (event is RawKeyDownEvent) {
          final key = event.logicalKey;

          // F1-F8 para selecionar formas de pagamento
          if (widget.formasPagamento.isNotEmpty) {
            if (key == LogicalKeyboardKey.f1 && widget.formasPagamento.length >= 1) {
              _adicionarPagamento(widget.formasPagamento[0]);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.f2 && widget.formasPagamento.length >= 2) {
              _adicionarPagamento(widget.formasPagamento[1]);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.f3 && widget.formasPagamento.length >= 3) {
              _adicionarPagamento(widget.formasPagamento[2]);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.f4 && widget.formasPagamento.length >= 4) {
              _adicionarPagamento(widget.formasPagamento[3]);
              return KeyEventResult.handled;
            }
          }

          // F9 - Finalizar pagamento
          if (key == LogicalKeyboardKey.f9 && pagamentoCompleto) {
            _finalizarPagamento();
            return KeyEventResult.handled;
          }

          // ESC - Fechar dialog
          if (key == LogicalKeyboardKey.escape) {
            Get.back();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Dialog(
        child: Container(
        width: 900,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho compacto
            Row(
              children: [
                Icon(Icons.payment, size: 22, color: Get.theme.primaryColor),
                SizedBox(width: 8),
                Text('PAGAMENTO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, size: 20),
                  onPressed: () => Get.back(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Divider(height: 16),

            // Conteúdo principal em Row
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // COLUNA ESQUERDA: Formas de pagamento
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Resumo de valores
                        _buildResumoValores(),
                        SizedBox(height: 12),

                        // Lista de pagamentos adicionados
                        Obx(() => pagamentosAdicionados.isNotEmpty
                            ? _buildListaPagamentos()
                            : Container()),

                        SizedBox(height: 12),

                        Text(
                          'FORMAS DE PAGAMENTO',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),

                        // Grid de formas
                        Expanded(child: _buildGridFormasPagamento()),

                        SizedBox(height: 8),

                        // Botão DÍVIDAS
                        Obx(() => ElevatedButton.icon(
                              onPressed: _selecionarCliente,
                              icon: Icon(
                                modoDivida.value ? Icons.credit_card : Icons.person_add,
                                size: 18,
                              ),
                              label: Text(
                                modoDivida.value && clienteSelecionado.value != null
                                    ? 'CLIENTE: ${clienteSelecionado.value!.nome.split(' ').first.toUpperCase()}'
                                    : 'DÍVIDAS',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: modoDivida.value
                                    ? Colors.red[700]
                                    : Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.all(12),
                              ),
                            )),
                      ],
                    ),
                  ),

                  SizedBox(width: 16),

                  // COLUNA DIREITA: Valor e Teclado
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('VALOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        _buildCampoValor(),
                        SizedBox(height: 12),

                        // Teclado numérico expandido
                        Expanded(
                          child: TecladoNumerico(
                            onNumeroPressed: _adicionarDigito,
                            onBackspace: _removerUltimoDigito,
                            onClear: _limparValor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Botão finalizar
            Obx(() => ElevatedButton.icon(
              onPressed: pagamentoCompleto ? _finalizarPagamento : null,
              icon: Icon(Icons.check_circle, size: 20),
              label: Text('FINALIZAR PAGAMENTO (F9)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
                disabledBackgroundColor: Colors.grey,
              ),
            )),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildResumoValores() {
    return Obx(() => Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: modoDivida.value ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: modoDivida.value ? Colors.red[200]! : Colors.blue[200]!),
      ),
      child: Column(
        children: [
          if (modoDivida.value && clienteSelecionado.value != null)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'VENDA A CRÉDITO - ${clienteSelecionado.value!.nome}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(
                'MT ${widget.valorTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: modoDivida.value ? Colors.red[900] : Colors.blue[900]),
              ),
            ],
          ),
          if (totalPago > 0) ...[
            Divider(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pago:', style: TextStyle(fontSize: 10)),
                Text('MT ${totalPago.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, color: Colors.green[700])),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Restante:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(
                  'MT ${restante.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: restante > 0 ? Colors.red[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
            if (troco > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TROCO:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[700])),
                  Text(
                    'MT ${troco.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                  ),
                ],
              ),
          ],
        ],
      ),
    ));
  }

  Widget _buildListaPagamentos() {
    return Container(
      constraints: BoxConstraints(maxHeight: 100),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('PAGAMENTOS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: pagamentosAdicionados.map((pagamento) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(_getIconeFormaPagamento(pagamento.formaPagamentoNome ?? ''), size: 14, color: Get.theme.primaryColor),
                    SizedBox(width: 4),
                    Text(pagamento.formaPagamentoNome ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('MT ${pagamento.valor.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    InkWell(
                      onTap: () => _removerPagamento(pagamento),
                      child: Icon(Icons.delete, color: Colors.red, size: 16),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoValor() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _valorController,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          prefix: Text('MT ', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildGridFormasPagamento() {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.5,
      ),
      itemCount: widget.formasPagamento.length,
      itemBuilder: (context, index) {
        final forma = widget.formasPagamento[index];
        return _buildBotaoFormaPagamento(forma, index);
      },
    );
  }

  Widget _buildBotaoFormaPagamento(FormaPagamentoModel forma, int index) {
    final atalho = index < 4 ? ' (F${index + 1})' : '';

    return ElevatedButton(
      onPressed: () => _adicionarPagamento(forma),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        side: BorderSide(color: Get.theme.primaryColor, width: 2),
        padding: EdgeInsets.all(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getIconeFormaPagamento(forma.nome), size: 20, color: Get.theme.primaryColor),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              '${forma.nome}$atalho',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconeFormaPagamento(String nome) {
    switch (nome.toUpperCase()) {
      case 'CASH': return Icons.money;
      case 'EMOLA': return Icons.phone_android;
      case 'MPESA': return Icons.phone_iphone;
      case 'POS': return Icons.credit_card;
      default: return Icons.payment;
    }
  }

  void _adicionarDigito(String digito) {
    if (digito == '.' && _valorController.text.contains('.')) return;
    if (_valorController.text == '0' && digito != '.') {
      _valorController.text = digito;
    } else {
      _valorController.text += digito;
    }
  }

  void _removerUltimoDigito() {
    if (_valorController.text.length > 1) {
      _valorController.text = _valorController.text.substring(0, _valorController.text.length - 1);
    } else {
      _valorController.text = '0';
    }
  }

  void _limparValor() {
    _valorController.text = '0';
  }

  String _formatarValor(String valor) {
    double val = double.tryParse(valor) ?? 0;
    return val.toStringAsFixed(2);
  }

  void _adicionarPagamento(FormaPagamentoModel forma) {
    double valor = double.tryParse(valorDigitado.value) ?? 0;

    if (valor <= 0) {
      Get.snackbar('Erro', 'Digite um valor maior que zero', duration: Duration(seconds: 2));
      return;
    }

    pagamentosAdicionados.add(PagamentoVendaModel(
      vendaId: 0,
      formaPagamentoId: forma.id!,
      valor: valor,
      formaPagamentoNome: forma.nome,
    ));

    _limparValor();
  }

  void _removerPagamento(PagamentoVendaModel pagamento) {
    pagamentosAdicionados.remove(pagamento);
  }

  void _selecionarCliente() async {
    // Abrir dialog simplificado de dívida
    final cliente = await Get.dialog<ClienteModel>(
      DialogDividaRapida(
        clientes: clientes,
        valorTotal: widget.valorTotal,
      ),
      barrierDismissible: false,
    );

    if (cliente != null) {
      // Cliente selecionado, finalizar como dívida
      final resultado = {
        'pagamentos': pagamentosAdicionados,
        'modoDivida': true,
        'cliente': cliente,
        'valorRestante': widget.valorTotal - totalPago,
      };
      Get.back(result: resultado);
    }
  }

  void _finalizarPagamento() {
    // Retornar pagamentos E informações sobre dívida
    final resultado = {
      'pagamentos': pagamentosAdicionados,
      'modoDivida': modoDivida.value,
      'cliente': clienteSelecionado.value,
      'valorRestante': restante,
    };
    Get.back(result: resultado);
  }
}
