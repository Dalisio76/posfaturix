import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/models/caixa_model.dart';

/// Dialog para conferência manual dos valores ao fechar o caixa
/// Permite que o operador digite manualmente os valores contados usando teclado numérico
class DialogConferenciaManual extends StatefulWidget {
  final CaixaModel caixa;

  const DialogConferenciaManual({
    Key? key,
    required this.caixa,
  }) : super(key: key);

  @override
  State<DialogConferenciaManual> createState() => _DialogConferenciaManualState();
}

class _DialogConferenciaManualState extends State<DialogConferenciaManual> {
  // Controllers para os text fields
  final Map<String, TextEditingController> _controllersEmCaixa = {
    'CASH': TextEditingController(),
    'EMOLA': TextEditingController(),
    'MPESA': TextEditingController(),
    'POS': TextEditingController(),
  };

  final Map<String, TextEditingController> _controllersGorjeta = {
    'CASH': TextEditingController(),
    'EMOLA': TextEditingController(),
    'MPESA': TextEditingController(),
    'POS': TextEditingController(),
  };

  // Campo focado atualmente
  TextEditingController? _controllerFocado;
  FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controllersEmCaixa.values.forEach((c) => c.dispose());
    _controllersGorjeta.values.forEach((c) => c.dispose());
    _focusNode.dispose();
    super.dispose();
  }

  /// Processa tecla do teclado numérico
  void _processTecla(String tecla) {
    if (_controllerFocado == null) return;

    final text = _controllerFocado!.text;

    if (tecla == 'C') {
      // Limpar
      _controllerFocado!.text = '';
    } else if (tecla == '.') {
      // Adicionar ponto decimal se ainda não tiver
      if (!text.contains('.')) {
        _controllerFocado!.text = text + '.';
      }
    } else {
      // Número
      _controllerFocado!.text = text + tecla;
    }
  }

  /// Confirma e retorna os valores
  void _confirmar() {
    final resultado = {
      'conferido': true,
      'observacoes': null,
      'valores': {
        'cash': {
          'digitado': double.tryParse(_controllersEmCaixa['CASH']!.text) ?? 0.0,
          'sistema': widget.caixa.totalCash
        },
        'emola': {
          'digitado': double.tryParse(_controllersEmCaixa['EMOLA']!.text) ?? 0.0,
          'sistema': widget.caixa.totalEmola
        },
        'mpesa': {
          'digitado': double.tryParse(_controllersEmCaixa['MPESA']!.text) ?? 0.0,
          'sistema': widget.caixa.totalMpesa
        },
        'pos': {
          'digitado': double.tryParse(_controllersEmCaixa['POS']!.text) ?? 0.0,
          'sistema': widget.caixa.totalPos
        },
      },
    };

    Get.back(result: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[800],
              child: Row(
                children: [
                  // Botão voltar
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Get.back(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'FECHO CAIXA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Datas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDataInfo('INICIO', widget.caixa.dataAbertura),
                            _buildDataInfo('FIM', DateTime.now()),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 40), // Espaço para balancear o botão voltar
                ],
              ),
            ),

            // Conteúdo principal
            Expanded(
              child: Row(
                children: [
                  // Lado esquerdo: Tabela de valores
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Tabela
                          Expanded(
                            child: _buildTabela(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lado direito: Teclado numérico
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.grey[200],
                      child: Column(
                        children: [
                          // Teclado
                          Expanded(
                            child: _buildTeclado(),
                          ),

                          SizedBox(height: 10),

                          // Botão OK
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _confirmar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'OK',
                                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildDataInfo(String label, DateTime data) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            DateFormat('MM/dd/yyyy HH:mm:ss').format(data),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela() {
    final formas = ['CASH', 'EMOLA', 'MPESA', 'POS'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 1, child: Text('FORMA', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('EM CAIXA', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Linhas
          ...formas.map((forma) => _buildLinhaForma(forma)).toList(),
        ],
      ),
    );
  }

  Widget _buildLinhaForma(String forma) {
    final controllerEmCaixa = _controllersEmCaixa[forma]!;
    final isFocadoEmCaixa = _controllerFocado == controllerEmCaixa;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              forma,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _controllerFocado = controllerEmCaixa;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isFocadoEmCaixa ? Colors.blue : Colors.grey,
                    width: isFocadoEmCaixa ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: isFocadoEmCaixa ? Colors.blue[50] : Colors.white,
                ),
                child: TextField(
                  controller: controllerEmCaixa,
                  readOnly: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTap: () {
                    setState(() {
                      _controllerFocado = controllerEmCaixa;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeclado() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        _buildTecla('7'),
        _buildTecla('8'),
        _buildTecla('9'),
        _buildTecla('4'),
        _buildTecla('5'),
        _buildTecla('6'),
        _buildTecla('1'),
        _buildTecla('2'),
        _buildTecla('3'),
        _buildTecla('C', cor: Colors.orange),
        _buildTecla('0'),
        _buildTecla('.'),
      ],
    );
  }

  Widget _buildTecla(String tecla, {Color? cor}) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _processTecla(tecla);
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: cor ?? Colors.red[700],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Text(
        tecla,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
