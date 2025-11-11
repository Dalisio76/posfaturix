import 'package:flutter/material.dart';

class TecladoNumerico extends StatelessWidget {
  final Function(String) onNumeroPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const TecladoNumerico({
    Key? key,
    required this.onNumeroPressed,
    required this.onBackspace,
    required this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildTecla('7'),
              SizedBox(width: 8),
              _buildTecla('8'),
              SizedBox(width: 8),
              _buildTecla('9'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildTecla('4'),
              SizedBox(width: 8),
              _buildTecla('5'),
              SizedBox(width: 8),
              _buildTecla('6'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildTecla('1'),
              SizedBox(width: 8),
              _buildTecla('2'),
              SizedBox(width: 8),
              _buildTecla('3'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildTecla('.'),
              SizedBox(width: 8),
              _buildTecla('0'),
              SizedBox(width: 8),
              _buildTeclaEspecial(
                Icons.backspace,
                Colors.orange,
                onBackspace,
              ),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onClear,
              icon: Icon(Icons.clear_all),
              label: Text('LIMPAR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTecla(String numero) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => onNumeroPressed(numero),
        child: Text(
          numero,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(24),
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTeclaEspecial(IconData icon, Color cor, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Icon(icon, size: 24),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.all(24),
          backgroundColor: cor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
