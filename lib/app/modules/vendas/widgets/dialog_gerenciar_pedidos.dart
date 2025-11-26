import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../data/models/mesa_model.dart';
import '../../../data/models/local_mesa_model.dart';
import '../../../data/models/pedido_model.dart';
import '../../../data/models/item_pedido_model.dart';
import '../../../data/repositories/mesa_repository.dart';
import '../../../data/repositories/local_mesa_repository.dart';
import '../../../data/repositories/pedido_repository.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/database/database_service.dart';
import '../../../../core/utils/formatters.dart';

class DialogGerenciarPedidos extends StatefulWidget {
  const DialogGerenciarPedidos({Key? key}) : super(key: key);

  @override
  State<DialogGerenciarPedidos> createState() => _DialogGerenciarPedidosState();
}

class _DialogGerenciarPedidosState extends State<DialogGerenciarPedidos> {
  final _mesaRepo = MesaRepository();
  final _localRepo = LocalMesaRepository();
  final _pedidoRepo = PedidoRepository();
  final _authService = Get.find<AuthService>();
  final _db = Get.find<DatabaseService>();

  final RxList<LocalMesaModel> locais = <LocalMesaModel>[].obs;
  final RxList<MesaModel> mesas = <MesaModel>[].obs;
  final RxList<MesaModel> mesasFiltradas = <MesaModel>[].obs;
  final Rxn<LocalMesaModel> localSelecionado = Rxn<LocalMesaModel>();
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      isLoading.value = true;

      locais.value = await _localRepo.listarTodos();

      final isAdmin = await _authService.temPermissao('gestao_mesas');
      final usuarioId = _authService.usuarioLogado.value?.id ?? 0;

      mesas.value = await _mesaRepo.listarPorUsuario(usuarioId, isAdmin);

      if (locais.isNotEmpty) {
        _selecionarLocal(locais.first);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar mesas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _selecionarLocal(LocalMesaModel local) {
    localSelecionado.value = local;
    mesasFiltradas.value = mesas.where((m) => m.localId == local.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.receipt_long, size: 28, color: Get.theme.primaryColor),
                SizedBox(width: 12),
                Text(
                  'GERENCIAR PEDIDOS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Obx(() => localSelecionado.value != null
                    ? Text(
                        'Local: ${localSelecionado.value!.nome}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Get.theme.primaryColor,
                        ),
                      )
                    : Container()),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.refresh, size: 24),
                  onPressed: _carregarDados,
                  tooltip: 'Atualizar',
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(height: 24),

