import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/produto_composicao_model.dart';

class ProdutoComposicaoRepository {
  final DatabaseService _db = Get.find<DatabaseService>();

  /// Buscar composição de um produto
  Future<List<ProdutoComposicaoModel>> buscarComposicao(int produtoId) async {
    final result = await _db.query('''
      SELECT * FROM get_composicao_produto(@produto_id)
    ''', parameters: {'produto_id': produtoId});

    return result.map((map) {
      return ProdutoComposicaoModel.fromMap({
        'produto_id': produtoId,
        'produto_componente_id': map['componente_id'],
        'quantidade': map['quantidade'],
        'componente_codigo': map['componente_codigo'],
        'componente_nome': map['componente_nome'],
        'componente_estoque': map['estoque_disponivel'],
      });
    }).toList();
  }

  /// Adicionar componente à composição de um produto
  Future<void> adicionarComponente(ProdutoComposicaoModel composicao) async {
    await _db.execute('''
      INSERT INTO produto_composicao (produto_id, produto_componente_id, quantidade)
      VALUES (@produto_id, @produto_componente_id, @quantidade)
      ON CONFLICT (produto_id, produto_componente_id)
      DO UPDATE SET quantidade = @quantidade
    ''', parameters: composicao.toMap());
  }

  /// Remover componente da composição
  Future<void> removerComponente(int produtoId, int componenteId) async {
    await _db.execute('''
      DELETE FROM produto_composicao
      WHERE produto_id = @produto_id
      AND produto_componente_id = @componente_id
    ''', parameters: {
      'produto_id': produtoId,
      'componente_id': componenteId,
    });
  }

  /// Limpar toda a composição de um produto
  Future<void> limparComposicao(int produtoId) async {
    await _db.execute('''
      DELETE FROM produto_composicao
      WHERE produto_id = @produto_id
    ''', parameters: {'produto_id': produtoId});
  }

  /// Salvar composição completa (limpa e recria)
  Future<void> salvarComposicao(
    int produtoId,
    List<ProdutoComposicaoModel> composicoes,
  ) async {
    // Limpar composição existente
    await limparComposicao(produtoId);

    // Adicionar novos componentes
    for (final composicao in composicoes) {
      // Criar nova composição com o produtoId correto
      final composicaoAtualizada = ProdutoComposicaoModel(
        produtoId: produtoId, // Usar o ID real do produto
        produtoComponenteId: composicao.produtoComponenteId,
        quantidade: composicao.quantidade,
      );
      await adicionarComponente(composicaoAtualizada);
    }
  }

  /// Verificar se produto tem estoque disponível (considerando composição)
  Future<Map<String, dynamic>> verificarEstoqueDisponivel(
    int produtoId,
    int quantidadeDesejada,
  ) async {
    final result = await _db.query('''
      SELECT * FROM verificar_estoque_disponivel(@produto_id, @quantidade)
    ''', parameters: {
      'produto_id': produtoId,
      'quantidade': quantidadeDesejada,
    });

    if (result.isEmpty) {
      return {'disponivel': false, 'mensagem': 'Erro ao verificar estoque'};
    }

    return {
      'disponivel': result.first['disponivel'],
      'mensagem': result.first['mensagem'],
    };
  }

  /// Abater estoque do produto (considerando composição)
  Future<void> abaterEstoque(int produtoId, int quantidade) async {
    await _db.execute('''
      SELECT abater_estoque_produto(@produto_id, @quantidade)
    ''', parameters: {
      'produto_id': produtoId,
      'quantidade': quantidade,
    });
  }
}
