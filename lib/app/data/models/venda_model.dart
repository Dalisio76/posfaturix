import 'item_venda_model.dart';
import 'pagamento_venda_model.dart';

class VendaModel {
  final int? id;
  final String numero;
  final int? numeroVenda; // Número sequencial simples (1, 2, 3...)
  final int? clienteId;
  final int? usuarioId;
  final double total;
  final DateTime dataVenda;
  final String? terminal;
  final String? observacoes;
  final String status; // 'finalizada', 'cancelada'

  // Itens da venda
  final List<ItemVendaModel>? itens;

  // Pagamentos da venda
  final List<PagamentoVendaModel>? pagamentos;

  // Campos adicionais para joins
  final String? clienteNome;
  final String? usuarioNome;

  VendaModel({
    this.id,
    required this.numero,
    this.numeroVenda,
    this.clienteId,
    this.usuarioId,
    required this.total,
    required this.dataVenda,
    this.terminal,
    this.observacoes,
    this.status = 'finalizada',
    this.itens,
    this.pagamentos,
    this.clienteNome,
    this.usuarioNome,
  });

  factory VendaModel.fromMap(Map<String, dynamic> map) {
    return VendaModel(
      id: map['id'],
      numero: map['numero'],
      numeroVenda: map['numero_venda'],
      clienteId: map['cliente_id'],
      usuarioId: map['usuario_id'],
      total: double.parse(map['total'].toString()),
      dataVenda: DateTime.parse(map['data_venda'].toString()),
      terminal: map['terminal'],
      observacoes: map['observacoes'],
      status: map['status'] ?? 'finalizada',
      clienteNome: map['cliente_nome'],
      usuarioNome: map['usuario_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'numero_venda': numeroVenda,
      'cliente_id': clienteId,
      'usuario_id': usuarioId,
      'total': total,
      'data_venda': dataVenda.toIso8601String(),
      'terminal': terminal,
      'observacoes': observacoes,
      'status': status,
    };
  }

  /// Retorna o número de exibição da venda (prioriza numero_venda)
  String get numeroExibicao => numeroVenda?.toString() ?? numero;

  bool get isCancelada => status == 'cancelada';
  bool get isFinalizada => status == 'finalizada';
}