            // Botões de Ação
            Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _iniciarUnirContas,
                      icon: Icon(Icons.call_merge, size: 20),
                      label: Text('UNIR CONTAS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _iniciarDividirConta,
                      icon: Icon(Icons.call_split, size: 20),
                      label: Text('DIVIDIR CONTA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Grid de mesas
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }

                if (locais.isEmpty) {
                  return Center(child: Text('Nenhum local cadastrado'));
                }

                return _buildGridMesas();
              }),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMesas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coluna dos locais
        Container(
          width: 160,
          child: Obx(() => Column(
            children: locais.map((local) {
              final mesasDoLocal = mesas.where((m) => m.localId == local.id).length;
              final mesasOcupadas = mesas
                  .where((m) => m.localId == local.id && m.isOcupada)
                  .length;
              final isSelected = localSelecionado.value?.id == local.id;

              return InkWell(
                onTap: () => _selecionarLocal(local),
                child: Container(
                  height: 80,
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Get.theme.primaryColor : Colors.black,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        local.nome,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$mesasOcupadas/$mesasDoLocal ocupadas',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          )),
        ),

        SizedBox(width: 16),

        // Grid das mesas
        Expanded(
          child: Obx(() => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: mesasFiltradas.length,
            itemBuilder: (context, index) {
              final mesa = mesasFiltradas[index];
              return _buildCardMesa(mesa);
            },
          )),
        ),
      ],
    );
  }

  Widget _buildCardMesa(MesaModel mesa) {
    Color corFundo;
    Color corTexto;

    if (mesa.isLivre) {
      corFundo = Colors.blue[900]!;
      corTexto = Colors.white;
    } else if (mesa.isOcupada) {
      corFundo = Colors.amber[600]!;
      corTexto = Colors.black;
    } else {
      corFundo = Colors.grey[400]!;
      corTexto = Colors.black54;
    }

    return InkWell(
      onTap: mesa.isOcupada ? () => _abrirDetalhesPedido(mesa) : null,
      child: Container(
        decoration: BoxDecoration(
          color: corFundo,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${mesa.numero}',
              style: TextStyle(
                color: corTexto,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mesa.isOcupada) ...[
              SizedBox(height: 2),
              Text(
                '${mesa.pedidoTotal?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  color: corTexto,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                (mesa.usuarioNome ?? '').split(' ').first.toUpperCase(),
                style: TextStyle(
                  color: corTexto,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Classe auxiliar para agrupar itens
  Map<String, Map<String, dynamic>> _agruparItens(List<ItemPedidoModel> itens) {
    final Map<String, Map<String, dynamic>> agrupados = {};

    for (final item in itens) {
      final key = '${item.produtoId}_${item.precoUnitario}';

      if (agrupados.containsKey(key)) {
        agrupados[key]!['quantidade'] += item.quantidade;
        agrupados[key]!['subtotal'] += item.subtotal;
        agrupados[key]!['itens'].add(item);
      } else {
        agrupados[key] = {
          'produto_id': item.produtoId,
          'produto_nome': item.produtoNome,
          'preco_unitario': item.precoUnitario,
          'quantidade': item.quantidade,
          'subtotal': item.subtotal,
          'itens': [item], // Lista de itens individuais para poder cancelar
        };
      }
    }

    return agrupados;
  }

  Future<void> _abrirDetalhesPedido(MesaModel mesa) async {
    if (mesa.pedidoId == null) return;

    try {
      final pedido = await _pedidoRepo.buscarPorId(mesa.pedidoId!);
      if (pedido == null) {
        Get.snackbar('Erro', 'Pedido não encontrado');
        return;
      }

      final itens = await _pedidoRepo.listarItensPedido(pedido.id!);

      Get.dialog(
        _buildDialogDetalhesPedido(mesa, pedido, itens),
        barrierDismissible: true,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar pedido: $e');
    }
  }

  Widget _buildDialogDetalhesPedido(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) {
    final itensAgrupados = _agruparItens(itens);

    return Dialog(
      child: Container(
        width: 650,
        height: MediaQuery.of(Get.context!).size.height * 0.85,
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Row(
              children: [
                Icon(Icons.receipt, size: 28, color: Get.theme.primaryColor),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MESA ${mesa.numero}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Pedido: ${pedido.numero}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    Get.back();
                    _abrirDetalhesPedido(mesa);
                  },
                  tooltip: 'Atualizar',
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            Divider(height: 24),

            // Informações
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Responsável:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(pedido.usuarioNome ?? ''),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Data Abertura:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${pedido.dataAbertura.day}/${pedido.dataAbertura.month}/${pedido.dataAbertura.year} ${pedido.dataAbertura.hour}:${pedido.dataAbertura.minute.toString().padLeft(2, '0')}'),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Lista de itens (com scroll)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ITENS DO PEDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${itensAgrupados.length} tipos', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: itensAgrupados.length,
                itemBuilder: (context, index) {
                  final key = itensAgrupados.keys.elementAt(index);
                  final item = itensAgrupados[key]!;
                  final todosItens = item['itens'] as List<ItemPedidoModel>;

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Get.theme.primaryColor,
                        child: Text(
                          '${item['quantidade']}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        item['produto_nome'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item['quantidade']}x ${Formatters.formatarMoeda(item['preco_unitario'])}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Formatters.formatarMoeda(item['subtotal']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Get.theme.primaryColor,
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _cancelarItem(
                              pedido,
                              mesa,
                              todosItens,
                              item['quantidade'],
                            ),
                            tooltip: 'Cancelar item',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 24),

            // Total (fixo na parte inferior)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TOTAL:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    Formatters.formatarMoeda(pedido.total),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Botões principais (fixos na parte inferior)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _imprimirConta(mesa, pedido, itens);
                    },
                    icon: Icon(Icons.print),
                    label: Text('IMPRIMIR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _finalizarPedido(mesa, pedido, itens);
                    },
                    icon: Icon(Icons.payment),
                    label: Text('FINALIZAR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarItem(
    PedidoModel pedido,
    MesaModel mesa,
    List<ItemPedidoModel> itens,
    int quantidadeTotal,
  ) async {
    final justificativaController = TextEditingController();
    final primeiroItem = itens.first;

    final confirmado = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Cancelar Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produto: ${primeiroItem.produtoNome}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Quantidade: $quantidadeTotal',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            Text(
              'Justificativa do Cancelamento:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: justificativaController,
              decoration: InputDecoration(
                hintText: 'Ex: Cliente desistiu, erro no pedido, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('VOLTAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (justificativaController.text.trim().isEmpty) {
                Get.snackbar(
                  'Atenção',
                  'A justificativa é obrigatória',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back(result: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('CANCELAR ITEM'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmado == true && justificativaController.text.trim().isNotEmpty) {
      try {
        final usuarioId = _authService.usuarioLogado.value?.id ?? 0;
        final usuarioNome = _authService.usuarioLogado.value?.nome ?? '';

        // Cancelar TODOS os itens do grupo
        for (final item in itens) {
          await _pedidoRepo.cancelarItem(
            itemId: item.id!,
            pedidoId: pedido.id!,
            usuarioId: usuarioId,
            usuarioNome: usuarioNome,
            justificativa: justificativaController.text.trim(),
          );
        }

        // Verificar se o pedido ficou vazio e cancelar automaticamente
        await _pedidoRepo.cancelarSeVazio(pedido.id!);

        Get.back(); // Fechar dialog de detalhes

        // Verificar se o pedido ainda existe
        final pedidoAtualizado = await _pedidoRepo.buscarPorId(pedido.id!);

        if (pedidoAtualizado == null || pedidoAtualizado.isCancelado) {
          // Pedido foi cancelado (estava vazio)
          Get.snackbar(
            'Mesa Liberada',
            'Todos os itens foram cancelados. Mesa ${mesa.numero} está livre.',
            backgroundColor: Colors.blue,
            colorText: Colors.white,
          );
        } else {
          // Pedido ainda existe
          Get.snackbar(
            'Sucesso',
            '${itens.length} item(ns) cancelado(s) com sucesso',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          // Reabrir detalhes
          await _abrirDetalhesPedido(mesa);
        }

        // Recarregar dados
        await _carregarDados();
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Erro ao cancelar item: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  void _iniciarUnirContas() async {
    // Buscar mesas ocupadas
    final mesasOcupadas = mesas.where((m) => m.isOcupada).toList();

    if (mesasOcupadas.length < 2) {
      Get.snackbar(
        'Aviso',
        'É necessário ter pelo menos 2 mesas ocupadas para unir contas',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Selecionar mesa destino (onde ficarão todos os itens)
    final mesaDestino = await Get.dialog<MesaModel>(
      AlertDialog(
        title: Text('Unir Contas'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione a mesa DESTINO (onde ficarão todos os itens):'),
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mesasOcupadas.length,
                  itemBuilder: (context, index) {
                    final mesa = mesasOcupadas[index];
                    return ListTile(
                      title: Text('Mesa ${mesa.numero}'),
                      subtitle: Text('Total: ${Formatters.formatarMoeda(mesa.pedidoTotal ?? 0)}'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () => Get.back(result: mesa),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
        ],
      ),
    );

    if (mesaDestino == null || mesaDestino.pedidoId == null) return;

    final pedidoDestino = await _pedidoRepo.buscarPorId(mesaDestino.pedidoId!);
    if (pedidoDestino == null) return;

    await _unirContas(pedidoDestino, mesaDestino);
  }

  void _iniciarDividirConta() async {
    // Buscar mesas ocupadas
    final mesasOcupadas = mesas.where((m) => m.isOcupada).toList();

    if (mesasOcupadas.isEmpty) {
      Get.snackbar(
        'Aviso',
        'Não há mesas ocupadas para dividir',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Selecionar mesa origem (que será dividida)
    final mesaOrigem = await Get.dialog<MesaModel>(
      AlertDialog(
        title: Text('Dividir Conta'),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Selecione a mesa que deseja DIVIDIR:'),
              SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mesasOcupadas.length,
                  itemBuilder: (context, index) {
                    final mesa = mesasOcupadas[index];
                    return ListTile(
                      title: Text('Mesa ${mesa.numero}'),
                      subtitle: Text('Total: ${Formatters.formatarMoeda(mesa.pedidoTotal ?? 0)}'),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () => Get.back(result: mesa),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
        ],
      ),
    );

    if (mesaOrigem == null || mesaOrigem.pedidoId == null) return;

    final pedido = await _pedidoRepo.buscarPorId(mesaOrigem.pedidoId!);
    if (pedido == null) return;

    final itens = await _pedidoRepo.listarItensPedido(pedido.id!);
    if (itens.isEmpty) return;

    await _dividirConta(pedido, mesaOrigem, itens);
  }

  Future<void> _imprimirConta(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) async {
    try {
      // Importar dependências necessárias
      final pdf = await _gerarPDFConta(mesa, pedido, itens);

      // Buscar impressora
      final printer = await _buscarImpressora('balcao');

      if (printer == null) {
        // Se impressora não encontrada, mostrar preview
        Get.snackbar(
          'Aviso',
          'Impressora não encontrada. Mostrando visualização.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        await _visualizarPDF(pdf);
        return;
      }

      // Imprimir diretamente
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) => pdf.save(),
      );

      Get.snackbar(
        'Sucesso',
        'Conta impressa com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao imprimir conta: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<pw.Document> _gerarPDFConta(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) async {
    // Buscar informações da empresa
    final empresaResult = await _db.query('SELECT * FROM empresa LIMIT 1');
    final nomeEmpresa = empresaResult.isNotEmpty
        ? empresaResult.first['nome'] ?? 'RESTAURANTE'
        : 'RESTAURANTE';

    // Agrupar itens
    final itensAgrupados = _agruparItens(itens);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Center(
                child: pw.Text(
                  nomeEmpresa.toUpperCase(),
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),

              // Informações da mesa
              pw.Text('MESA: ${mesa.numero}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text('PEDIDO: ${pedido.numero}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('RESPONSAVEL: ${pedido.usuarioNome ?? ''}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('DATA: ${pedido.dataAbertura.day.toString().padLeft(2, '0')}/${pedido.dataAbertura.month.toString().padLeft(2, '0')}/${pedido.dataAbertura.year}', style: pw.TextStyle(fontSize: 8)),
              pw.Text('HORA: ${pedido.dataAbertura.hour.toString().padLeft(2, '0')}:${pedido.dataAbertura.minute.toString().padLeft(2, '0')}', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),

              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.Text('CONSUMO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),

              // Itens
              ...itensAgrupados.values.map((item) {
                final nomeProduto = item['produto_nome'].toString();
                final quantidade = item['quantidade'];
                final precoUnitario = item['preco_unitario'] as double;
                final subtotal = item['subtotal'] as double;

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(nomeProduto.toUpperCase(), style: pw.TextStyle(fontSize: 9)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$quantidade x ${precoUnitario.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8)),
                        pw.Text(subtotal.toStringAsFixed(2), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                  ],
                );
              }).toList(),

              pw.Text('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 10),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(pedido.total.toStringAsFixed(2), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),

              pw.Text('================================================', style: pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  Future<Printer?> _buscarImpressora(String nome) async {
    try {
      final impressoras = await Printing.listPrinters();

      // Buscar exatamente pelo nome
      for (var impressora in impressoras) {
        if (impressora.name.toLowerCase() == nome.toLowerCase()) {
          return impressora;
        }
      }

      // Se não encontrar exato, buscar que contenha o nome
      for (var impressora in impressoras) {
        if (impressora.name.toLowerCase().contains(nome.toLowerCase())) {
          return impressora;
        }
      }

      return null;
    } catch (e) {
      print('Erro ao buscar impressora: $e');
      return null;
    }
  }

  Future<void> _visualizarPDF(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Conta_Mesa.pdf',
    );
  }

  Future<void> _finalizarPedido(
    MesaModel mesa,
    PedidoModel pedido,
    List<ItemPedidoModel> itens,
  ) async {
    // Retornar dados para o controller processar o pagamento
    Get.back(result: {
      'mesa': mesa,
      'pedido': pedido,
      'itens': itens,
    });
  }

  /// Unir contas de várias mesas em uma só
  Future<void> _unirContas(PedidoModel pedidoDestino, MesaModel mesaDestino) async {
    Get.back(); // Fecha o dialog atual

    // Buscar apenas mesas ocupadas para unir
    final mesasOcupadas = mesas.where((m) => m.isOcupada && m.id != mesaDestino.id).toList();

    if (mesasOcupadas.isEmpty) {
      Get.snackbar(
        'Aviso',
        'Não há outras mesas ocupadas para unir',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Dialog para selecionar mesas
    final mesasSelecionadas = await Get.dialog<List<MesaModel>>(
      _buildDialogSelecionarMesas(mesasOcupadas, mesaDestino),
    );

    if (mesasSelecionadas == null || mesasSelecionadas.isEmpty) return;

    try {
      for (final mesa in mesasSelecionadas) {
        if (mesa.pedidoId != null) {
          await _pedidoRepo.moverItensPedido(mesa.pedidoId!, pedidoDestino.id!);
        }
      }

      Get.snackbar(
        'Sucesso',
        'Contas unidas na Mesa ${mesaDestino.numero}. ${mesasSelecionadas.length} mesa(s) liberada(s).',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _carregarDados();
      await _abrirDetalhesPedido(mesaDestino);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao unir contas: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildDialogSelecionarMesas(List<MesaModel> mesasDisponiveis, MesaModel mesaDestino) {
    final selecionadas = <MesaModel>[];

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text('Unir Contas → Mesa ${mesaDestino.numero}'),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecione as mesas para unir com a Mesa ${mesaDestino.numero}:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: mesasDisponiveis.length,
                    itemBuilder: (context, index) {
                      final mesa = mesasDisponiveis[index];
                      final isSelected = selecionadas.contains(mesa);

                      return CheckboxListTile(
                        title: Text('Mesa ${mesa.numero}'),
                        subtitle: Text('Total: ${Formatters.formatarMoeda(mesa.pedidoTotal ?? 0)}'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selecionadas.add(mesa);
                            } else {
                              selecionadas.remove(mesa);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: selecionadas),
              child: Text('UNIR (${selecionadas.length})'),
            ),
          ],
        );
      },
    );
  }

  /// Dividir conta - mover itens para outra mesa
  Future<void> _dividirConta(PedidoModel pedido, MesaModel mesa, List<ItemPedidoModel> itens) async {
    Get.back(); // Fecha o dialog atual

    final itensAgrupados = _agruparItens(itens);
    final itensSelecionados = <ItemPedidoModel>[];

    // Dialog para selecionar itens
    final confirmar = await Get.dialog<bool>(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Dividir Conta - Mesa ${mesa.numero}'),
            content: Container(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Selecione os itens para mover para outra mesa:'),
                  SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(maxHeight: 350),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: itensAgrupados.length,
                      itemBuilder: (context, index) {
                        final key = itensAgrupados.keys.elementAt(index);
                        final item = itensAgrupados[key]!;
                        final primeiroItem = item['itens'][0] as ItemPedidoModel;
                        final isSelected = itensSelecionados.contains(primeiroItem);

                        return CheckboxListTile(
                          title: Text(item['produto_nome']),
                          subtitle: Text('${item['quantidade']}x ${Formatters.formatarMoeda(item['preco_unitario'])}'),
                          secondary: Text(
                            Formatters.formatarMoeda(item['subtotal']),
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                itensSelecionados.add(primeiroItem);
                              } else {
                                itensSelecionados.remove(primeiroItem);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('CANCELAR'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itensSelecionados.isEmpty) {
                    Get.snackbar('Aviso', 'Selecione pelo menos um item');
                    return;
                  }
                  Get.back(result: true);
                },
                child: Text('CONTINUAR (${itensSelecionados.length})'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmar != true || itensSelecionados.isEmpty) return;

    // Selecionar mesa destino
    final mesasLivres = mesas.where((m) => m.isLivre).toList();

    if (mesasLivres.isEmpty) {
      Get.snackbar(
        'Aviso',
        'Não há mesas livres disponíveis',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final mesaDestino = await Get.dialog<MesaModel>(
      _buildDialogSelecionarMesaDestino(mesasLivres),
    );

    if (mesaDestino == null) return;

    try {
      final usuarioId = _authService.usuarioLogado.value?.id ?? 0;

      // Criar novo pedido na mesa destino
      final numeroPedido = 'PD${DateTime.now().millisecondsSinceEpoch}';
      final novoPedido = PedidoModel(
        numero: numeroPedido,
        mesaId: mesaDestino.id!,
        usuarioId: usuarioId,
        status: 'aberto',
      );

      final novoPedidoId = await _pedidoRepo.criar(novoPedido);

      // Mover itens selecionados
      for (final item in itensSelecionados) {
        await _db.execute('''
          UPDATE itens_pedido
          SET pedido_id = @novo_pedido_id
          WHERE id = @item_id
        ''', parameters: {
          'novo_pedido_id': novoPedidoId,
          'item_id': item.id,
        });
      }

      // Verificar se o pedido original ficou vazio
      await _pedidoRepo.cancelarSeVazio(pedido.id!);

      Get.snackbar(
        'Sucesso',
        'Conta dividida! ${itensSelecionados.length} item(ns) movido(s) para Mesa ${mesaDestino.numero}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      await _carregarDados();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao dividir conta: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildDialogSelecionarMesaDestino(List<MesaModel> mesasLivres) {
    return AlertDialog(
      title: Text('Selecionar Mesa Destino'),
      content: Container(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Para qual mesa mover os itens?'),
            SizedBox(height: 16),
            Container(
              constraints: BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mesasLivres.length,
                itemBuilder: (context, index) {
                  final mesa = mesasLivres[index];
                  return ListTile(
                    title: Text('Mesa ${mesa.numero}'),
                    subtitle: Text(mesa.localNome ?? ''),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () => Get.back(result: mesa),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('CANCELAR'),
        ),
      ],
    );
  }
}
