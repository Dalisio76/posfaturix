import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/pedido_model.dart';
import '../models/item_pedido_model.dart';

class PedidoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Lista pedidos abertos
  Future<List<PedidoModel>> listarAbertos() async {
    final result = await _db.query('''
      SELECT * FROM v_pedidos_abertos
      ORDER BY data_abertura DESC
    ''');

    return result.map((map) => PedidoModel.fromMap(map)).toList();
  }

  /// Lista pedidos de um usuário
  Future<List<PedidoModel>> listarPorUsuario(int usuarioId) async {
    final result = await _db.query('''
      SELECT * FROM v_pedidos_abertos
      WHERE usuario_id = @usuario_id
      ORDER BY data_abertura DESC
    ''', parameters: {'usuario_id': usuarioId});

    return result.map((map) => PedidoModel.fromMap(map)).toList();
  }

  /// Busca pedido por ID
  Future<PedidoModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_pedidos_abertos WHERE id = @id
    ''', parameters: {'id': id});

    if (result.isEmpty) return null;
    return PedidoModel.fromMap(result.first);
  }

  /// Busca pedido aberto de uma mesa
  Future<PedidoModel?> buscarPedidoAbertoMesa(int mesaId) async {
    final result = await _db.query('''
      SELECT * FROM pedidos
      WHERE mesa_id = @mesa_id AND status = 'aberto'
      LIMIT 1
    ''', parameters: {'mesa_id': mesaId});

    if (result.isEmpty) return null;
    return PedidoModel.fromMap(result.first);
  }

  /// Cria novo pedido
  Future<int> criar(PedidoModel pedido) async {
    return await _db.insert('''
      INSERT INTO pedidos (numero, mesa_id, usuario_id, status, observacoes)
      VALUES (@numero, @mesa_id, @usuario_id, @status, @observacoes)
    ''', parameters: {
      'numero': pedido.numero,
      'mesa_id': pedido.mesaId,
      'usuario_id': pedido.usuarioId,
      'status': pedido.status,
      'observacoes': pedido.observacoes,
    });
  }

  /// Adiciona item ao pedido
  Future<void> adicionarItem(ItemPedidoModel item) async {
    await _db.execute('''
      INSERT INTO itens_pedido
        (pedido_id, produto_id, produto_nome, quantidade, preco_unitario, subtotal, observacoes)
      VALUES
        (@pedido_id, @produto_id, @produto_nome, @quantidade, @preco_unitario, @subtotal, @observacoes)
    ''', parameters: item.toMap());
  }

  /// Adiciona múltiplos itens ao pedido
  Future<void> adicionarItens(List<ItemPedidoModel> itens) async {
    for (final item in itens) {
      await adicionarItem(item);
    }
  }

  /// Lista itens de um pedido
  Future<List<ItemPedidoModel>> listarItensPedido(int pedidoId) async {
    final result = await _db.query('''
      SELECT * FROM itens_pedido
      WHERE pedido_id = @pedido_id
      ORDER BY created_at
    ''', parameters: {'pedido_id': pedidoId});

    return result.map((map) => ItemPedidoModel.fromMap(map)).toList();
  }

  /// Remove item do pedido
  Future<void> removerItem(int itemId) async {
    await _db.execute('''
      DELETE FROM itens_pedido WHERE id = @id
    ''', parameters: {'id': itemId});
  }

  /// Cancela item do pedido com justificativa
  Future<void> cancelarItem({
    required int itemId,
    required int pedidoId,
    required int usuarioId,
    required String usuarioNome,
    required String justificativa,
  }) async {
    // Buscar informações do item antes de cancelar
    final item = await _db.query('''
      SELECT * FROM itens_pedido WHERE id = @id
    ''', parameters: {'id': itemId});

    if (item.isEmpty) {
      throw Exception('Item não encontrado');
    }

    final itemData = item.first;

    // Registrar cancelamento no log
    await _db.execute('''
      INSERT INTO cancelamentos_item_pedido
        (item_pedido_id, pedido_id, produto_id, produto_nome, quantidade,
         preco_unitario, subtotal, usuario_id, usuario_nome, justificativa)
      VALUES
        (@item_pedido_id, @pedido_id, @produto_id, @produto_nome, @quantidade,
         @preco_unitario, @subtotal, @usuario_id, @usuario_nome, @justificativa)
    ''', parameters: {
      'item_pedido_id': itemId,
      'pedido_id': pedidoId,
      'produto_id': itemData['produto_id'],
      'produto_nome': itemData['produto_nome'],
      'quantidade': itemData['quantidade'],
      'preco_unitario': itemData['preco_unitario'],
      'subtotal': itemData['subtotal'],
      'usuario_id': usuarioId,
      'usuario_nome': usuarioNome,
      'justificativa': justificativa,
    });

    // Remover item do pedido
    await removerItem(itemId);
  }

  /// Atualiza quantidade de item
  Future<void> atualizarQuantidadeItem(int itemId, int novaQuantidade) async {
    await _db.execute('''
      UPDATE itens_pedido
      SET quantidade = @quantidade,
          subtotal = preco_unitario * @quantidade
      WHERE id = @id
    ''', parameters: {
      'id': itemId,
      'quantidade': novaQuantidade,
    });
  }

  /// Fecha pedido (converte em venda)
  Future<void> fechar(int pedidoId) async {
    await _db.execute('''
      UPDATE pedidos
      SET status = 'fechado',
          data_fechamento = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {'id': pedidoId});
  }

  /// Cancela pedido
  Future<void> cancelar(int pedidoId) async {
    await _db.execute('''
      UPDATE pedidos
      SET status = 'cancelado',
          data_fechamento = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {'id': pedidoId});
  }

  /// Atualiza observações do pedido
  Future<void> atualizarObservacoes(int pedidoId, String observacoes) async {
    await _db.execute('''
      UPDATE pedidos
      SET observacoes = @observacoes
      WHERE id = @id
    ''', parameters: {
      'id': pedidoId,
      'observacoes': observacoes,
    });
  }

  /// Calcula total do pedido (já é feito automaticamente por trigger)
  Future<double> calcularTotal(int pedidoId) async {
    final result = await _db.query('''
      SELECT calcular_total_pedido(@pedido_id) as total
    ''', parameters: {'pedido_id': pedidoId});

    return double.parse(result.first['total'].toString());
  }

  /// Conta quantos itens tem no pedido
  Future<int> contarItensPedido(int pedidoId) async {
    final result = await _db.query('''
      SELECT COUNT(*) as count FROM itens_pedido WHERE pedido_id = @pedido_id
    ''', parameters: {'pedido_id': pedidoId});

    return result.first['count'] as int;
  }

  /// Move todos os itens de um pedido para outro (para unir contas)
  Future<void> moverItensPedido(int pedidoOrigemId, int pedidoDestinoId) async {
    await _db.execute('''
      UPDATE itens_pedido
      SET pedido_id = @pedido_destino
      WHERE pedido_id = @pedido_origem
    ''', parameters: {
      'pedido_origem': pedidoOrigemId,
      'pedido_destino': pedidoDestinoId,
    });

    // Fechar pedido origem
    await fechar(pedidoOrigemId);
  }

  /// Cancela pedido vazio (sem itens)
  Future<void> cancelarSeVazio(int pedidoId) async {
    final count = await contarItensPedido(pedidoId);
    if (count == 0) {
      await cancelar(pedidoId);
    }
  }
}
