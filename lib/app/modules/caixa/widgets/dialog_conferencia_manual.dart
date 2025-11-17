import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../data/models/caixa_model.dart';

/// Dialog para conferência manual dos valores ao fechar o caixa
/// Permite que o operador digite manualmente os valores contados
/// e compara com os valores do sistema
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
  // Controllers para os campos de entrada
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _emolaController = TextEditingController();
  final TextEditingController _mpesaController = TextEditingController();
  final TextEditingController _posController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  // Valores digitados (convertidos)
  double _cashDigitado = 0.0;
  double _emolaDigitado = 0.0;
  double _mpesaDigitado = 0.0;
  double _posDigitado = 0.0;

  // Estado de conferência
  bool _conferido = false;

  @override
  void dispose() {
    _cashController.dispose();
    _emolaController.dispose();
    _mpesaController.dispose();
    _posController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Verifica se a forma de pagamento foi usada
  bool _formaUsada(String forma) {
    switch (forma) {
      case 'CASH':
        return widget.caixa.totalCash > 0;
      case 'EMOLA':
        return widget.caixa.totalEmola > 0;
      case 'MPESA':
        return widget.caixa.totalMpesa > 0;
      case 'POS':
        return widget.caixa.totalPos > 0;
      default:
        return false;
    }
  }

  /// Calcula a diferença entre valor digitado e sistema
  double _calcularDiferenca(String forma) {
    double digitado = 0.0;
    double sistema = 0.0;

    switch (forma) {
      case 'CASH':
        digitado = _cashDigitado;
        sistema = widget.caixa.totalCash;
        break;
      case 'EMOLA':
        digitado = _emolaDigitado;
        sistema = widget.caixa.totalEmola;
        break;
      case 'MPESA':
        digitado = _mpesaDigitado;
        sistema = widget.caixa.totalMpesa;
        break;
      case 'POS':
        digitado = _posDigitado;
        sistema = widget.caixa.totalPos;
        break;
    }

    return digitado - sistema;
  }

  /// Valida se todos os campos obrigatórios foram preenchidos
  bool _validarCampos() {
    if (_formaUsada('CASH') && _cashController.text.isEmpty) return false;
    if (_formaUsada('EMOLA') && _emolaController.text.isEmpty) return false;
    if (_formaUsada('MPESA') && _mpesaController.text.isEmpty) return false;
    if (_formaUsada('POS') && _posController.text.isEmpty) return false;
    return true;
  }

  /// Realiza a conferência e mostra o resumo
  void _conferir() {
    if (!_validarCampos()) {
      Get.snackbar(
        'Atenção',
        'Preencha todos os campos das formas de pagamento utilizadas.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _cashDigitado = double.tryParse(_cashController.text) ?? 0.0;
      _emolaDigitado = double.tryParse(_emolaController.text) ?? 0.0;
      _mpesaDigitado = double.tryParse(_mpesaController.text) ?? 0.0;
      _posDigitado = double.tryParse(_posController.text) ?? 0.0;
      _conferido = true;
    });
  }

  /// Confirma o fechamento e retorna os dados
  void _confirmarFechamento() {
    if (!_conferido) {
      Get.snackbar(
        'Atenção',
        'Realize a conferência antes de confirmar.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Retornar dados da conferência
    final resultado = {
      'conferido': true,
      'observacoes': _observacoesController.text.trim(),
      'valores': {
        'cash': {'digitado': _cashDigitado, 'sistema': widget.caixa.totalCash},
        'emola': {'digitado': _emolaDigitado, 'sistema': widget.caixa.totalEmola},
        'mpesa': {'digitado': _mpesaDigitado, 'sistema': widget.caixa.totalMpesa},
        'pos': {'digitado': _posDigitado, 'sistema': widget.caixa.totalPos},
      },
    };

    Get.back(result: resultado);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue,
              child: Row(
                children: [
                  Icon(Icons.calculate, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Conferência Manual de Valores',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instruções
                    if (!_conferido)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Digite os valores contados manualmente para cada forma de pagamento utilizada.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),

                    // Campos de entrada (se não conferido)
                    if (!_conferido) ...[
                      _buildCampoValor('CASH', _cashController),
                      _buildCampoValor('E-MOLA', _emolaController),
                      _buildCampoValor('M-PESA', _mpesaController),
                      _buildCampoValor('POS/CARTÃO', _posController),
                      SizedBox(height: 20),
                    ],

                    // Tabela de comparação (se conferido)
                    if (_conferido) ...[
                      Text(
                        'RESULTADO DA CONFERÊNCIA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildTabelaComparacao(),
                      SizedBox(height: 20),
                    ],

                    // Campo de observações
                    TextField(
                      controller: _observacoesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observações (opcional)',
                        hintText: 'Adicione observações sobre o fechamento...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botões
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text('CANCELAR'),
                  ),
                  SizedBox(width: 10),
                  if (!_conferido)
                    ElevatedButton.icon(
                      onPressed: _conferir,
                      icon: Icon(Icons.calculate),
                      label: Text('CONFERIR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _confirmarFechamento,
                      icon: Icon(Icons.check),
                      label: Text('CONFIRMAR FECHAMENTO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
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

  /// Constrói campo de entrada de valor
  Widget _buildCampoValor(String label, TextEditingController controller) {
    // Normalizar label para comparação: remover hífens, barras e espaços
    final labelNormalizado = label.replaceAll('-', '').replaceAll('/', '').replaceAll(' ', '').toUpperCase();

    if (!_formaUsada(labelNormalizado)) {
      return SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        decoration: InputDecoration(
          labelText: '$label (MT)',
          hintText: '0.00',
          prefixIcon: Icon(Icons.money),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  /// Constrói tabela de comparação
  Widget _buildTabelaComparacao() {
    final formas = ['CASH', 'EMOLA', 'MPESA', 'POS'];
    final formasUsadas = formas.where((f) => _formaUsada(f)).toList();

    double totalDigitado = 0.0;
    double totalSistema = 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('Forma', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Contado', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Sistema', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Diferença', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Divider(height: 1),

          // Linhas de dados
          ...formasUsadas.map((forma) {
            double digitado = 0.0;
            double sistema = 0.0;

            switch (forma) {
              case 'CASH':
                digitado = _cashDigitado;
                sistema = widget.caixa.totalCash;
                break;
              case 'EMOLA':
                digitado = _emolaDigitado;
                sistema = widget.caixa.totalEmola;
                break;
              case 'MPESA':
                digitado = _mpesaDigitado;
                sistema = widget.caixa.totalMpesa;
                break;
              case 'POS':
                digitado = _posDigitado;
                sistema = widget.caixa.totalPos;
                break;
            }

            totalDigitado += digitado;
            totalSistema += sistema;

            final diferenca = digitado - sistema;
            final diferencaColor = diferenca == 0
                ? Colors.green
                : (diferenca > 0 ? Colors.blue : Colors.red);

            return Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(forma, style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${digitado.toStringAsFixed(2)} MT'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('${sistema.toStringAsFixed(2)} MT'),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          '${diferenca.toStringAsFixed(2)} MT',
                          style: TextStyle(
                            color: diferencaColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          diferenca == 0
                              ? Icons.check_circle
                              : Icons.warning,
                          color: diferencaColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          // Totais
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${totalDigitado.toStringAsFixed(2)} MT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${totalSistema.toStringAsFixed(2)} MT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${(totalDigitado - totalSistema).toStringAsFixed(2)} MT',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: (totalDigitado - totalSistema) == 0
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
