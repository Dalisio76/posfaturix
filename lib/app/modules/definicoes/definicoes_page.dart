import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/definicao_model.dart';
import '../../../core/services/definicoes_service.dart';

class DefinicoesPage extends StatefulWidget {
  @override
  State<DefinicoesPage> createState() => _DefinicoesPageState();
}

class _DefinicoesPageState extends State<DefinicoesPage> {
  DefinicaoModel? _definicoes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDefinicoes();
  }

  Future<void> _carregarDefinicoes() async {
    setState(() => _isLoading = true);
    try {
      final definicoes = await DefinicoesService.carregar();
      print('Definições carregadas: timeoutAtivo=${definicoes.timeoutAtivo}, timeoutSegundos=${definicoes.timeoutSegundos}, mostrarBotaoPedidos=${definicoes.mostrarBotaoPedidos}');
      setState(() {
        _definicoes = definicoes;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar definições: $e');
      setState(() => _isLoading = false);
      Get.snackbar('Erro', 'Erro ao carregar definições: $e');
    }
  }

  Future<void> _salvarDefinicoes(DefinicaoModel novasDefinicoes) async {
    try {
      print('Salvando definições: ${novasDefinicoes.toJson()}');
      await DefinicoesService.salvar(novasDefinicoes);
      setState(() => _definicoes = novasDefinicoes);
      Get.snackbar(
        'Sucesso',
        'Definições salvas com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('Erro ao salvar: $e');
      Get.snackbar(
        'Erro',
        'Erro ao salvar definições: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEFINIÇÕES'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _definicoes == null
              ? Center(child: Text('Erro ao carregar definições'))
              : ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // Seção: Impressão
                    _buildSecaoTitulo('IMPRESSÃO DE RECIBOS'),
                    SizedBox(height: 10),

                    // Opção: Perguntar antes de imprimir
                    Card(
                      child: SwitchListTile(
                        title: Text(
                          'Perguntar antes de imprimir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _definicoes!.perguntarAntesDeImprimir
                              ? 'Sistema perguntará se deseja imprimir após finalizar venda'
                              : 'Sistema imprimirá automaticamente após finalizar venda',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _definicoes!.perguntarAntesDeImprimir,
                        activeColor: Colors.blue,
                        onChanged: (valor) {
                          final novasDefinicoes = _definicoes!.copyWith(
                            perguntarAntesDeImprimir: valor,
                          );
                          _salvarDefinicoes(novasDefinicoes);
                        },
                      ),
                    ),

                    SizedBox(height: 30),

                    // Seção: Segurança
                    _buildSecaoTitulo('SEGURANÇA'),
                    SizedBox(height: 10),

                    // Opção: Timeout de inatividade
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: Text(
                              'Timeout de inatividade',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              _definicoes!.timeoutAtivo
                                  ? 'Sistema fará logout automático após inatividade'
                                  : 'Timeout de inatividade desativado',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: _definicoes!.timeoutAtivo,
                            activeColor: Colors.blue,
                            onChanged: (valor) {
                              final novasDefinicoes = _definicoes!.copyWith(
                                timeoutAtivo: valor,
                              );
                              _salvarDefinicoes(novasDefinicoes);
                            },
                          ),
                          if (_definicoes!.timeoutAtivo) ...[
                            Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Tempo de inatividade (segundos)',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      keyboardType: TextInputType.number,
                                      controller: TextEditingController(
                                        text: _definicoes!.timeoutSegundos.toString(),
                                      )..selection = TextSelection.collapsed(
                                          offset: _definicoes!.timeoutSegundos
                                              .toString()
                                              .length,
                                        ),
                                      onSubmitted: (valor) {
                                        final segundos = int.tryParse(valor) ?? 30;
                                        if (segundos < 10) {
                                          Get.snackbar(
                                            'Atenção',
                                            'O timeout mínimo é de 10 segundos',
                                            backgroundColor: Colors.orange,
                                            colorText: Colors.white,
                                          );
                                          return;
                                        }
                                        final novasDefinicoes = _definicoes!.copyWith(
                                          timeoutSegundos: segundos,
                                        );
                                        _salvarDefinicoes(novasDefinicoes);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 30),

                    // Seção: Vendas
                    _buildSecaoTitulo('VENDAS'),
                    SizedBox(height: 10),

                    // Opção: Botão de Pedidos/Mesas
                    Card(
                      child: SwitchListTile(
                        title: Text(
                          'Mostrar botão PEDIDOS/MESAS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _definicoes!.mostrarBotaoPedidos
                              ? 'Botão de pedidos e mesas visível na tela de vendas'
                              : 'Botão de pedidos/mesas oculto (modo supermercado)',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: _definicoes!.mostrarBotaoPedidos,
                        activeColor: Colors.blue,
                        onChanged: (valor) {
                          final novasDefinicoes = _definicoes!.copyWith(
                            mostrarBotaoPedidos: valor,
                          );
                          _salvarDefinicoes(novasDefinicoes);
                        },
                      ),
                    ),

                    SizedBox(height: 30),

                    // Botão de resetar
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmar = await Get.dialog<bool>(
                          AlertDialog(
                            title: Text('Resetar Definições'),
                            content: Text(
                              'Tem certeza que deseja resetar todas as definições para os valores padrão?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(result: false),
                                child: Text('CANCELAR'),
                              ),
                              ElevatedButton(
                                onPressed: () => Get.back(result: true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text('RESETAR'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar == true) {
                          await DefinicoesService.limpar();
                          // Salvar explicitamente as definições padrão
                          final definicoespadrao = DefinicaoModel();
                          await DefinicoesService.salvar(definicoespadrao);
                          await _carregarDefinicoes();
                          Get.snackbar(
                            'Sucesso',
                            'Definições resetadas para padrão',
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                        }
                      },
                      icon: Icon(Icons.restore, color: Colors.red),
                      label: Text(
                        'RESETAR PARA PADRÃO',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
