import 'package:flutter/material.dart';

class TecladoQwerty extends StatelessWidget {
  final Function(String) onLetraPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onEspaco;

  const TecladoQwerty({
    Key? key,
    required this.onLetraPressed,
    required this.onBackspace,
    required this.onClear,
    required this.onEspaco,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha 1: QWERTYUIOP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...'QWERTYUIOP'.split('').map((letra) => _buildTecla(letra)),
            ],
          ),
          SizedBox(height: 8),

          // Linha 2: ASDFGHJKL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...'ASDFGHJKL'.split('').map((letra) => _buildTecla(letra)),
            ],
          ),
          SizedBox(height: 8),

          // Linha 3: ZXCVBNM + Backspace
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...'ZXCVBNM'.split('').map((letra) => _buildTecla(letra)),
              SizedBox(width: 4),
              _buildTeclaEspecial(Icons.backspace, Colors.orange, onBackspace, 60),
            ],
          ),
          SizedBox(height: 8),

          // Linha 4: Espaço e Limpar
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: onEspaco,
                    child: Text('ESPAÇO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(18),
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: onClear,
                    icon: Icon(Icons.clear_all, size: 20),
                    label: Text('LIMPAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.all(18),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTecla(String letra) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: SizedBox(
        width: 50,  // Aumentado de 36 para 50
        height: 50,  // Aumentado de 40 para 50
        child: ElevatedButton(
          onPressed: () => onLetraPressed(letra),
          child: Text(
            letra,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),  // Aumentado de 16 para 20
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTeclaEspecial(IconData icon, Color cor, VoidCallback onPressed, double largura) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: SizedBox(
        width: largura,
        height: 50,  // Aumentado de 40 para 50
        child: ElevatedButton(
          onPressed: onPressed,
          child: Icon(icon, size: 24),  // Aumentado de 20 para 24
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: cor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
