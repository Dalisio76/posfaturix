import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/cliente_model.dart';
import 'teclado_qwerty.dart';

class DialogDividaRapida extends StatefulWidget {
  final List<ClienteModel> clientes;
  final double valorTotal;

  const DialogDividaRapida({
    Key? key,
    required this.clientes,
    required this.valorTotal,
  }) : super(key: key);

  @override
  State<DialogDividaRapida> createState() => _DialogDividaRapidaState();
}

class _DialogDividaRapidaState extends State<DialogDividaRapida> {
  final _pesquisaController = TextEditingController();
  List<ClienteModel> _clientesFiltrados = [];
  ClienteModel? _clienteSelecionado;

  @override
  void initState() {
    super.initState();
    _clientesFiltrados = widget.clientes;
  }

  void _filtrarClientes(String termo) {
    setState(() {
      if (termo.isEmpty) {
        _clientesFiltrados = widget.clientes;
      } else {
        _clientesFiltrados = widget.clientes
            .where((cliente) =>
                cliente.nome.toLowerCase().contains(termo.toLowerCase()) ||
                (cliente.contacto?.contains(termo) ?? false) ||
                (cliente.email?.toLowerCase().contains(termo.toLowerCase()) ??
                    false))
            .toList();
      }
    });
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
                color: Colors.red[700],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_card, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'REGISTRAR DÍVIDA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Selecione o cliente devedor',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VALOR TOTAL DA DÍVIDA:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'MT ${widget.valorTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Campo de pesquisa
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _pesquisaController,
                decoration: InputDecoration(
                  labelText: 'Pesquisar cliente',
                  hintText: 'Digite o nome, contacto ou email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _pesquisaController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _pesquisaController.clear();
                            _filtrarClientes('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrarClientes,
                readOnly: true,
              ),
            ),

            // Lista de clientes
            Expanded(
              child: _clientesFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum cliente encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = _clientesFiltrados[index];
                        final isSelected = _clienteSelecionado?.id == cliente.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.red[50],
                          leading: CircleAvatar(
                            backgroundColor:
                                isSelected ? Colors.red[700] : Colors.blue,
                            child: Text(
                              cliente.nome.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            cliente.nome,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cliente.contacto != null)
                                Text('Tel: ${cliente.contacto}'),
                              if (cliente.email != null)
                                Text('Email: ${cliente.email}'),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: Colors.red[700])
                              : null,
                          onTap: () {
                            setState(() {
                              _clienteSelecionado = cliente;
                            });
                          },
                        );
                      },
                    ),
            ),

            // Teclado Virtual
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: TecladoQwerty(
                onLetraPressed: (letra) {
                  _pesquisaController.text += letra;
                  _filtrarClientes(_pesquisaController.text);
                },
                onBackspace: () {
                  if (_pesquisaController.text.isNotEmpty) {
                    _pesquisaController.text = _pesquisaController.text
                        .substring(0, _pesquisaController.text.length - 1);
                    _filtrarClientes(_pesquisaController.text);
                  }
                },
                onClear: () {
                  _pesquisaController.clear();
                  _filtrarClientes('');
                },
                onEspaco: () {
                  _pesquisaController.text += ' ';
                  _filtrarClientes(_pesquisaController.text);
                },
              ),
            ),

            // Botão de ação
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _clienteSelecionado == null
                      ? null
                      : () {
                          Get.back(result: _clienteSelecionado);
                        },
                  icon: Icon(Icons.check_circle, size: 24),
                  label: Text(
                    'CONCLUIR DÍVIDA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.all(18),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }
}
