# 🚀 GUIA - Clientes, Dívidas e Despesas

> **Sistema completo de:**
> - CRUD de Clientes
> - Sistema de Dívidas
> - Pagamento de Dívidas
> - Despesas
> - Teclado Virtual para Pesquisa

---

## 📋 Índice

1. [SQL - Criar Tabelas](#fase-1-sql---criar-tabelas)
2. [Models Flutter](#fase-2-models-flutter)
3. [Repositories](#fase-3-repositories)
4. [Teclado Virtual](#fase-4-teclado-virtual-de-pesquisa)
5. [Admin - CRUD Clientes](#fase-5-admin---crud-clientes)
6. [Admin - CRUD Despesas](#fase-6-admin---crud-despesas)
7. [Vendas - Sistema de Dívidas](#fase-7-vendas---sistema-de-dívidas)
8. [Tela de Devedores](#fase-8-tela-de-devedores)
9. [Pagamento de Dívidas](#fase-9-pagamento-de-dívidas)
10. [Integração Completa](#fase-10-integração-completa)

---

## 🗄️ FASE 1: SQL - Criar Tabelas

### Abrir SQL Shell

```bash
# SQL Shell (psql)
# Pressione Enter em tudo, depois digite a senha

\c pdv_system
```

### Executar SQL Completo

Cole todo este código:

```sql
-- ===================================
-- TABELA: clientes
-- ===================================
CREATE TABLE clientes (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    contacto VARCHAR(50),
    contacto2 VARCHAR(50),
    email VARCHAR(100),
    endereco TEXT,
    bairro VARCHAR(100),
    cidade VARCHAR(100),
    nuit VARCHAR(50),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_clientes_nome ON clientes(nome);
CREATE INDEX idx_clientes_contacto ON clientes(contacto);
CREATE INDEX idx_clientes_ativo ON clientes(ativo);

-- Dados de exemplo
INSERT INTO clientes (nome, contacto, email, endereco, cidade) VALUES 
('João Silva', '+258 84 111 2222', 'joao@email.com', 'Av. 25 de Setembro, 123', 'Maputo'),
('Maria Santos', '+258 82 333 4444', 'maria@email.com', 'Rua da Resistência, 456', 'Matola'),
('António Macamo', '+258 86 555 6666', 'antonio@email.com', 'Av. Julius Nyerere, 789', 'Maputo');

-- ===================================
-- TABELA: dividas
-- ===================================
CREATE TABLE dividas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    venda_id INTEGER UNIQUE REFERENCES vendas(id) ON DELETE CASCADE,
    valor_total DECIMAL(10,2) NOT NULL,
    valor_pago DECIMAL(10,2) DEFAULT 0,
    valor_restante DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDENTE', -- PENDENTE, PAGO, PARCIAL
    observacoes TEXT,
    data_divida TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_vencimento TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_dividas_cliente ON dividas(cliente_id);
CREATE INDEX idx_dividas_status ON dividas(status);
CREATE INDEX idx_dividas_data ON dividas(data_divida);

-- ===================================
-- TABELA: pagamentos_divida
-- ===================================
CREATE TABLE pagamentos_divida (
    id SERIAL PRIMARY KEY,
    divida_id INTEGER NOT NULL REFERENCES dividas(id) ON DELETE CASCADE,
    valor DECIMAL(10,2) NOT NULL,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    data_pagamento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacoes TEXT,
    usuario VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_pagamentos_divida ON pagamentos_divida(divida_id);
CREATE INDEX idx_pagamentos_data ON pagamentos_divida(data_pagamento);

-- ===================================
-- TABELA: despesas
-- ===================================
CREATE TABLE despesas (
    id SERIAL PRIMARY KEY,
    descricao TEXT NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    categoria VARCHAR(100),
    data_despesa TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento_id INTEGER REFERENCES formas_pagamento(id),
    observacoes TEXT,
    usuario VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_despesas_data ON despesas(data_despesa);
CREATE INDEX idx_despesas_categoria ON despesas(categoria);

-- Dados de exemplo
INSERT INTO despesas (descricao, valor, categoria) VALUES 
('Compra de gás', 500.00, 'OPERACIONAL'),
('Conta de luz', 1200.00, 'UTILIDADES'),
('Salário funcionário', 8000.00, 'PESSOAL');

-- ===================================
-- ATUALIZAR TABELA VENDAS
-- Adicionar cliente_id e tipo_venda
-- ===================================
ALTER TABLE vendas ADD COLUMN cliente_id INTEGER REFERENCES clientes(id);
ALTER TABLE vendas ADD COLUMN tipo_venda VARCHAR(20) DEFAULT 'NORMAL'; -- NORMAL, DIVIDA

CREATE INDEX idx_vendas_cliente ON vendas(cliente_id);
CREATE INDEX idx_vendas_tipo ON vendas(tipo_venda);

-- ===================================
-- VIEWS ÚTEIS
-- ===================================

-- View: Clientes com total de dívidas
CREATE VIEW v_clientes_dividas AS
SELECT 
    c.id,
    c.nome,
    c.contacto,
    c.email,
    COUNT(d.id) as total_dividas,
    SUM(d.valor_restante) as total_devendo,
    MAX(d.data_divida) as ultima_divida
FROM clientes c
LEFT JOIN dividas d ON c.id = d.cliente_id AND d.status != 'PAGO'
GROUP BY c.id, c.nome, c.contacto, c.email;

-- View: Dívidas completas (com nome do cliente)
CREATE VIEW v_dividas_completo AS
SELECT 
    d.*,
    c.nome as cliente_nome,
    c.contacto as cliente_contacto,
    v.numero as venda_numero,
    v.data_venda
FROM dividas d
INNER JOIN clientes c ON d.cliente_id = c.id
LEFT JOIN vendas v ON d.venda_id = v.id;

-- View: Resumo de despesas
CREATE VIEW v_despesas_resumo AS
SELECT 
    categoria,
    COUNT(*) as total_despesas,
    SUM(valor) as total_valor,
    DATE(data_despesa) as data
FROM despesas
GROUP BY categoria, DATE(data_despesa)
ORDER BY data DESC;

-- View: Devedores (clientes com dívidas pendentes)
CREATE VIEW v_devedores AS
SELECT 
    c.id,
    c.nome,
    c.contacto,
    c.email,
    COUNT(DISTINCT d.id) as qtd_dividas,
    SUM(d.valor_restante) as total_devendo,
    MIN(d.data_divida) as divida_mais_antiga,
    MAX(d.data_divida) as divida_mais_recente
FROM clientes c
INNER JOIN dividas d ON c.id = d.cliente_id
WHERE d.status != 'PAGO'
GROUP BY c.id, c.nome, c.contacto, c.email
HAVING SUM(d.valor_restante) > 0
ORDER BY total_devendo DESC;

-- ===================================
-- TRIGGER: Atualizar valor_restante automaticamente
-- ===================================
CREATE OR REPLACE FUNCTION atualizar_valor_restante()
RETURNS TRIGGER AS $$
BEGIN
    -- Atualizar valor_restante
    NEW.valor_restante := NEW.valor_total - NEW.valor_pago;
    
    -- Atualizar status
    IF NEW.valor_pago = 0 THEN
        NEW.status := 'PENDENTE';
    ELSIF NEW.valor_pago >= NEW.valor_total THEN
        NEW.status := 'PAGO';
    ELSE
        NEW.status := 'PARCIAL';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_atualizar_valor_restante
BEFORE INSERT OR UPDATE ON dividas
FOR EACH ROW
EXECUTE FUNCTION atualizar_valor_restante();

-- ===================================
-- FUNCTION: Registrar pagamento de dívida
-- ===================================
CREATE OR REPLACE FUNCTION registrar_pagamento_divida(
    p_divida_id INTEGER,
    p_valor DECIMAL(10,2),
    p_forma_pagamento_id INTEGER,
    p_observacoes TEXT DEFAULT NULL,
    p_usuario VARCHAR(100) DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_valor_restante DECIMAL(10,2);
BEGIN
    -- Buscar valor restante
    SELECT valor_restante INTO v_valor_restante
    FROM dividas
    WHERE id = p_divida_id;
    
    -- Validar se dívida existe
    IF v_valor_restante IS NULL THEN
        RAISE EXCEPTION 'Dívida não encontrada';
    END IF;
    
    -- Validar se valor não excede restante
    IF p_valor > v_valor_restante THEN
        RAISE EXCEPTION 'Valor excede o restante da dívida';
    END IF;
    
    -- Inserir pagamento
    INSERT INTO pagamentos_divida (divida_id, valor, forma_pagamento_id, observacoes, usuario)
    VALUES (p_divida_id, p_valor, p_forma_pagamento_id, p_observacoes, p_usuario);
    
    -- Atualizar valor_pago na dívida
    UPDATE dividas
    SET valor_pago = valor_pago + p_valor
    WHERE id = p_divida_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- COMENTÁRIOS NAS TABELAS
-- ===================================
COMMENT ON TABLE clientes IS 'Cadastro de clientes';
COMMENT ON TABLE dividas IS 'Registro de dívidas de clientes';
COMMENT ON TABLE pagamentos_divida IS 'Histórico de pagamentos de dívidas';
COMMENT ON TABLE despesas IS 'Registro de despesas do estabelecimento';

COMMENT ON COLUMN dividas.status IS 'PENDENTE: Não pagou nada, PARCIAL: Pagou parte, PAGO: Quitado';
COMMENT ON COLUMN vendas.tipo_venda IS 'NORMAL: Venda comum, DIVIDA: Venda a crédito';
```

### Verificar Criação

```sql
-- Ver tabelas
\dt

-- Ver dados
SELECT * FROM clientes;
SELECT * FROM dividas;
SELECT * FROM despesas;

-- Ver views
SELECT * FROM v_devedores;

-- Testar function
SELECT registrar_pagamento_divida(1, 100.00, 1, 'Pagamento parcial', 'Admin');

-- Sair
\q
```

### ✅ Checkpoint Fase 1

- [ ] Todas tabelas criadas
- [ ] Views criadas
- [ ] Trigger criado
- [ ] Function criada
- [ ] Dados de exemplo inseridos

---

## 📱 FASE 2: Models Flutter

### 1. Cliente Model

Crie `lib/app/data/models/cliente_model.dart`:

```dart
class ClienteModel {
  final int? id;
  final String nome;
  final String? contacto;
  final String? contacto2;
  final String? email;
  final String? endereco;
  final String? bairro;
  final String? cidade;
  final String? nuit;
  final String? observacoes;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Campos adicionais de views
  final int? totalDividas;
  final double? totalDevendo;
  final DateTime? ultimaDivida;

  ClienteModel({
    this.id,
    required this.nome,
    this.contacto,
    this.contacto2,
    this.email,
    this.endereco,
    this.bairro,
    this.cidade,
    this.nuit,
    this.observacoes,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.totalDividas,
    this.totalDevendo,
    this.ultimaDivida,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> map) {
    return ClienteModel(
      id: map['id'],
      nome: map['nome'],
      contacto: map['contacto'],
      contacto2: map['contacto2'],
      email: map['email'],
      endereco: map['endereco'],
      bairro: map['bairro'],
      cidade: map['cidade'],
      nuit: map['nuit'],
      observacoes: map['observacoes'],
      ativo: map['ativo'] ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'].toString()) 
          : null,
      totalDividas: map['total_dividas'],
      totalDevendo: map['total_devendo'] != null 
          ? double.parse(map['total_devendo'].toString()) 
          : null,
      ultimaDivida: map['ultima_divida'] != null 
          ? DateTime.parse(map['ultima_divida'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'contacto': contacto,
      'contacto2': contacto2,
      'email': email,
      'endereco': endereco,
      'bairro': bairro,
      'cidade': cidade,
      'nuit': nuit,
      'observacoes': observacoes,
      'ativo': ativo,
    };
  }

  @override
  String toString() => 'Cliente(id: $id, nome: $nome, contacto: $contacto)';
}
```

### 2. Dívida Model

Crie `lib/app/data/models/divida_model.dart`:

```dart
class DividaModel {
  final int? id;
  final int clienteId;
  final int? vendaId;
  final double valorTotal;
  final double valorPago;
  final double valorRestante;
  final String status;
  final String? observacoes;
  final DateTime dataDivida;
  final DateTime? dataVencimento;
  final DateTime? createdAt;
  
  // Campos adicionais de views
  final String? clienteNome;
  final String? clienteContacto;
  final String? vendaNumero;
  final DateTime? dataVenda;

  DividaModel({
    this.id,
    required this.clienteId,
    this.vendaId,
    required this.valorTotal,
    this.valorPago = 0,
    required this.valorRestante,
    this.status = 'PENDENTE',
    this.observacoes,
    required this.dataDivida,
    this.dataVencimento,
    this.createdAt,
    this.clienteNome,
    this.clienteContacto,
    this.vendaNumero,
    this.dataVenda,
  });

  factory DividaModel.fromMap(Map<String, dynamic> map) {
    return DividaModel(
      id: map['id'],
      clienteId: map['cliente_id'],
      vendaId: map['venda_id'],
      valorTotal: double.parse(map['valor_total'].toString()),
      valorPago: double.parse(map['valor_pago'].toString()),
      valorRestante: double.parse(map['valor_restante'].toString()),
      status: map['status'] ?? 'PENDENTE',
      observacoes: map['observacoes'],
      dataDivida: DateTime.parse(map['data_divida'].toString()),
      dataVencimento: map['data_vencimento'] != null 
          ? DateTime.parse(map['data_vencimento'].toString()) 
          : null,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      clienteNome: map['cliente_nome'],
      clienteContacto: map['cliente_contacto'],
      vendaNumero: map['venda_numero'],
      dataVenda: map['data_venda'] != null 
          ? DateTime.parse(map['data_venda'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cliente_id': clienteId,
      'venda_id': vendaId,
      'valor_total': valorTotal,
      'valor_pago': valorPago,
      'valor_restante': valorRestante,
      'status': status,
      'observacoes': observacoes,
      'data_divida': dataDivida.toIso8601String(),
      'data_vencimento': dataVencimento?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Divida(id: $id, cliente: $clienteNome, total: $valorTotal, restante: $valorRestante)';
}
```

### 3. Pagamento Dívida Model

Crie `lib/app/data/models/pagamento_divida_model.dart`:

```dart
class PagamentoDividaModel {
  final int? id;
  final int dividaId;
  final double valor;
  final int? formaPagamentoId;
  final DateTime dataPagamento;
  final String? observacoes;
  final String? usuario;
  final DateTime? createdAt;
  
  // Campo adicional
  final String? formaPagamentoNome;

  PagamentoDividaModel({
    this.id,
    required this.dividaId,
    required this.valor,
    this.formaPagamentoId,
    required this.dataPagamento,
    this.observacoes,
    this.usuario,
    this.createdAt,
    this.formaPagamentoNome,
  });

  factory PagamentoDividaModel.fromMap(Map<String, dynamic> map) {
    return PagamentoDividaModel(
      id: map['id'],
      dividaId: map['divida_id'],
      valor: double.parse(map['valor'].toString()),
      formaPagamentoId: map['forma_pagamento_id'],
      dataPagamento: DateTime.parse(map['data_pagamento'].toString()),
      observacoes: map['observacoes'],
      usuario: map['usuario'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      formaPagamentoNome: map['forma_pagamento_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'divida_id': dividaId,
      'valor': valor,
      'forma_pagamento_id': formaPagamentoId,
      'data_pagamento': dataPagamento.toIso8601String(),
      'observacoes': observacoes,
      'usuario': usuario,
    };
  }
}
```

### 4. Despesa Model

Crie `lib/app/data/models/despesa_model.dart`:

```dart
class DespesaModel {
  final int? id;
  final String descricao;
  final double valor;
  final String? categoria;
  final DateTime dataDespesa;
  final int? formaPagamentoId;
  final String? observacoes;
  final String? usuario;
  final DateTime? createdAt;
  
  // Campo adicional
  final String? formaPagamentoNome;

  DespesaModel({
    this.id,
    required this.descricao,
    required this.valor,
    this.categoria,
    required this.dataDespesa,
    this.formaPagamentoId,
    this.observacoes,
    this.usuario,
    this.createdAt,
    this.formaPagamentoNome,
  });

  factory DespesaModel.fromMap(Map<String, dynamic> map) {
    return DespesaModel(
      id: map['id'],
      descricao: map['descricao'],
      valor: double.parse(map['valor'].toString()),
      categoria: map['categoria'],
      dataDespesa: DateTime.parse(map['data_despesa'].toString()),
      formaPagamentoId: map['forma_pagamento_id'],
      observacoes: map['observacoes'],
      usuario: map['usuario'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      formaPagamentoNome: map['forma_pagamento_nome'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descricao': descricao,
      'valor': valor,
      'categoria': categoria,
      'data_despesa': dataDespesa.toIso8601String(),
      'forma_pagamento_id': formaPagamentoId,
      'observacoes': observacoes,
      'usuario': usuario,
    };
  }

  @override
  String toString() => 'Despesa(id: $id, descricao: $descricao, valor: $valor)';
}
```

### ✅ Checkpoint Fase 2

- [ ] ClienteModel criado
- [ ] DividaModel criado
- [ ] PagamentoDividaModel criado
- [ ] DespesaModel criado
- [ ] Sem erros de compilação

---

## 🔧 FASE 3: Repositories

### 1. Cliente Repository

Crie `lib/app/data/repositories/cliente_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/cliente_model.dart';

class ClienteRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  /// Listar todos clientes ativos
  Future<List<ClienteModel>> listarTodos() async {
    final result = await _db.query('''
      SELECT * FROM clientes 
      WHERE ativo = true 
      ORDER BY nome
    ''');
    
    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }
  
  /// Listar clientes com dívidas
  Future<List<ClienteModel>> listarComDividas() async {
    final result = await _db.query('''
      SELECT * FROM v_clientes_dividas
      WHERE total_dividas > 0
      ORDER BY total_devendo DESC
    ''');
    
    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }
  
  /// Listar devedores (apenas com dívidas pendentes)
  Future<List<ClienteModel>> listarDevedores() async {
    final result = await _db.query('''
      SELECT * FROM v_devedores
      ORDER BY total_devendo DESC
    ''');
    
    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }
  
  /// Buscar por ID
  Future<ClienteModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM clientes WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return ClienteModel.fromMap(result.first);
  }
  
  /// Pesquisar por nome ou contacto
  Future<List<ClienteModel>> pesquisar(String termo) async {
    final result = await _db.query('''
      SELECT * FROM clientes 
      WHERE ativo = true 
        AND (LOWER(nome) LIKE LOWER(@termo) OR contacto LIKE @termo)
      ORDER BY nome
      LIMIT 50
    ''', parameters: {'termo': '%$termo%'});
    
    return result.map((map) => ClienteModel.fromMap(map)).toList();
  }
  
  /// Inserir novo cliente
  Future<int> inserir(ClienteModel cliente) async {
    return await _db.insert('''
      INSERT INTO clientes (nome, contacto, contacto2, email, endereco, bairro, cidade, nuit, observacoes, ativo)
      VALUES (@nome, @contacto, @contacto2, @email, @endereco, @bairro, @cidade, @nuit, @observacoes, @ativo)
    ''', parameters: cliente.toMap());
  }
  
  /// Atualizar cliente
  Future<void> atualizar(int id, ClienteModel cliente) async {
    await _db.execute('''
      UPDATE clientes 
      SET nome = @nome,
          contacto = @contacto,
          contacto2 = @contacto2,
          email = @email,
          endereco = @endereco,
          bairro = @bairro,
          cidade = @cidade,
          nuit = @nuit,
          observacoes = @observacoes,
          ativo = @ativo,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = @id
    ''', parameters: {
      ...cliente.toMap(),
      'id': id,
    });
  }
  
  /// Deletar (soft delete)
  Future<void> deletar(int id) async {
    await _db.execute('''
      UPDATE clientes SET ativo = false WHERE id = @id
    ''', parameters: {'id': id});
  }
}
```

### 2. Dívida Repository

Crie `lib/app/data/repositories/divida_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/divida_model.dart';
import '../models/pagamento_divida_model.dart';

class DividaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  /// Criar dívida a partir de venda
  Future<int> criar(DividaModel divida) async {
    return await _db.insert('''
      INSERT INTO dividas (cliente_id, venda_id, valor_total, valor_pago, valor_restante, observacoes)
      VALUES (@cliente_id, @venda_id, @valor_total, @valor_pago, @valor_restante, @observacoes)
    ''', parameters: divida.toMap());
  }
  
  /// Listar dívidas de um cliente
  Future<List<DividaModel>> listarPorCliente(int clienteId, {String? status}) async {
    String sql = '''
      SELECT * FROM v_dividas_completo
      WHERE cliente_id = @cliente_id
    ''';
    
    Map<String, dynamic> params = {'cliente_id': clienteId};
    
    if (status != null) {
      sql += ' AND status = @status';
      params['status'] = status;
    }
    
    sql += ' ORDER BY data_divida DESC';
    
    final result = await _db.query(sql, parameters: params);
    return result.map((map) => DividaModel.fromMap(map)).toList();
  }
  
  /// Listar todas dívidas pendentes
  Future<List<DividaModel>> listarPendentes() async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo
      WHERE status != 'PAGO'
      ORDER BY data_divida DESC
    ''');
    
    return result.map((map) => DividaModel.fromMap(map)).toList();
  }
  
  /// Buscar por ID
  Future<DividaModel?> buscarPorId(int id) async {
    final result = await _db.query('''
      SELECT * FROM v_dividas_completo WHERE id = @id
    ''', parameters: {'id': id});
    
    if (result.isEmpty) return null;
    return DividaModel.fromMap(result.first);
  }
  
  /// Registrar pagamento de dívida
  Future<void> registrarPagamento(PagamentoDividaModel pagamento) async {
    await _db.execute('''
      SELECT registrar_pagamento_divida(
        @divida_id,
        @valor,
        @forma_pagamento_id,
        @observacoes,
        @usuario
      )
    ''', parameters: pagamento.toMap());
  }
  
  /// Listar pagamentos de uma dívida
  Future<List<PagamentoDividaModel>> listarPagamentos(int dividaId) async {
    final result = await _db.query('''
      SELECT pd.*, fp.nome as forma_pagamento_nome
      FROM pagamentos_divida pd
      LEFT JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
      WHERE pd.divida_id = @divida_id
      ORDER BY pd.data_pagamento DESC
    ''', parameters: {'divida_id': dividaId});
    
    return result.map((map) => PagamentoDividaModel.fromMap(map)).toList();
  }
  
  /// Total de dívidas de um cliente
  Future<double> totalDividasCliente(int clienteId) async {
    final result = await _db.query('''
      SELECT COALESCE(SUM(valor_restante), 0) as total
      FROM dividas
      WHERE cliente_id = @cliente_id AND status != 'PAGO'
    ''', parameters: {'cliente_id': clienteId});
    
    if (result.isEmpty) return 0;
    return double.parse(result.first['total'].toString());
  }
}
```

### 3. Despesa Repository

Crie `lib/app/data/repositories/despesa_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/despesa_model.dart';

class DespesaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  /// Listar todas despesas
  Future<List<DespesaModel>> listarTodas({DateTime? dataInicio, DateTime? dataFim}) async {
    String sql = '''
      SELECT d.*, fp.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento fp ON d.forma_pagamento_id = fp.id
      WHERE 1=1
    ''';
    
    Map<String, dynamic> params = {};
    
    if (dataInicio != null) {
      sql += ' AND d.data_despesa >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }
    
    if (dataFim != null) {
      sql += ' AND d.data_despesa <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }
    
    sql += ' ORDER BY d.data_despesa DESC';
    
    final result = await _db.query(sql, parameters: params);
    return result.map((map) => DespesaModel.fromMap(map)).toList();
  }
  
  /// Listar por categoria
  Future<List<DespesaModel>> listarPorCategoria(String categoria) async {
    final result = await _db.query('''
      SELECT d.*, fp.nome as forma_pagamento_nome
      FROM despesas d
      LEFT JOIN formas_pagamento fp ON d.forma_pagamento_id = fp.id
      WHERE d.categoria = @categoria
      ORDER BY d.data_despesa DESC
    ''', parameters: {'categoria': categoria});
    
    return result.map((map) => DespesaModel.fromMap(map)).toList();
  }
  
  /// Inserir despesa
  Future<int> inserir(DespesaModel despesa) async {
    return await _db.insert('''
      INSERT INTO despesas (descricao, valor, categoria, forma_pagamento_id, observacoes, usuario)
      VALUES (@descricao, @valor, @categoria, @forma_pagamento_id, @observacoes, @usuario)
    ''', parameters: despesa.toMap());
  }
  
  /// Atualizar despesa
  Future<void> atualizar(int id, DespesaModel despesa) async {
    await _db.execute('''
      UPDATE despesas 
      SET descricao = @descricao,
          valor = @valor,
          categoria = @categoria,
          forma_pagamento_id = @forma_pagamento_id,
          observacoes = @observacoes
      WHERE id = @id
    ''', parameters: {
      ...despesa.toMap(),
      'id': id,
    });
  }
  
  /// Deletar despesa
  Future<void> deletar(int id) async {
    await _db.execute('''
      DELETE FROM despesas WHERE id = @id
    ''', parameters: {'id': id});
  }
  
  /// Total de despesas por período
  Future<double> totalPorPeriodo({DateTime? dataInicio, DateTime? dataFim}) async {
    String sql = 'SELECT COALESCE(SUM(valor), 0) as total FROM despesas WHERE 1=1';
    Map<String, dynamic> params = {};
    
    if (dataInicio != null) {
      sql += ' AND data_despesa >= @data_inicio';
      params['data_inicio'] = dataInicio.toIso8601String();
    }
    
    if (dataFim != null) {
      sql += ' AND data_despesa <= @data_fim';
      params['data_fim'] = dataFim.toIso8601String();
    }
    
    final result = await _db.query(sql, parameters: params);
    if (result.isEmpty) return 0;
    return double.parse(result.first['total'].toString());
  }
}
```

### ✅ Checkpoint Fase 3

- [ ] ClienteRepository criado
- [ ] DividaRepository criado
- [ ] DespesaRepository criado
- [ ] Métodos completos
- [ ] Sem erros

---

## ⌨️ FASE 4: Teclado Virtual de Pesquisa

### 1. Widget de Teclado Virtual

Crie `lib/app/modules/vendas/widgets/teclado_virtual.dart`:

```dart
import 'package:flutter/material.dart';

class TecladoVirtual extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearch;

  const TecladoVirtual({
    Key? key,
    required this.controller,
    this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha 1
          Row(
            children: [
              _buildKey('1'), _buildKey('2'), _buildKey('3'),
              _buildKey('4'), _buildKey('5'), _buildKey('6'),
              _buildKey('7'), _buildKey('8'), _buildKey('9'),
              _buildKey('0'),
            ],
          ),
          SizedBox(height: 8),
          // Linha 2
          Row(
            children: [
              _buildKey('Q'), _buildKey('W'), _buildKey('E'),
              _buildKey('R'), _buildKey('T'), _buildKey('Y'),
              _buildKey('U'), _buildKey('I'), _buildKey('O'),
              _buildKey('P'),
            ],
          ),
          SizedBox(height: 8),
          // Linha 3
          Row(
            children: [
              _buildKey('A'), _buildKey('S'), _buildKey('D'),
              _buildKey('F'), _buildKey('G'), _buildKey('H'),
              _buildKey('J'), _buildKey('K'), _buildKey('L'),
            ],
          ),
          SizedBox(height: 8),
          // Linha 4
          Row(
            children: [
              _buildKey('Z'), _buildKey('X'), _buildKey('C'),
              _buildKey('V'), _buildKey('B'), _buildKey('N'),
              _buildKey('M'),
              _buildSpecialKey(
                Icons.backspace,
                () {
                  if (controller.text.isNotEmpty) {
                    controller.text = controller.text.substring(
                      0,
                      controller.text.length - 1,
                    );
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          // Linha 5 - Espaço e buscar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildWideKey(
                  'ESPAÇO',
                  () => controller.text += ' ',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildSearchKey(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: () => controller.text += key,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: Text(
            key,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }

  Widget _buildWideKey(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSearchKey() {
    return ElevatedButton(
      onPressed: onSearch,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search),
          SizedBox(width: 4),
          Text(
            'BUSCAR',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

### 2. Modal de Pesquisa de Cliente

Crie `lib/app/modules/vendas/widgets/pesquisa_cliente_modal.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/cliente_model.dart';
import '../../../data/repositories/cliente_repository.dart';
import 'teclado_virtual.dart';

class PesquisaClienteModal extends StatefulWidget {
  final Function(ClienteModel) onClienteSelecionado;

  const PesquisaClienteModal({
    Key? key,
    required this.onClienteSelecionado,
  }) : super(key: key);

  @override
  State<PesquisaClienteModal> createState() => _PesquisaClienteModalState();
}

class _PesquisaClienteModalState extends State<PesquisaClienteModal> {
  final TextEditingController _searchController = TextEditingController();
  final ClienteRepository _clienteRepo = ClienteRepository();
  final RxList<ClienteModel> resultados = <ClienteModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _carregarTodos();
  }

  Future<void> _carregarTodos() async {
    isLoading.value = true;
    try {
      resultados.value = await _clienteRepo.listarTodos();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar clientes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _pesquisar() async {
    if (_searchController.text.trim().isEmpty) {
      await _carregarTodos();
      return;
    }

    isLoading.value = true;
    try {
      resultados.value = await _clienteRepo.pesquisar(_searchController.text);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao pesquisar: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: EdgeInsets.all(16),
              color: Get.theme.primaryColor,
              child: Row(
                children: [
                  Icon(Icons.person_search, color: Colors.white, size: 30),
                  SizedBox(width: 12),
                  Text(
                    'PESQUISAR CLIENTE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            
            // Campo de pesquisa
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Digite nome ou contacto...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                readOnly: true, // Usar apenas teclado virtual
              ),
            ),
            
            // Lista de resultados
            Expanded(
              child: Obx(() {
                if (isLoading.value) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (resultados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum cliente encontrado',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: resultados.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, index) {
                    final cliente = resultados[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Get.theme.primaryColor,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        cliente.nome,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cliente.contacto != null)
                            Text('Tel: ${cliente.contacto}'),
                          if (cliente.totalDevendo != null && 
                              cliente.totalDevendo! > 0)
                            Text(
                              'Dívida: ${cliente.totalDevendo!.toStringAsFixed(2)} MT',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Get.back();
                        widget.onClienteSelecionado(cliente);
                      },
                    );
                  },
                );
              }),
            ),
            
            // Teclado Virtual
            TecladoVirtual(
              controller: _searchController,
              onSearch: _pesquisar,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
```

### ✅ Checkpoint Fase 4

- [ ] TecladoVirtual criado
- [ ] PesquisaClienteModal criado
- [ ] Teclado funciona
- [ ] Pesquisa funciona

---

## 👥 FASE 5: Admin - CRUD Clientes

### 1. Atualizar Admin Controller

Edite `lib/app/modules/admin/controllers/admin_controller.dart`:

Adicione os imports e variáveis:

```dart
import '../../../data/models/cliente_model.dart';
import '../../../data/repositories/cliente_repository.dart';

final ClienteRepository _clienteRepo = ClienteRepository();
final clientes = <ClienteModel>[].obs;
```

No método `carregarDados()`:

```dart
clientes.value = await _clienteRepo.listarTodos();
```

Adicione os métodos:

```dart
// ===== CLIENTE =====
Future<void> adicionarCliente(ClienteModel cliente) async {
  try {
    await _clienteRepo.inserir(cliente);
    await carregarDados();
    Get.back();
    Get.snackbar('Sucesso', 'Cliente adicionado!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao adicionar: $e');
  }
}

Future<void> editarCliente(int id, ClienteModel cliente) async {
  try {
    await _clienteRepo.atualizar(id, cliente);
    await carregarDados();
    Get.back();
    Get.snackbar('Sucesso', 'Cliente atualizado!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao atualizar: $e');
  }
}

Future<void> deletarCliente(int id) async {
  try {
    await _clienteRepo.deletar(id);
    await carregarDados();
    Get.snackbar('Sucesso', 'Cliente removido!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao remover: $e');
  }
}
```

### 2. Atualizar Admin Page - Adicionar ao Drawer

Edite `lib/app/modules/admin/admin_page.dart`:

No drawer, adicione:

```dart
_buildMenuItem(6, Icons.people, 'Clientes'),
_buildMenuItem(7, Icons.money_off, 'Despesas'),
```

No método `_getTitulo()`:

```dart
case 6: return 'CLIENTES';
case 7: return 'DESPESAS';
```

No método `_getBody()`:

```dart
case 6: return ClientesTab();
case 7: return DespesasTab();
```

### 3. Clientes Tab

Crie `lib/app/modules/admin/views/clientes_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/cliente_model.dart';
import '../controllers/admin_controller.dart';

class ClientesTab extends GetView<AdminController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.clientes.isEmpty) {
          return Center(child: Text('Nenhum cliente cadastrado'));
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: controller.clientes.length,
          itemBuilder: (context, index) {
            final cliente = controller.clientes[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Get.theme.primaryColor,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  cliente.nome,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cliente.contacto != null)
                      Text('Tel: ${cliente.contacto}'),
                    if (cliente.email != null)
                      Text('Email: ${cliente.email}'),
                    if (cliente.cidade != null)
                      Text('Cidade: ${cliente.cidade}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarDialog(cliente),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmarDelete(cliente.id!),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  void _mostrarDialog(ClienteModel? cliente) {
    final nomeController = TextEditingController(text: cliente?.nome ?? '');
    final contactoController = TextEditingController(text: cliente?.contacto ?? '');
    final contacto2Controller = TextEditingController(text: cliente?.contacto2 ?? '');
    final emailController = TextEditingController(text: cliente?.email ?? '');
    final enderecoController = TextEditingController(text: cliente?.endereco ?? '');
    final bairroController = TextEditingController(text: cliente?.bairro ?? '');
    final cidadeController = TextEditingController(text: cliente?.cidade ?? '');
    final nuitController = TextEditingController(text: cliente?.nuit ?? '');
    final observacoesController = TextEditingController(text: cliente?.observacoes ?? '');
    
    Get.dialog(
      AlertDialog(
        title: Text(cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        content: SingleChildScrollView(
          child: Container(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome *',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: contactoController,
                        decoration: InputDecoration(
                          labelText: 'Contacto',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: contacto2Controller,
                        decoration: InputDecoration(
                          labelText: 'Contacto 2',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: enderecoController,
                  decoration: InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bairroController,
                        decoration: InputDecoration(
                          labelText: 'Bairro',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cidadeController,
                        decoration: InputDecoration(
                          labelText: 'Cidade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                TextField(
                  controller: nuitController,
                  decoration: InputDecoration(
                    labelText: 'NUIT',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  controller: observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isEmpty) {
                Get.snackbar('Erro', 'Nome é obrigatório');
                return;
              }
              
              final novoCliente = ClienteModel(
                nome: nomeController.text,
                contacto: contactoController.text,
                contacto2: contacto2Controller.text,
                email: emailController.text,
                endereco: enderecoController.text,
                bairro: bairroController.text,
                cidade: cidadeController.text,
                nuit: nuitController.text,
                observacoes: observacoesController.text,
              );
              
              if (cliente == null) {
                controller.adicionarCliente(novoCliente);
              } else {
                controller.editarCliente(cliente.id!, novoCliente);
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }
  
  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja realmente remover este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarCliente(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
```

### ✅ Checkpoint Fase 5

- [ ] Clientes tab criada
- [ ] CRUD completo funciona
- [ ] Dialog de edição funciona
- [ ] Consegue cadastrar cliente

---

## 💸 FASE 6: Admin - CRUD Despesas

### 1. Atualizar Admin Controller

Adicione no controller:

```dart
import '../../../data/models/despesa_model.dart';
import '../../../data/repositories/despesa_repository.dart';

final DespesaRepository _despesaRepo = DespesaRepository();
final despesas = <DespesaModel>[].obs;
```

No `carregarDados()`:

```dart
despesas.value = await _despesaRepo.listarTodas();
```

Adicione os métodos:

```dart
// ===== DESPESA =====
Future<void> adicionarDespesa(DespesaModel despesa) async {
  try {
    await _despesaRepo.inserir(despesa);
    await carregarDados();
    Get.back();
    Get.snackbar('Sucesso', 'Despesa registrada!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao adicionar: $e');
  }
}

Future<void> editarDespesa(int id, DespesaModel despesa) async {
  try {
    await _despesaRepo.atualizar(id, despesa);
    await carregarDados();
    Get.back();
    Get.snackbar('Sucesso', 'Despesa atualizada!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao atualizar: $e');
  }
}

Future<void> deletarDespesa(int id) async {
  try {
    await _despesaRepo.deletar(id);
    await carregarDados();
    Get.snackbar('Sucesso', 'Despesa removida!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao remover: $e');
  }
}
```

### 2. Despesas Tab

Crie `lib/app/modules/admin/views/despesas_tab.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/formatters.dart';
import '../../../data/models/despesa_model.dart';
import '../controllers/admin_controller.dart';

class DespesasTab extends GetView<AdminController> {
  final List<String> categorias = [
    'OPERACIONAL',
    'UTILIDADES',
    'PESSOAL',
    'MARKETING',
    'MANUTENCAO',
    'OUTROS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (controller.despesas.isEmpty) {
          return Center(child: Text('Nenhuma despesa registrada'));
        }
        
        // Calcular total
        final total = controller.despesas.fold<double>(
          0, 
          (sum, d) => sum + d.valor,
        );
        
        return Column(
          children: [
            // Card de resumo
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.money_off, size: 40, color: Colors.red),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total de Despesas',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        Formatters.formatarMoeda(total),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.despesas.length,
                itemBuilder: (context, index) {
                  final despesa = controller.despesas[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getCorCategoria(despesa.categoria),
                        child: Icon(Icons.money_off, color: Colors.white),
                      ),
                      title: Text(
                        despesa.descricao,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Categoria: ${despesa.categoria ?? "N/A"}'),
                          Text(
                            Formatters.formatarData(despesa.dataDespesa),
                            style: TextStyle(fontSize: 12),
                          ),
                          if (despesa.formaPagamentoNome != null)
                            Text('Pago via: ${despesa.formaPagamentoNome}'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatarMoeda(despesa.valor),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.red,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _mostrarDialog(despesa),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _confirmarDelete(despesa.id!),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialog(null),
        child: Icon(Icons.add),
      ),
    );
  }
  
  Color _getCorCategoria(String? categoria) {
    switch (categoria) {
      case 'OPERACIONAL': return Colors.blue;
      case 'UTILIDADES': return Colors.orange;
      case 'PESSOAL': return Colors.green;
      case 'MARKETING': return Colors.purple;
      case 'MANUTENCAO': return Colors.brown;
      default: return Colors.grey;
    }
  }
  
  void _mostrarDialog(DespesaModel? despesa) {
    final descricaoController = TextEditingController(text: despesa?.descricao ?? '');
    final valorController = TextEditingController(
      text: despesa?.valor.toString() ?? '',
    );
    final observacoesController = TextEditingController(text: despesa?.observacoes ?? '');
    
    String? categoriaSelecionada = despesa?.categoria ?? categorias.first;
    int? formaPagamentoId = despesa?.formaPagamentoId;
    
    Get.dialog(
      AlertDialog(
        title: Text(despesa == null ? 'Nova Despesa' : 'Editar Despesa'),
        content: SingleChildScrollView(
          child: Container(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 15),
                TextField(
                  controller: valorController,
                  decoration: InputDecoration(
                    labelText: 'Valor *',
                    border: OutlineInputBorder(),
                    prefixText: 'MT ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: categoriaSelecionada,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  items: categorias.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    categoriaSelecionada = value;
                  },
                ),
                SizedBox(height: 15),
                Obx(() => DropdownButtonFormField<int>(
                  value: formaPagamentoId,
                  decoration: InputDecoration(
                    labelText: 'Forma de Pagamento',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.formasPagamento.map((forma) {
                    return DropdownMenuItem<int>(
                      value: forma.id,
                      child: Text(forma.nome),
                    );
                  }).toList(),
                  onChanged: (value) {
                    formaPagamentoId = value;
                  },
                )),
                SizedBox(height: 15),
                TextField(
                  controller: observacoesController,
                  decoration: InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (descricaoController.text.isEmpty || valorController.text.isEmpty) {
                Get.snackbar('Erro', 'Preencha descrição e valor');
                return;
              }
              
              final novaDespesa = DespesaModel(
                descricao: descricaoController.text,
                valor: double.parse(valorController.text),
                categoria: categoriaSelecionada,
                dataDespesa: DateTime.now(),
                formaPagamentoId: formaPagamentoId,
                observacoes: observacoesController.text,
                usuario: 'Admin', // TODO: pegar usuário logado
              );
              
              if (despesa == null) {
                controller.adicionarDespesa(novaDespesa);
              } else {
                controller.editarDespesa(despesa.id!, novaDespesa);
              }
            },
            child: Text('SALVAR'),
          ),
        ],
      ),
    );
  }
  
  void _confirmarDelete(int id) {
    Get.dialog(
      AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja realmente remover esta despesa?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.deletarDespesa(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('REMOVER'),
          ),
        ],
      ),
    );
  }
}
```

### ✅ Checkpoint Fase 6

- [ ] DespesasTab criada
- [ ] CRUD completo funciona
- [ ] Mostra total de despesas
- [ ] Categorias funcionam

---

## 🛒 FASE 7: Vendas - Sistema de Dívidas

### 1. Atualizar Vendas Controller

Edite `lib/app/modules/vendas/controllers/vendas_controller.dart`:

Adicione imports:

```dart
import '../../../data/models/cliente_model.dart';
import '../../../data/models/divida_model.dart';
import '../../../data/repositories/cliente_repository.dart';
import '../../../data/repositories/divida_repository.dart';
import '../widgets/pesquisa_cliente_modal.dart';
```

Adicione variáveis:

```dart
final ClienteRepository _clienteRepo = ClienteRepository();
final DividaRepository _dividaRepo = DividaRepository();
final clienteSelecionado = Rxn<ClienteModel>();
final isModoDiv ida = false.obs;
```

Adicione método para abrir pesquisa de cliente:

```dart
void abrirPesquisaCliente() {
  Get.dialog(
    PesquisaClienteModal(
      onClienteSelecionado: (cliente) {
        clienteSelecionado.value = cliente;
        isMododivida.value = true;
        Get.snackbar(
          'Cliente Selecionado',
          '${cliente.nome} - Venda será registrada como dívida',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      },
    ),
  );
}

void cancelarDivida() {
  clienteSelecionado.value = null;
  isMododivida.value = false;
}
```

Modifique o método `finalizarVenda()`:

```dart
Future<void> finalizarVenda() async {
  if (carrinho.isEmpty) {
    Get.snackbar('Erro', 'Carrinho vazio');
    return;
  }
  
  // Se é modo dívida, não pede forma de pagamento
  if (isMododivida.value) {
    await _processarVendaComoDivida();
    return;
  }
  
  // Resetar forma de pagamento
  formaPagamentoSelecionada.value = null;
  
  // Mostrar dialog de opções: Pagamento ou Dívida
  await Get.dialog(
    AlertDialog(
      title: Text('Finalizar Venda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Escolha uma opção:'),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              _mostrarFormasPagamento();
            },
            icon: Icon(Icons.payment),
            label: Text('FINALIZAR PAGAMENTO'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.green,
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              abrirPesquisaCliente();
            },
            icon: Icon(Icons.person),
            label: Text('DÍVIDA'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.orange,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('CANCELAR'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

Future<void> _mostrarFormasPagamento() async {
  await Get.dialog(
    AlertDialog(
      title: Text('Forma de Pagamento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Selecione a forma de pagamento:'),
          SizedBox(height: 20),
          ...formasPagamento.map((forma) {
            return Obx(() => RadioListTile<FormaPagamentoModel>(
              title: Text(forma.nome),
              subtitle: Text(forma.descricao ?? ''),
              value: forma,
              groupValue: formaPagamentoSelecionada.value,
              onChanged: (value) {
                formaPagamentoSelecionada.value = value;
              },
            ));
          }).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            if (formaPagamentoSelecionada.value == null) {
              Get.snackbar('Erro', 'Selecione uma forma de pagamento');
              return;
            }
            Get.back();
            _processarVenda();
          },
          child: Text('CONFIRMAR'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

Future<void> _processarVendaComoDivida() async {
  if (clienteSelecionado.value == null) {
    Get.snackbar('Erro', 'Nenhum cliente selecionado');
    return;
  }
  
  try {
    // Gerar número da venda
    final numero = 'VD${DateTime.now().millisecondsSinceEpoch}';
    
    // Criar venda
    final venda = VendaModel(
      numero: numero,
      total: totalCarrinho,
      dataVenda: DateTime.now(),
      terminal: 'CAIXA-01',
      clienteId: clienteSelecionado.value!.id,
      tipoVenda: 'DIVIDA',
    );
    
    // Criar itens
    final itens = carrinho.map((item) {
      return ItemVendaModel(
        produtoId: item.produto.id!,
        quantidade: item.quantidade,
        precoUnitario: item.produto.preco,
        subtotal: item.subtotal,
        produtoNome: item.produto.nome,
      );
    }).toList();
    
    // Registrar venda no banco
    final vendaId = await _vendaRepo.registrarVenda(venda, itens);
    
    // Criar dívida
    final divida = DividaModel(
      clienteId: clienteSelecionado.value!.id!,
      vendaId: vendaId,
      valorTotal: totalCarrinho,
      valorPago: 0,
      valorRestante: totalCarrinho,
      dataDivida: DateTime.now(),
    );
    
    await _dividaRepo.criar(divida);
    
    Get.snackbar(
      'Sucesso',
      'Dívida registrada para ${clienteSelecionado.value!.nome}',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
    );
    
    // Limpar tudo
    carrinho.clear();
    clienteSelecionado.value = null;
    isMododivida.value = false;
    
    await carregarDados();
    
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao registrar dívida: $e');
  }
}
```

### 2. Atualizar UI de Vendas - Mostrar Cliente Selecionado

Edite `lib/app/modules/vendas/vendas_page.dart`:

No método `_buildHeaderCarrinho()`, adicione antes do Row:

```dart
Widget _buildHeaderCarrinho() {
  return Column(
    children: [
      // Cliente selecionado (se houver)
      Obx(() {
        if (controller.clienteSelecionado.value != null) {
          return Container(
            padding: EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÍVIDA PARA:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      Text(
                        controller.clienteSelecionado.value!.nome,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: controller.cancelarDivida,
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      }),
      
      // Header normal
      Container(
        padding: EdgeInsets.all(16),
        color: Get.theme.primaryColor,
        child: Row(
          children: [
            Icon(Icons.shopping_cart, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'CARRINHO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            Obx(() => Text(
              '${controller.carrinho.length} itens',
              style: TextStyle(color: Colors.white),
            )),
          ],
        ),
      ),
    ],
  );
}
```

### ✅ Checkpoint Fase 7

- [ ] Dialog "Finalizar Pagamento" ou "Dívida" funciona
- [ ] Pesquisa de cliente abre
- [ ] Teclado virtual funciona
- [ ] Consegue selecionar cliente
- [ ] Dívida registra no banco
- [ ] Mostra cliente selecionado

---

## 📋 FASE 8: Tela de Devedores

### 1. Criar Página de Devedores

Crie `lib/app/modules/devedores/devedores_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/cliente_model.dart';
import '../../data/repositories/cliente_repository.dart';
import 'detalhes_divida_page.dart';

class DevedoresPage extends StatefulWidget {
  @override
  State<DevedoresPage> createState() => _DevedoresPageState();
}

class _DevedoresPageState extends State<DevedoresPage> {
  final ClienteRepository _clienteRepo = ClienteRepository();
  final RxList<ClienteModel> devedores = <ClienteModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _carregarDevedores();
  }

  Future<void> _carregarDevedores() async {
    isLoading.value = true;
    try {
      devedores.value = await _clienteRepo.listarDevedores();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar devedores: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DEVEDORES'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarDevedores,
          ),
        ],
      ),
      body: Obx(() {
        if (isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (devedores.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 100, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  'Nenhum devedor!',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
                Text(
                  'Todas as dívidas foram pagas',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        // Calcular total
        final totalGeral = devedores.fold<double>(
          0, 
          (sum, d) => sum + (d.totalDevendo ?? 0),
        );
        
        return Column(
          children: [
            // Card de resumo
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, size: 40, color: Colors.red),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total em Dívidas',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      Text(
                        Formatters.formatarMoeda(totalGeral),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        '${devedores.length} ${devedores.length == 1 ? "devedor" : "devedores"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de devedores
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: devedores.length,
                itemBuilder: (context, index) {
                  final devedor = devedores[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        devedor.nome,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (devedor.contacto != null)
                            Text('Tel: ${devedor.contacto}'),
                          Text(
                            '${devedor.totalDividas} ${devedor.totalDividas == 1 ? "dívida" : "dívidas"}',
                          ),
                          if (devedor.ultimaDivida != null)
                            Text(
                              'Última: ${Formatters.formatarDataCurta(devedor.ultimaDivida!)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.formatarMoeda(devedor.totalDevendo ?? 0),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.red,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () async {
                        await Get.to(() => DetalhesDividaPage(cliente: devedor));
                        _carregarDevedores(); // Atualizar após voltar
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
```

### 2. Adicionar Botão na Tela de Vendas

Edite `lib/app/modules/vendas/vendas_page.dart`:

No AppBar, adicione:

```dart
appBar: AppBar(
  title: Text('VENDAS'),
  actions: [
    IconButton(
      icon: Icon(Icons.people),
      tooltip: 'Devedores',
      onPressed: () => Get.to(() => DevedoresPage()),
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: controller.carregarDados,
    ),
  ],
),
```

### 3. Adicionar Rota

Edite `lib/app/routes/app_routes.dart`:

```dart
static const devedores = '/devedores';
```

Edite `lib/app/routes/app_pages.dart`:

```dart
import '../modules/devedores/devedores_page.dart';

GetPage(
  name: AppRoutes.devedores,
  page: () => DevedoresPage(),
),
```

### ✅ Checkpoint Fase 8

- [ ] Tela de devedores criada
- [ ] Lista devedores ordenados
- [ ] Mostra total em dívidas
- [ ] Botão na tela de vendas funciona

---

## 💰 FASE 9: Pagamento de Dívidas

### 1. Página de Detalhes da Dívida

Crie `lib/app/modules/devedores/detalhes_divida_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/cliente_model.dart';
import '../../data/models/divida_model.dart';
import '../../data/models/pagamento_divida_model.dart';
import '../../data/models/forma_pagamento_model.dart';
import '../../data/repositories/divida_repository.dart';
import '../../data/repositories/forma_pagamento_repository.dart';

class DetalhesDividaPage extends StatefulWidget {
  final ClienteModel cliente;

  const DetalhesDividaPage({Key? key, required this.cliente}) : super(key: key);

  @override
  State<DetalhesDividaPage> createState() => _DetalhesDividaPageState();
}

class _DetalhesDividaPageState extends State<DetalhesDividaPage> {
  final DividaRepository _dividaRepo = DividaRepository();
  final FormaPagamentoRepository _formaPagamentoRepo = FormaPagamentoRepository();
  
  final RxList<DividaModel> dividas = <DividaModel>[].obs;
  final RxList<FormaPagamentoModel> formasPagamento = <FormaPagamentoModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    isLoading.value = true;
    try {
      dividas.value = await _dividaRepo.listarPorCliente(
        widget.cliente.id!,
        status: null, // Todas
      );
      formasPagamento.value = await _formaPagamentoRepo.listarTodas();
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao carregar dívidas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dívidas - ${widget.cliente.nome}'),
      ),
      body: Obx(() {
        if (isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (dividas.isEmpty) {
          return Center(
            child: Text('Nenhuma dívida encontrada'),
          );
        }
        
        final totalDevendo = dividas
            .where((d) => d.status != 'PAGO')
            .fold<double>(0, (sum, d) => sum + d.valorRestante);
        
        return Column(
          children: [
            // Card info do cliente
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: totalDevendo > 0 ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: totalDevendo > 0 ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: totalDevendo > 0 ? Colors.red : Colors.green,
                        child: Icon(Icons.person, color: Colors.white, size: 30),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cliente.nome,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.cliente.contacto != null)
                              Text('Tel: ${widget.cliente.contacto}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCard(
                        'Total Devendo',
                        Formatters.formatarMoeda(totalDevendo),
                        Colors.red,
                      ),
                      _buildInfoCard(
                        'Dívidas',
                        dividas.where((d) => d.status != 'PAGO').length.toString(),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de dívidas
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: dividas.length,
                itemBuilder: (context, index) {
                  final divida = dividas[index];
                  return _buildDividaCard(divida);
                },
              ),
            ),
          ],
        );
      }),
    );
  }
  
  Widget _buildInfoCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDividaCard(DividaModel divida) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getCorStatus(divida.status),
          child: Icon(
            _getIconStatus(divida.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          'Dívida #${divida.id}',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${Formatters.formatarDataCurta(divida.dataDivida)} - ${divida.status}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatarMoeda(divida.valorRestante),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            Text(
              'de ${Formatters.formatarMoeda(divida.valorTotal)}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Total:', divida.valorTotal),
                _buildInfoRow('Pago:', divida.valorPago),
                _buildInfoRow('Restante:', divida.valorRestante),
                if (divida.vendaNumero != null)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Venda: ${divida.vendaNumero}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                if (divida.status != 'PAGO')
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _mostrarDialogPagamento(divida),
                        icon: Icon(Icons.payment),
                        label: Text('REGISTRAR PAGAMENTO'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
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
  
  Widget _buildInfoRow(String label, double valor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            Formatters.formatarMoeda(valor),
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Color _getCorStatus(String status) {
    switch (status) {
      case 'PAGO': return Colors.green;
      case 'PARCIAL': return Colors.orange;
      default: return Colors.red;
    }
  }
  
  IconData _getIconStatus(String status) {
    switch (status) {
      case 'PAGO': return Icons.check_circle;
      case 'PARCIAL': return Icons.pending;
      default: return Icons.warning;
    }
  }
  
  void _mostrarDialogPagamento(DividaModel divida) {
    final valorController = TextEditingController();
    final observacoesController = TextEditingController();
    int? formaPagamentoId;
    
    Get.dialog(
      AlertDialog(
        title: Text('Registrar Pagamento'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valor restante: ${Formatters.formatarMoeda(divida.valorRestante)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: valorController,
                decoration: InputDecoration(
                  labelText: 'Valor a Pagar *',
                  border: OutlineInputBorder(),
                  prefixText: 'MT ',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Forma de Pagamento *',
                  border: OutlineInputBorder(),
                ),
                items: formasPagamento.map((forma) {
                  return DropdownMenuItem<int>(
                    value: forma.id,
                    child: Text(forma.nome),
                  );
                }).toList(),
                onChanged: (value) {
                  formaPagamentoId = value;
                },
              ),
              SizedBox(height: 15),
              TextField(
                controller: observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
            onPressed: () async {
              if (valorController.text.isEmpty || formaPagamentoId == null) {
                Get.snackbar('Erro', 'Preencha valor e forma de pagamento');
                return;
              }
              
              final valor = double.tryParse(valorController.text);
              if (valor == null || valor <= 0) {
                Get.snackbar('Erro', 'Valor inválido');
                return;
              }
              
              if (valor > divida.valorRestante) {
                Get.snackbar('Erro', 'Valor excede o restante da dívida');
                return;
              }
              
              try {
                final pagamento = PagamentoDividaModel(
                  dividaId: divida.id!,
                  valor: valor,
                  formaPagamentoId: formaPagamentoId,
                  dataPagamento: DateTime.now(),
                  observacoes: observacoesController.text,
                  usuario: 'Admin', // TODO: usuário logado
                );
                
                await _dividaRepo.registrarPagamento(pagamento);
                
                Get.back();
                Get.snackbar(
                  'Sucesso',
                  'Pagamento registrado!',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
                
                await _carregarDados();
                
              } catch (e) {
                Get.snackbar('Erro', 'Erro ao registrar pagamento: $e');
              }
            },
            child: Text('REGISTRAR'),
          ),
        ],
      ),
    );
  }
}
```

### ✅ Checkpoint Fase 9

- [ ] Tela de detalhes da dívida criada
- [ ] Lista dívidas do cliente
- [ ] Mostra total devendo
- [ ] Dialog de pagamento funciona
- [ ] Consegue registrar pagamento
- [ ] Status atualiza automaticamente

---

## 🎉 FASE 10: Integração Completa e Testes

### 1. Checklist Final

#### **Banco de Dados**
- [ ] Tabelas criadas (clientes, dividas, pagamentos_divida, despesas)
- [ ] Views criadas
- [ ] Trigger funcionando
- [ ] Function de pagamento funcionando

#### **Models**
- [ ] ClienteModel
- [ ] DividaModel
- [ ] PagamentoDividaModel
- [ ] DespesaModel

#### **Repositories**
- [ ] ClienteRepository
- [ ] DividaRepository
- [ ] DespesaRepository

#### **Admin**
- [ ] CRUD Clientes funciona
- [ ] CRUD Despesas funciona
- [ ] Menu drawer atualizado

#### **Vendas**
- [ ] Opção "Dívida" aparece
- [ ] Teclado virtual funciona
- [ ] Pesquisa de cliente funciona
- [ ] Registra dívida no banco
- [ ] Mostra cliente selecionado

#### **Devedores**
- [ ] Tela lista devedores
- [ ] Ordena por valor
- [ ] Mostra total geral
- [ ] Botão na tela de vendas

#### **Pagamento de Dívidas**
- [ ] Tela de detalhes funciona
- [ ] Lista dívidas do cliente
- [ ] Registra pagamento
- [ ] Status atualiza
- [ ] Valor restante calcula corretamente

### 2. Testes SQL

```bash
# Conectar
psql -U postgres -d pdv_system

# Ver clientes
SELECT * FROM clientes;

# Ver devedores
SELECT * FROM v_devedores;

# Ver dívidas
SELECT * FROM v_dividas_completo;

# Ver despesas
SELECT * FROM despesas ORDER BY data_despesa DESC;

# Registrar pagamento de teste
SELECT registrar_pagamento_divida(1, 100.00, 1, 'Pagamento teste', 'Admin');

# Ver status da dívida atualizado
SELECT * FROM dividas WHERE id = 1;

# Total de despesas
SELECT SUM(valor) FROM despesas;

# Total em dívidas
SELECT SUM(valor_restante) FROM dividas WHERE status != 'PAGO';

\q
```

### 3. Fluxo Completo de Teste

**Teste 1: Cadastrar Cliente e Fazer Dívida**
1. Admin → Clientes → Adicionar cliente
2. Vendas → Adicionar produtos ao carrinho
3. Finalizar Venda → DÍVIDA
4. Pesquisar cliente (usar teclado)
5. Selecionar cliente
6. Confirmar
7. Verificar no banco: `SELECT * FROM dividas ORDER BY id DESC LIMIT 1;`

**Teste 2: Ver Devedores e Pagar Dívida**
1. Vendas → Botão Clientes
2. Ver lista de devedores
3. Clicar em um devedor
4. Ver detalhes das dívidas
5. Registrar Pagamento
6. Escolher forma de pagamento
7. Digitar valor
8. Confirmar
9. Ver status atualizado

**Teste 3: Registrar Despesa**
1. Admin → Despesas
2. Adicionar nova despesa
3. Preencher descrição e valor
4. Escolher categoria
5. Escolher forma de pagamento
6. Salvar
7. Ver na lista

### 4. Problemas Comuns

**Erro: "cliente_id não existe em vendas"**
```sql
ALTER TABLE vendas ADD COLUMN cliente_id INTEGER REFERENCES clientes(id);
ALTER TABLE vendas ADD COLUMN tipo_venda VARCHAR(20) DEFAULT 'NORMAL';
```

**Erro: "trigger não funciona"**
```sql
-- Recriar trigger
DROP TRIGGER IF EXISTS trigger_atualizar_valor_restante ON dividas;
CREATE TRIGGER trigger_atualizar_valor_restante
BEFORE INSERT OR UPDATE ON dividas
FOR EACH ROW
EXECUTE FUNCTION atualizar_valor_restante();
```

**Teclado virtual não aparece:**
- Verificar imports no PesquisaClienteModal
- Verificar se TecladoVirtual está correto

**Dívida não registra:**
- Ver logs no console
- Verificar se cliente está selecionado
- Verificar se vendaId está sendo passado

---

## 📚 Resumo das Funcionalidades

✅ **Clientes**
- CRUD completo
- Pesquisa com teclado virtual
- Histórico de dívidas

✅ **Dívidas**
- Registrar dívida na venda
- Listar devedores
- Detalhes por cliente
- Múltiplos pagamentos parciais
- Status automático (PENDENTE, PARCIAL, PAGO)

✅ **Despesas**
- CRUD completo
- Categorização
- Forma de pagamento
- Total por período

✅ **Integrações**
- Teclado virtual personalizado
- Pesquisa de cliente
- Link entre vendas e dívidas
- Pagamentos rastreáveis

---

**Desenvolvido com ❤️ para Frentex e Serviços**

*Sistema Completo - Clientes, Dívidas e Despesas v1.0*
