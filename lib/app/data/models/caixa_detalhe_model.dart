// ===================================
// MODELS PARA DETALHES DO CAIXA
// ===================================

/// Detalhes de uma despesa do caixa
class DespesaDetalhe {
  final int despesaId;
  final String descricao;
  final double valor;
  final DateTime dataDespesa;
  final String? observacoes;

  DespesaDetalhe({
    required this.despesaId,
    required this.descricao,
    required this.valor,
    required this.dataDespesa,
    this.observacoes,
  });

  factory DespesaDetalhe.fromMap(Map<String, dynamic> map) {
    return DespesaDetalhe(
      despesaId: map['despesa_id'] ?? 0,
      descricao: map['descricao']?.toString() ?? '',
      valor: double.tryParse(map['valor']?.toString() ?? '0') ?? 0.0,
      dataDespesa: DateTime.parse(map['data_despesa'].toString()),
      observacoes: map['observacoes']?.toString(),
    );
  }
}

/// Detalhes de um pagamento de dívida
class PagamentoDividaDetalhe {
  final int pagamentoId;
  final int dividaId;
  final double valor;
  final DateTime dataPagamento;
  final String? observacoes;
  final String formaPagamento;
  final String clienteNome;
  final String? clienteContacto;
  final double dividaTotal;
  final double dividaPago;
  final double dividaRestante;

  PagamentoDividaDetalhe({
    required this.pagamentoId,
    required this.dividaId,
    required this.valor,
    required this.dataPagamento,
    this.observacoes,
    required this.formaPagamento,
    required this.clienteNome,
    this.clienteContacto,
    required this.dividaTotal,
    required this.dividaPago,
    required this.dividaRestante,
  });

  factory PagamentoDividaDetalhe.fromMap(Map<String, dynamic> map) {
    return PagamentoDividaDetalhe(
      pagamentoId: map['pagamento_id'] ?? 0,
      dividaId: map['divida_id'] ?? 0,
      valor: double.tryParse(map['valor']?.toString() ?? '0') ?? 0.0,
      dataPagamento: DateTime.parse(map['data_pagamento'].toString()),
      observacoes: map['observacoes']?.toString(),
      formaPagamento: map['forma_pagamento']?.toString() ?? '',
      clienteNome: map['cliente_nome']?.toString() ?? '',
      clienteContacto: map['cliente_contacto']?.toString(),
      dividaTotal: double.tryParse(map['divida_total']?.toString() ?? '0') ?? 0.0,
      dividaPago: double.tryParse(map['divida_pago']?.toString() ?? '0') ?? 0.0,
      dividaRestante: double.tryParse(map['divida_restante']?.toString() ?? '0') ?? 0.0,
    );
  }
}

/// Produto vendido no caixa (detalhado por venda)
class ProdutoVendidoDetalhe {
  final int vendaId;
  final String vendaNumero;
  final DateTime dataVenda;
  final double vendaTotal;
  final int produtoId;
  final String produtoNome;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  ProdutoVendidoDetalhe({
    required this.vendaId,
    required this.vendaNumero,
    required this.dataVenda,
    required this.vendaTotal,
    required this.produtoId,
    required this.produtoNome,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });

  factory ProdutoVendidoDetalhe.fromMap(Map<String, dynamic> map) {
    return ProdutoVendidoDetalhe(
      vendaId: map['venda_id'] ?? 0,
      vendaNumero: map['venda_numero']?.toString() ?? '',
      dataVenda: DateTime.parse(map['data_venda'].toString()),
      vendaTotal: double.tryParse(map['venda_total']?.toString() ?? '0') ?? 0.0,
      produtoId: map['produto_id'] ?? 0,
      produtoNome: map['produto_nome']?.toString() ?? '',
      quantidade: map['quantidade'] ?? 0,
      precoUnitario: double.tryParse(map['preco_unitario']?.toString() ?? '0') ?? 0.0,
      subtotal: double.tryParse(map['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

/// Resumo agregado de produtos vendidos
class ResumoProdutoVendido {
  final int produtoId;
  final String produtoNome;
  final int quantidadeTotal;
  final double precoUnitario;
  final double subtotalTotal;

  ResumoProdutoVendido({
    required this.produtoId,
    required this.produtoNome,
    required this.quantidadeTotal,
    required this.precoUnitario,
    required this.subtotalTotal,
  });

  factory ResumoProdutoVendido.fromMap(Map<String, dynamic> map) {
    return ResumoProdutoVendido(
      produtoId: map['produto_id'] ?? 0,
      produtoNome: map['produto_nome']?.toString() ?? '',
      quantidadeTotal: map['quantidade_total'] ?? 0,
      precoUnitario: double.tryParse(map['preco_unitario']?.toString() ?? '0') ?? 0.0,
      subtotalTotal: double.tryParse(map['subtotal_total']?.toString() ?? '0') ?? 0.0,
    );
  }
}
