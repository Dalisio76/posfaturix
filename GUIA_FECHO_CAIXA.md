# 🚀 GUIA - Sistema de Fecho de Caixa

> **Sistema completo de controle de caixa:**
> - Abertura automática na primeira venda
> - Fecho de caixa com relatório completo
> - Movimentos por forma de pagamento
> - Dívidas feitas e pagas
> - Despesas do período
> - Impressão do relatório
> - Bloqueio do sistema após fecho
> - Reabertura automática

---

## 📋 Índice

1. [SQL - Criar Tabelas](#fase-1-sql---criar-tabelas)
2. [Models Flutter](#fase-2-models-flutter)
3. [Repository](#fase-3-repository)
4. [Controller de Caixa](#fase-4-controller-de-caixa)
5. [Lógica de Abertura/Fechamento](#fase-5-lógica-de-aberturafechamento)
6. [Tela de Fecho de Caixa](#fase-6-tela-de-fecho-de-caixa)
7. [Relatório de Fecho](#fase-7-relatório-de-fecho)
8. [Impressão do Fecho](#fase-8-impressão-do-fecho)
9. [Bloqueio do Sistema](#fase-9-bloqueio-do-sistema)
10. [Integração Completa](#fase-10-integração-completa)

---

## 🗄️ FASE 1: SQL - Criar Tabelas

### Abrir SQL Shell

```bash
# SQL Shell (psql)
# Pressione Enter em tudo, digite a senha
\c pdv_system
```

### Executar SQL Completo

Cole todo este código:

```sql
-- ===================================
-- TABELA: caixas
-- ===================================
CREATE TABLE caixas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(50) UNIQUE NOT NULL,
    terminal VARCHAR(50),
    usuario VARCHAR(100),
    data_abertura TIMESTAMP NOT NULL,
    data_fechamento TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ABERTO', -- ABERTO, FECHADO
    
    -- Totais de vendas
    total_vendas DECIMAL(10,2) DEFAULT 0,
    qtd_vendas INTEGER DEFAULT 0,
    
    -- Totais por forma de pagamento
    total_cash DECIMAL(10,2) DEFAULT 0,
    total_emola DECIMAL(10,2) DEFAULT 0,
    total_mpesa DECIMAL(10,2) DEFAULT 0,
    total_pos DECIMAL(10,2) DEFAULT 0,
    
    -- Dívidas
    total_dividas_feitas DECIMAL(10,2) DEFAULT 0,
    qtd_dividas_feitas INTEGER DEFAULT 0,
    total_dividas_pagas DECIMAL(10,2) DEFAULT 0,
    qtd_dividas_pagas INTEGER DEFAULT 0,
    
    -- Despesas
    total_despesas DECIMAL(10,2) DEFAULT 0,
    qtd_despesas INTEGER DEFAULT 0,
    
    -- Saldo
    saldo_final DECIMAL(10,2) DEFAULT 0,
    
    observacoes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices
CREATE INDEX idx_caixas_status ON caixas(status);
CREATE INDEX idx_caixas_data_abertura ON caixas(data_abertura);
CREATE INDEX idx_caixas_terminal ON caixas(terminal);

-- ===================================
-- VIEW: Caixa Atual (Aberto)
-- ===================================
CREATE VIEW v_caixa_atual AS
SELECT * FROM caixas 
WHERE status = 'ABERTO' 
ORDER BY data_abertura DESC 
LIMIT 1;

-- ===================================
-- FUNCTION: Abrir Caixa
-- ===================================
CREATE OR REPLACE FUNCTION abrir_caixa(
    p_terminal VARCHAR(50),
    p_usuario VARCHAR(100) DEFAULT 'Sistema'
)
RETURNS INTEGER AS $$
DECLARE
    v_caixa_aberto_id INTEGER;
    v_novo_caixa_id INTEGER;
    v_numero VARCHAR(50);
BEGIN
    -- Verificar se já existe caixa aberto
    SELECT id INTO v_caixa_aberto_id
    FROM caixas
    WHERE status = 'ABERTO'
    LIMIT 1;
    
    IF v_caixa_aberto_id IS NOT NULL THEN
        RAISE EXCEPTION 'Já existe um caixa aberto. Feche o caixa atual antes de abrir um novo.';
    END IF;
    
    -- Gerar número do caixa
    v_numero := 'CX' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || 
                LPAD(CAST(EXTRACT(EPOCH FROM NOW()) AS TEXT), 10, '0');
    
    -- Inserir novo caixa
    INSERT INTO caixas (numero, terminal, usuario, data_abertura, status)
    VALUES (v_numero, p_terminal, p_usuario, NOW(), 'ABERTO')
    RETURNING id INTO v_novo_caixa_id;
    
    RETURN v_novo_caixa_id;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- FUNCTION: Calcular Totais do Caixa
-- ===================================
CREATE OR REPLACE FUNCTION calcular_totais_caixa(p_caixa_id INTEGER)
RETURNS VOID AS $$
DECLARE
    v_data_abertura TIMESTAMP;
    v_data_fechamento TIMESTAMP;
BEGIN
    -- Buscar datas do caixa
    SELECT data_abertura, data_fechamento
    INTO v_data_abertura, v_data_fechamento
    FROM caixas
    WHERE id = p_caixa_id;
    
    IF v_data_fechamento IS NULL THEN
        v_data_fechamento := NOW();
    END IF;
    
    -- Calcular totais de vendas normais por forma de pagamento
    UPDATE caixas SET
        total_vendas = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
        ), 0),
        qtd_vendas = COALESCE((
            SELECT COUNT(*)
            FROM vendas v
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
        ), 0),
        total_cash = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
              AND UPPER(fp.nome) = 'CASH'
        ), 0),
        total_emola = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
              AND UPPER(fp.nome) = 'EMOLA'
        ), 0),
        total_mpesa = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
              AND UPPER(fp.nome) = 'MPESA'
        ), 0),
        total_pos = COALESCE((
            SELECT SUM(v.total)
            FROM vendas v
            INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
            WHERE v.data_venda >= v_data_abertura
              AND v.data_venda <= v_data_fechamento
              AND v.tipo_venda = 'NORMAL'
              AND UPPER(fp.nome) = 'POS'
        ), 0),
        total_dividas_feitas = COALESCE((
            SELECT SUM(d.valor_total)
            FROM dividas d
            WHERE d.data_divida >= v_data_abertura
              AND d.data_divida <= v_data_fechamento
        ), 0),
        qtd_dividas_feitas = COALESCE((
            SELECT COUNT(*)
            FROM dividas d
            WHERE d.data_divida >= v_data_abertura
              AND d.data_divida <= v_data_fechamento
        ), 0),
        total_dividas_pagas = COALESCE((
            SELECT SUM(pd.valor)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0),
        qtd_dividas_pagas = COALESCE((
            SELECT COUNT(*)
            FROM pagamentos_divida pd
            WHERE pd.data_pagamento >= v_data_abertura
              AND pd.data_pagamento <= v_data_fechamento
        ), 0),
        total_despesas = COALESCE((
            SELECT SUM(valor)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0),
        qtd_despesas = COALESCE((
            SELECT COUNT(*)
            FROM despesas
            WHERE data_despesa >= v_data_abertura
              AND data_despesa <= v_data_fechamento
        ), 0)
    WHERE id = p_caixa_id;
    
    -- Calcular saldo final
    UPDATE caixas SET
        saldo_final = total_vendas + total_dividas_pagas - total_despesas
    WHERE id = p_caixa_id;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- FUNCTION: Fechar Caixa
-- ===================================
CREATE OR REPLACE FUNCTION fechar_caixa(
    p_caixa_id INTEGER,
    p_observacoes TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    -- Verificar se caixa existe e está aberto
    IF NOT EXISTS (SELECT 1 FROM caixas WHERE id = p_caixa_id AND status = 'ABERTO') THEN
        RAISE EXCEPTION 'Caixa não encontrado ou já está fechado';
    END IF;
    
    -- Calcular totais
    PERFORM calcular_totais_caixa(p_caixa_id);
    
    -- Fechar caixa
    UPDATE caixas 
    SET status = 'FECHADO',
        data_fechamento = NOW(),
        observacoes = p_observacoes
    WHERE id = p_caixa_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- ===================================
-- VIEW: Resumo de Movimentos do Caixa
-- ===================================
CREATE VIEW v_movimentos_caixa AS
SELECT 
    c.id as caixa_id,
    c.numero,
    c.data_abertura,
    c.data_fechamento,
    
    -- Vendas por forma de pagamento
    (SELECT COUNT(*) 
     FROM vendas v 
     INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
     WHERE v.data_venda >= c.data_abertura 
       AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
       AND v.tipo_venda = 'NORMAL'
       AND UPPER(fp.nome) = 'CASH'
    ) as qtd_vendas_cash,
    
    (SELECT COUNT(*) 
     FROM vendas v 
     INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
     WHERE v.data_venda >= c.data_abertura 
       AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
       AND v.tipo_venda = 'NORMAL'
       AND UPPER(fp.nome) = 'EMOLA'
    ) as qtd_vendas_emola,
    
    (SELECT COUNT(*) 
     FROM vendas v 
     INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
     WHERE v.data_venda >= c.data_abertura 
       AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
       AND v.tipo_venda = 'NORMAL'
       AND UPPER(fp.nome) = 'MPESA'
    ) as qtd_vendas_mpesa,
    
    (SELECT COUNT(*) 
     FROM vendas v 
     INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
     WHERE v.data_venda >= c.data_abertura 
       AND v.data_venda <= COALESCE(c.data_fechamento, NOW())
       AND v.tipo_venda = 'NORMAL'
       AND UPPER(fp.nome) = 'POS'
    ) as qtd_vendas_pos,
    
    c.total_cash,
    c.total_emola,
    c.total_mpesa,
    c.total_pos,
    c.total_vendas,
    c.qtd_vendas,
    c.total_dividas_feitas,
    c.qtd_dividas_feitas,
    c.total_dividas_pagas,
    c.qtd_dividas_pagas,
    c.total_despesas,
    c.qtd_despesas,
    c.saldo_final
FROM caixas c;

-- ===================================
-- COMENTÁRIOS
-- ===================================
COMMENT ON TABLE caixas IS 'Controle de abertura e fechamento de caixa';
COMMENT ON COLUMN caixas.status IS 'ABERTO: Caixa em operação, FECHADO: Caixa encerrado';
COMMENT ON COLUMN caixas.data_abertura IS 'Data/hora da primeira venda após abertura';
COMMENT ON COLUMN caixas.data_fechamento IS 'Data/hora do fechamento do caixa';
```

### Verificar Criação

```sql
-- Ver tabela
\d caixas

-- Testar abertura de caixa
SELECT abrir_caixa('CAIXA-01', 'Admin');

-- Ver caixa aberto
SELECT * FROM v_caixa_atual;

-- Ver movimentos
SELECT * FROM v_movimentos_caixa;

-- Sair
\q
```

### ✅ Checkpoint Fase 1

- [ ] Tabela `caixas` criada
- [ ] Views criadas
- [ ] Functions criadas
- [ ] Consegue abrir caixa

---

## 📱 FASE 2: Models Flutter

### 1. Caixa Model

Crie `lib/app/data/models/caixa_model.dart`:

```dart
class CaixaModel {
  final int? id;
  final String numero;
  final String? terminal;
  final String? usuario;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String status;
  
  // Totais de vendas
  final double totalVendas;
  final int qtdVendas;
  
  // Totais por forma de pagamento
  final double totalCash;
  final double totalEmola;
  final double totalMpesa;
  final double totalPos;
  
  // Dívidas
  final double totalDividasFeitas;
  final int qtdDividasFeitas;
  final double totalDividasPagas;
  final int qtdDividasPagas;
  
  // Despesas
  final double totalDespesas;
  final int qtdDespesas;
  
  // Saldo
  final double saldoFinal;
  
  final String? observacoes;
  final DateTime? createdAt;
  
  // Campos adicionais da view
  final int? qtdVendasCash;
  final int? qtdVendasEmola;
  final int? qtdVendasMpesa;
  final int? qtdVendasPos;

  CaixaModel({
    this.id,
    required this.numero,
    this.terminal,
    this.usuario,
    required this.dataAbertura,
    this.dataFechamento,
    this.status = 'ABERTO',
    this.totalVendas = 0,
    this.qtdVendas = 0,
    this.totalCash = 0,
    this.totalEmola = 0,
    this.totalMpesa = 0,
    this.totalPos = 0,
    this.totalDividasFeitas = 0,
    this.qtdDividasFeitas = 0,
    this.totalDividasPagas = 0,
    this.qtdDividasPagas = 0,
    this.totalDespesas = 0,
    this.qtdDespesas = 0,
    this.saldoFinal = 0,
    this.observacoes,
    this.createdAt,
    this.qtdVendasCash,
    this.qtdVendasEmola,
    this.qtdVendasMpesa,
    this.qtdVendasPos,
  });

  factory CaixaModel.fromMap(Map<String, dynamic> map) {
    return CaixaModel(
      id: map['id'] ?? map['caixa_id'],
      numero: map['numero'],
      terminal: map['terminal'],
      usuario: map['usuario'],
      dataAbertura: DateTime.parse(map['data_abertura'].toString()),
      dataFechamento: map['data_fechamento'] != null 
          ? DateTime.parse(map['data_fechamento'].toString()) 
          : null,
      status: map['status'] ?? 'ABERTO',
      totalVendas: double.parse(map['total_vendas']?.toString() ?? '0'),
      qtdVendas: map['qtd_vendas'] ?? 0,
      totalCash: double.parse(map['total_cash']?.toString() ?? '0'),
      totalEmola: double.parse(map['total_emola']?.toString() ?? '0'),
      totalMpesa: double.parse(map['total_mpesa']?.toString() ?? '0'),
      totalPos: double.parse(map['total_pos']?.toString() ?? '0'),
      totalDividasFeitas: double.parse(map['total_dividas_feitas']?.toString() ?? '0'),
      qtdDividasFeitas: map['qtd_dividas_feitas'] ?? 0,
      totalDividasPagas: double.parse(map['total_dividas_pagas']?.toString() ?? '0'),
      qtdDividasPagas: map['qtd_dividas_pagas'] ?? 0,
      totalDespesas: double.parse(map['total_despesas']?.toString() ?? '0'),
      qtdDespesas: map['qtd_despesas'] ?? 0,
      saldoFinal: double.parse(map['saldo_final']?.toString() ?? '0'),
      observacoes: map['observacoes'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString()) 
          : null,
      qtdVendasCash: map['qtd_vendas_cash'],
      qtdVendasEmola: map['qtd_vendas_emola'],
      qtdVendasMpesa: map['qtd_vendas_mpesa'],
      qtdVendasPos: map['qtd_vendas_pos'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'numero': numero,
      'terminal': terminal,
      'usuario': usuario,
      'data_abertura': dataAbertura.toIso8601String(),
      'data_fechamento': dataFechamento?.toIso8601String(),
      'status': status,
      'observacoes': observacoes,
    };
  }

  @override
  String toString() => 'Caixa(id: $id, numero: $numero, status: $status)';
}
```

### ✅ Checkpoint Fase 2

- [ ] CaixaModel criado
- [ ] Todos os campos mapeados
- [ ] Sem erros

---

## 🔧 FASE 3: Repository

### Caixa Repository

Crie `lib/app/data/repositories/caixa_repository.dart`:

```dart
import 'package:get/get.dart';
import '../../../core/database/database_service.dart';
import '../models/caixa_model.dart';

class CaixaRepository {
  final DatabaseService _db = Get.find<DatabaseService>();
  
  /// Buscar caixa atual (aberto)
  Future<CaixaModel?> buscarCaixaAtual() async {
    final result = await _db.query('SELECT * FROM v_caixa_atual');
    
    if (result.isEmpty) return null;
    return CaixaModel.fromMap(result.first);
  }
  
  /// Abrir novo caixa
  Future<int> abrirCaixa({
    required String terminal,
    String usuario = 'Sistema',
  }) async {
    final result = await _db.query('''
      SELECT abrir_caixa(@terminal, @usuario) as id
    ''', parameters: {
      'terminal': terminal,
      'usuario': usuario,
    });
    
    return result.first['id'] as int;
  }
  
  /// Calcular totais do caixa
  Future<void> calcularTotais(int caixaId) async {
    await _db.execute('''
      SELECT calcular_totais_caixa(@caixa_id)
    ''', parameters: {'caixa_id': caixaId});
  }
  
  /// Fechar caixa
  Future<void> fecharCaixa(int caixaId, {String? observacoes}) async {
    await _db.execute('''
      SELECT fechar_caixa(@caixa_id, @observacoes)
    ''', parameters: {
      'caixa_id': caixaId,
      'observacoes': observacoes,
    });
  }
  
  /// Buscar movimentos detalhados do caixa
  Future<CaixaModel?> buscarMovimentos(int caixaId) async {
    final result = await _db.query('''
      SELECT * FROM v_movimentos_caixa WHERE caixa_id = @caixa_id
    ''', parameters: {'caixa_id': caixaId});
    
    if (result.isEmpty) return null;
    return CaixaModel.fromMap(result.first);
  }
  
  /// Listar histórico de caixas fechados
  Future<List<CaixaModel>> listarHistorico({int limit = 30}) async {
    final result = await _db.query('''
      SELECT * FROM caixas 
      WHERE status = 'FECHADO'
      ORDER BY data_fechamento DESC
      LIMIT @limit
    ''', parameters: {'limit': limit});
    
    return result.map((map) => CaixaModel.fromMap(map)).toList();
  }
  
  /// Verificar se existe caixa aberto
  Future<bool> existeCaixaAberto() async {
    final result = await _db.query('''
      SELECT COUNT(*) as total FROM caixas WHERE status = 'ABERTO'
    ''');
    
    return (result.first['total'] as int) > 0;
  }
}
```

### ✅ Checkpoint Fase 3

- [ ] CaixaRepository criado
- [ ] Métodos completos
- [ ] Sem erros

---

## 🎮 FASE 4: Controller de Caixa

### Caixa Controller

Crie `lib/app/modules/caixa/caixa_controller.dart`:

```dart
import 'package:get/get.dart';
import '../../data/models/caixa_model.dart';
import '../../data/repositories/caixa_repository.dart';

class CaixaController extends GetxController {
  final CaixaRepository _caixaRepo = CaixaRepository();
  
  final caixaAtual = Rxn<CaixaModel>();
  final isLoading = false.obs;
  final isCaixaFechado = false.obs;

  @override
  void onInit() {
    super.onInit();
    verificarCaixaAtual();
  }

  /// Verificar se existe caixa aberto
  Future<void> verificarCaixaAtual() async {
    isLoading.value = true;
    try {
      caixaAtual.value = await _caixaRepo.buscarCaixaAtual();
      
      if (caixaAtual.value != null) {
        print('✅ Caixa aberto: ${caixaAtual.value!.numero}');
        isCaixaFechado.value = false;
      } else {
        print('⚠️ Nenhum caixa aberto');
        isCaixaFechado.value = true;
      }
    } catch (e) {
      print('❌ Erro ao verificar caixa: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Abrir novo caixa (primeira venda)
  Future<void> abrirCaixa() async {
    try {
      final caixaId = await _caixaRepo.abrirCaixa(
        terminal: 'CAIXA-01',
        usuario: 'Admin', // TODO: pegar usuário logado
      );
      
      print('✅ Caixa aberto: ID $caixaId');
      await verificarCaixaAtual();
      
      Get.snackbar(
        'Caixa Aberto',
        'Caixa iniciado com sucesso!',
        backgroundColor: Get.theme.primaryColor,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao abrir caixa: $e');
    }
  }

  /// Atualizar totais do caixa
  Future<void> atualizarTotais() async {
    if (caixaAtual.value == null) return;
    
    try {
      await _caixaRepo.calcularTotais(caixaAtual.value!.id!);
      
      // Buscar dados atualizados
      caixaAtual.value = await _caixaRepo.buscarMovimentos(caixaAtual.value!.id!);
    } catch (e) {
      print('Erro ao atualizar totais: $e');
    }
  }

  /// Preparar fecho de caixa
  Future<CaixaModel?> prepararFecho() async {
    if (caixaAtual.value == null) {
      Get.snackbar('Erro', 'Nenhum caixa aberto');
      return null;
    }
    
    isLoading.value = true;
    try {
      // Atualizar totais antes de fechar
      await _caixaRepo.calcularTotais(caixaAtual.value!.id!);
      
      // Buscar dados atualizados com movimentos
      return await _caixaRepo.buscarMovimentos(caixaAtual.value!.id!);
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao preparar fecho: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Fechar caixa
  Future<void> fecharCaixa({String? observacoes}) async {
    if (caixaAtual.value == null) {
      Get.snackbar('Erro', 'Nenhum caixa aberto');
      return;
    }
    
    try {
      await _caixaRepo.fecharCaixa(
        caixaAtual.value!.id!,
        observacoes: observacoes,
      );
      
      print('✅ Caixa fechado');
      
      // Marcar sistema como fechado
      isCaixaFechado.value = true;
      caixaAtual.value = null;
      
      Get.snackbar(
        'Caixa Fechado',
        'Fecho realizado com sucesso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Erro ao fechar caixa: $e');
    }
  }
}
```

### ✅ Checkpoint Fase 4

- [ ] CaixaController criado
- [ ] Métodos implementados
- [ ] Sem erros

---

## 🚀 FASE 5: Lógica de Abertura/Fechamento

### 1. Integrar com Vendas Controller

Edite `lib/app/modules/vendas/controllers/vendas_controller.dart`:

Adicione imports e variável:

```dart
import '../../../modules/caixa/caixa_controller.dart';

final CaixaController _caixaController = Get.put(CaixaController());
```

No método `_processarVenda()` e `_processarVendaComoDivida()`, adicione ANTES de registrar a venda:

```dart
// Verificar se precisa abrir caixa (primeira venda)
if (_caixaController.caixaAtual.value == null) {
  await _caixaController.abrirCaixa();
}

// Verificar se caixa está fechado
if (_caixaController.isCaixaFechado.value) {
  Get.snackbar(
    'Caixa Fechado',
    'O sistema está bloqueado. Feche e abra novamente.',
    backgroundColor: Colors.red,
    colorText: Colors.white,
  );
  return;
}
```

DEPOIS de registrar a venda com sucesso, adicione:

```dart
// Atualizar totais do caixa
await _caixaController.atualizarTotais();
```

### 2. Atualizar main.dart

Edite `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/modules/caixa/caixa_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar banco de dados
  print('🔄 Conectando ao PostgreSQL...');
  try {
    await Get.putAsync(() => DatabaseService().init());
    print('✅ Conexão estabelecida!');
  } catch (e) {
    print('❌ Erro ao conectar: $e');
  }
  
  // Inicializar controller de caixa
  Get.put(CaixaController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CaixaController caixaController = Get.find<CaixaController>();
    
    return GetMaterialApp(
      title: 'PDV System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Obx(() {
        // Se caixa está fechado, mostrar tela de bloqueio
        if (caixaController.isCaixaFechado.value) {
          return _buildTelaBloqueio();
        }
        
        // Senão, ir para home normal
        return HomePage();
      }),
      getPages: AppPages.routes,
    );
  }
  
  Widget _buildTelaBloqueio() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red.shade400, Colors.red.shade700],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text(
                'CAIXA FECHADO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'O sistema está bloqueado',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  // Fechar aplicação
                  SystemNavigator.pop();
                },
                icon: Icon(Icons.exit_to_app),
                label: Text('FECHAR SISTEMA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### ✅ Checkpoint Fase 5

- [ ] Caixa abre na primeira venda
- [ ] Sistema bloqueia após fecho
- [ ] Totais atualizam após cada venda

---

## 📊 FASE 6: Tela de Fecho de Caixa

### 1. Botão no App Bar de Vendas

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
      icon: Icon(Icons.point_of_sale),
      tooltip: 'Fechar Caixa',
      onPressed: () => Get.to(() => FechoCaixaPage()),
    ),
    IconButton(
      icon: Icon(Icons.refresh),
      onPressed: controller.carregarDados,
    ),
  ],
),
```

### 2. Criar Página de Fecho

Crie `lib/app/modules/caixa/fecho_caixa_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/formatters.dart';
import '../../data/models/caixa_model.dart';
import 'caixa_controller.dart';
import 'relatorio_fecho_page.dart';

class FechoCaixaPage extends StatefulWidget {
  @override
  State<FechoCaixaPage> createState() => _FechoCaixaPageState();
}

class _FechoCaixaPageState extends State<FechoCaixaPage> {
  final CaixaController controller = Get.find<CaixaController>();
  final observacoesController = TextEditingController();
  CaixaModel? caixaParaFechar;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    caixaParaFechar = await controller.prepararFecho();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FECHAR CAIXA'),
        backgroundColor: Colors.red,
      ),
      body: Obx(() {
        if (controller.isLoading.value || caixaParaFechar == null) {
          return Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              _buildHeader(),
              SizedBox(height: 30),
              
              // Vendas
              _buildSecao(
                'VENDAS',
                Icons.shopping_cart,
                Colors.green,
                [
                  _buildLinha('Total de Vendas:', caixaParaFechar!.totalVendas),
                  _buildLinhaQtd('Quantidade:', caixaParaFechar!.qtdVendas),
                ],
              ),
              SizedBox(height: 20),
              
              // Formas de Pagamento
              _buildSecao(
                'FORMAS DE PAGAMENTO',
                Icons.payment,
                Colors.blue,
                [
                  _buildLinhaFormaPagamento('CASH', 
                    caixaParaFechar!.totalCash, 
                    caixaParaFechar!.qtdVendasCash ?? 0),
                  _buildLinhaFormaPagamento('eMOLA', 
                    caixaParaFechar!.totalEmola, 
                    caixaParaFechar!.qtdVendasEmola ?? 0),
                  _buildLinhaFormaPagamento('M-PESA', 
                    caixaParaFechar!.totalMpesa, 
                    caixaParaFechar!.qtdVendasMpesa ?? 0),
                  _buildLinhaFormaPagamento('POS', 
                    caixaParaFechar!.totalPos, 
                    caixaParaFechar!.qtdVendasPos ?? 0),
                ],
              ),
              SizedBox(height: 20),
              
              // Dívidas
              _buildSecao(
                'DÍVIDAS',
                Icons.warning,
                Colors.orange,
                [
                  _buildLinha('Dívidas Feitas:', caixaParaFechar!.totalDividasFeitas),
                  _buildLinhaQtd('Quantidade:', caixaParaFechar!.qtdDividasFeitas),
                  Divider(),
                  _buildLinha('Dívidas Pagas:', caixaParaFechar!.totalDividasPagas, cor: Colors.green),
                  _buildLinhaQtd('Quantidade:', caixaParaFechar!.qtdDividasPagas),
                ],
              ),
              SizedBox(height: 20),
              
              // Despesas
              _buildSecao(
                'DESPESAS',
                Icons.money_off,
                Colors.red,
                [
                  _buildLinha('Total de Despesas:', caixaParaFechar!.totalDespesas),
                  _buildLinhaQtd('Quantidade:', caixaParaFechar!.qtdDespesas),
                ],
              ),
              SizedBox(height: 30),
              
              // Saldo Final
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: caixaParaFechar!.saldoFinal >= 0 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: caixaParaFechar!.saldoFinal >= 0 
                        ? Colors.green.shade300 
                        : Colors.red.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SALDO FINAL:',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Formatters.formatarMoeda(caixaParaFechar!.saldoFinal),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: caixaParaFechar!.saldoFinal >= 0 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              
              // Observações
              TextField(
                controller: observacoesController,
                decoration: InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                  hintText: 'Adicione observações sobre o fecho...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 30),
              
              // Botões
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Get.to(() => RelatorioFechoPage(caixa: caixaParaFechar!));
                      },
                      icon: Icon(Icons.visibility),
                      label: Text('VER RELATÓRIO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 20),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _confirmarFecho,
                      icon: Icon(Icons.check_circle),
                      label: Text('FECHAR CAIXA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 20),
                        textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAIXA: ${caixaParaFechar!.numero}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Terminal: ${caixaParaFechar!.terminal ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ABERTURA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      Formatters.formatarData(caixaParaFechar!.dataAbertura),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.grey),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FECHAMENTO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      Formatters.formatarData(DateTime.now()),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecao(String titulo, IconData icon, Color cor, List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cor),
              SizedBox(width: 10),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ],
          ),
          Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildLinha(String label, double valor, {Color? cor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16),
          ),
          Text(
            Formatters.formatarMoeda(valor),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinhaQtd(String label, int qtd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          Text(
            qtd.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLinhaFormaPagamento(String nome, double valor, int qtd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              nome,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$qtd vendas',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatarMoeda(valor),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  void _confirmarFecho() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Confirmar Fecho de Caixa'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja fechar o caixa?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Text(
              'Após o fecho, o sistema será bloqueado e você precisará fechá-lo completamente.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _realizarFecho();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('CONFIRMAR FECHO'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _realizarFecho() async {
    // Mostrar loading
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    try {
      // Fechar caixa
      await controller.fecharCaixa(
        observacoes: observacoesController.text,
      );
      
      Get.back(); // Fechar loading
      
      // Mostrar relatório final
      Get.off(() => RelatorioFechoPage(
        caixa: caixaParaFechar!,
        isFechoFinal: true,
      ));
      
    } catch (e) {
      Get.back(); // Fechar loading
      Get.snackbar('Erro', 'Erro ao fechar caixa: $e');
    }
  }

  @override
  void dispose() {
    observacoesController.dispose();
    super.dispose();
  }
}
```

### ✅ Checkpoint Fase 6

- [ ] Botão no AppBar funciona
- [ ] Tela de fecho abre
- [ ] Mostra todos os totais
- [ ] Botões funcionam

---

## 📄 FASE 7: Relatório de Fecho

### Criar Página de Relatório

Crie `lib/app/modules/caixa/relatorio_fecho_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/printer_service.dart';
import '../../data/models/caixa_model.dart';
import '../../data/models/empresa_model.dart';
import '../../data/repositories/empresa_repository.dart';

class RelatorioFechoPage extends StatefulWidget {
  final CaixaModel caixa;
  final bool isFechoFinal;

  const RelatorioFechoPage({
    Key? key,
    required this.caixa,
    this.isFechoFinal = false,
  }) : super(key: key);

  @override
  State<RelatorioFechoPage> createState() => _RelatorioFechoPageState();
}

class _RelatorioFechoPageState extends State<RelatorioFechoPage> {
  final EmpresaRepository _empresaRepo = EmpresaRepository();
  EmpresaModel? empresa;

  @override
  void initState() {
    super.initState();
    _carregarEmpresa();
  }

  Future<void> _carregarEmpresa() async {
    empresa = await _empresaRepo.buscarDados();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RELATÓRIO DE FECHO'),
        backgroundColor: widget.isFechoFinal ? Colors.red : Colors.blue,
        automaticallyImplyLeading: !widget.isFechoFinal,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho da Empresa
            if (empresa != null) _buildEmpresaHeader(),
            SizedBox(height: 20),
            
            // Informações do Caixa
            _buildCaixaInfo(),
            SizedBox(height: 30),
            
            // Resumo Geral
            _buildResumoGeral(),
            SizedBox(height: 20),
            
            // Vendas por Forma de Pagamento
            _buildFormasPagamento(),
            SizedBox(height: 20),
            
            // Dívidas
            _buildDividas(),
            SizedBox(height: 20),
            
            // Despesas
            _buildDespesas(),
            SizedBox(height: 30),
            
            // Saldo Final
            _buildSaldoFinal(),
            
            if (widget.caixa.observacoes != null && widget.caixa.observacoes!.isNotEmpty)
              ...[
                SizedBox(height: 20),
                _buildObservacoes(),
              ],
            
            SizedBox(height: 40),
            
            // Botões
            _buildBotoes(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmpresaHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            empresa!.nome,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (empresa!.nuit != null)
            Text('NUIT: ${empresa!.nuit}'),
          if (empresa!.endereco != null)
            Text(empresa!.endereco!),
          if (empresa!.contacto != null)
            Text('Tel: ${empresa!.contacto}'),
        ],
      ),
    );
  }
  
  Widget _buildCaixaInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FECHO DE CAIXA',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Divider(height: 20),
            _buildInfoRow('Número:', widget.caixa.numero),
            _buildInfoRow('Terminal:', widget.caixa.terminal ?? 'N/A'),
            _buildInfoRow('Usuário:', widget.caixa.usuario ?? 'N/A'),
            Divider(height: 20),
            _buildInfoRow('Abertura:', Formatters.formatarData(widget.caixa.dataAbertura)),
            _buildInfoRow('Fechamento:', Formatters.formatarData(
              widget.caixa.dataFechamento ?? DateTime.now()
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResumoGeral() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RESUMO GERAL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
            Divider(height: 20),
            _buildValorRow('Total de Vendas:', widget.caixa.totalVendas, Colors.green),
            _buildQtdRow('Quantidade de Vendas:', widget.caixa.qtdVendas),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFormasPagamento() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FORMAS DE PAGAMENTO',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Divider(height: 20),
            _buildFormaPagamentoRow('CASH', widget.caixa.totalCash, widget.caixa.qtdVendasCash ?? 0),
            _buildFormaPagamentoRow('eMOLA', widget.caixa.totalEmola, widget.caixa.qtdVendasEmola ?? 0),
            _buildFormaPagamentoRow('M-PESA', widget.caixa.totalMpesa, widget.caixa.qtdVendasMpesa ?? 0),
            _buildFormaPagamentoRow('POS', widget.caixa.totalPos, widget.caixa.qtdVendasPos ?? 0),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDividas() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DÍVIDAS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            Divider(height: 20),
            Text('Dívidas Feitas:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildValorRow('  Valor:', widget.caixa.totalDividasFeitas, Colors.orange),
            _buildQtdRow('  Quantidade:', widget.caixa.qtdDividasFeitas),
            SizedBox(height: 10),
            Text('Dívidas Pagas:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildValorRow('  Valor:', widget.caixa.totalDividasPagas, Colors.green),
            _buildQtdRow('  Quantidade:', widget.caixa.qtdDividasPagas),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDespesas() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DESPESAS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade900,
              ),
            ),
            Divider(height: 20),
            _buildValorRow('Total:', widget.caixa.totalDespesas, Colors.red),
            _buildQtdRow('Quantidade:', widget.caixa.qtdDespesas),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSaldoFinal() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.caixa.saldoFinal >= 0 
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SALDO FINAL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            Formatters.formatarMoeda(widget.caixa.saldoFinal),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildObservacoes() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OBSERVAÇÕES',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(widget.caixa.observacoes!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBotoes() {
    if (widget.isFechoFinal) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _imprimirRelatorio,
              icon: Icon(Icons.print, size: 30),
              label: Text(
                'IMPRIMIR RELATÓRIO',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () {
                // Fechar aplicação
                SystemNavigator.pop();
              },
              icon: Icon(Icons.exit_to_app, size: 30),
              label: Text(
                'FECHAR SISTEMA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _imprimirRelatorio,
        icon: Icon(Icons.print, size: 30),
        label: Text(
          'IMPRIMIR RELATÓRIO',
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
  
  Widget _buildValorRow(String label, double valor, Color cor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            Formatters.formatarMoeda(valor),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQtdRow(String label, int qtd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          Text('$qtd', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }
  
  Widget _buildFormaPagamentoRow(String nome, double valor, int qtd) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(nome, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '$qtd',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              Formatters.formatarMoeda(valor),
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _imprimirRelatorio() async {
    Get.dialog(
      Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    
    final sucesso = await PrinterService.imprimirFechoCaixa(
      widget.caixa,
      empresa,
    );
    
    Get.back();
    
    if (sucesso) {
      Get.snackbar(
        'Sucesso',
        'Relatório impresso!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Erro',
        'Erro ao imprimir relatório',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
```

### ✅ Checkpoint Fase 7

- [ ] Relatório completo aparece
- [ ] Mostra todas as informações
- [ ] Botões funcionam

---

## 🖨️ FASE 8: Impressão do Fecho

### 1. Atualizar Printer Service

Edite `lib/core/utils/printer_service.dart`:

Adicione o import e o método:

```dart
import '../../app/data/models/caixa_model.dart';
import '../../app/data/models/empresa_model.dart';

/// Imprimir Fecho de Caixa
static Future<bool> imprimirFechoCaixa(
  CaixaModel caixa,
  EmpresaModel? empresa,
) async {
  try {
    List<int> bytes = [];
    
    // Configuração inicial
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    
    // Cabeçalho da Empresa
    if (empresa != null) {
      bytes += generator.text(
        empresa.nome,
        styles: PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      
      if (empresa.nuit != null) {
        bytes += generator.text('NUIT: ${empresa.nuit}', 
          styles: PosStyles(align: PosAlign.center));
      }
      
      if (empresa.endereco != null) {
        bytes += generator.text(empresa.endereco!, 
          styles: PosStyles(align: PosAlign.center));
      }
      
      if (empresa.contacto != null) {
        bytes += generator.text('Tel: ${empresa.contacto}', 
          styles: PosStyles(align: PosAlign.center));
      }
      
      bytes += generator.feed(1);
    }
    
    // Separador
    bytes += generator.text('=' * 48, styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    
    // Título
    bytes += generator.text(
      'FECHO DE CAIXA',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.text('=' * 48, styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(1);
    
    // Informações do Caixa
    bytes += generator.text('Numero: ${caixa.numero}', 
      styles: PosStyles(bold: true));
    bytes += generator.text('Terminal: ${caixa.terminal ?? "N/A"}');
    bytes += generator.text('Usuario: ${caixa.usuario ?? "N/A"}');
    bytes += generator.feed(1);
    
    bytes += generator.text('Abertura:', styles: PosStyles(bold: true));
    bytes += generator.text('  ${Formatters.formatarData(caixa.dataAbertura)}');
    
    bytes += generator.text('Fechamento:', styles: PosStyles(bold: true));
    bytes += generator.text('  ${Formatters.formatarData(
      caixa.dataFechamento ?? DateTime.now()
    )}');
    
    bytes += generator.feed(1);
    bytes += generator.text('-' * 48);
    bytes += generator.feed(1);
    
    // RESUMO GERAL
    bytes += generator.text(
      'RESUMO GERAL',
      styles: PosStyles(bold: true, height: PosTextSize.size2),
    );
    bytes += generator.feed(1);
    
    bytes += _gerarLinhaValor(generator, 'Total de Vendas:', caixa.totalVendas);
    bytes += _gerarLinhaSimples(generator, 'Qtd. Vendas:', '${caixa.qtdVendas}');
    
    bytes += generator.feed(1);
    bytes += generator.text('-' * 48);
    bytes += generator.feed(1);
    
    // FORMAS DE PAGAMENTO
    bytes += generator.text(
      'FORMAS DE PAGAMENTO',
      styles: PosStyles(bold: true, height: PosTextSize.size2),
    );
    bytes += generator.feed(1);
    
    if (caixa.totalCash > 0) {
      bytes += generator.text('CASH:', styles: PosStyles(bold: true));
      bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalCash);
      bytes += _gerarLinhaSimples(generator, '  Vendas:', '${caixa.qtdVendasCash ?? 0}');
    }
    
    if (caixa.totalEmola > 0) {
      bytes += generator.text('eMOLA:', styles: PosStyles(bold: true));
      bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalEmola);
      bytes += _gerarLinhaSimples(generator, '  Vendas:', '${caixa.qtdVendasEmola ?? 0}');
    }
    
    if (caixa.totalMpesa > 0) {
      bytes += generator.text('M-PESA:', styles: PosStyles(bold: true));
      bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalMpesa);
      bytes += _gerarLinhaSimples(generator, '  Vendas:', '${caixa.qtdVendasMpesa ?? 0}');
    }
    
    if (caixa.totalPos > 0) {
      bytes += generator.text('POS:', styles: PosStyles(bold: true));
      bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalPos);
      bytes += _gerarLinhaSimples(generator, '  Vendas:', '${caixa.qtdVendasPos ?? 0}');
    }
    
    bytes += generator.feed(1);
    bytes += generator.text('-' * 48);
    bytes += generator.feed(1);
    
    // DÍVIDAS
    bytes += generator.text(
      'DIVIDAS',
      styles: PosStyles(bold: true, height: PosTextSize.size2),
    );
    bytes += generator.feed(1);
    
    bytes += generator.text('Dividas Feitas:', styles: PosStyles(bold: true));
    bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalDividasFeitas);
    bytes += _gerarLinhaSimples(generator, '  Qtd:', '${caixa.qtdDividasFeitas}');
    
    bytes += generator.feed(1);
    
    bytes += generator.text('Dividas Pagas:', styles: PosStyles(bold: true));
    bytes += _gerarLinhaValor(generator, '  Valor:', caixa.totalDividasPagas);
    bytes += _gerarLinhaSimples(generator, '  Qtd:', '${caixa.qtdDividasPagas}');
    
    bytes += generator.feed(1);
    bytes += generator.text('-' * 48);
    bytes += generator.feed(1);
    
    // DESPESAS
    bytes += generator.text(
      'DESPESAS',
      styles: PosStyles(bold: true, height: PosTextSize.size2),
    );
    bytes += generator.feed(1);
    
    bytes += _gerarLinhaValor(generator, 'Total:', caixa.totalDespesas);
    bytes += _gerarLinhaSimples(generator, 'Qtd:', '${caixa.qtdDespesas}');
    
    bytes += generator.feed(1);
    bytes += generator.text('=' * 48);
    bytes += generator.feed(1);
    
    // SALDO FINAL
    bytes += generator.text(
      'SALDO FINAL',
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    
    bytes += generator.text(
      Formatters.formatarMoeda(caixa.saldoFinal),
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size3,
        width: PosTextSize.size3,
      ),
    );
    
    bytes += generator.feed(1);
    bytes += generator.text('=' * 48);
    bytes += generator.feed(1);
    
    // Observações
    if (caixa.observacoes != null && caixa.observacoes!.isNotEmpty) {
      bytes += generator.text('OBSERVACOES:', styles: PosStyles(bold: true));
      bytes += generator.text(caixa.observacoes!);
      bytes += generator.feed(1);
      bytes += generator.text('-' * 48);
      bytes += generator.feed(1);
    }
    
    // Rodapé
    bytes += generator.text(
      'Impresso em: ${Formatters.formatarData(DateTime.now())}',
      styles: PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    
    bytes += generator.feed(1);
    bytes += generator.text(
      'Obrigado!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    
    bytes += generator.feed(3);
    bytes += generator.cut();
    
    // Enviar para impressora
    return await _imprimirBytes(bytes);
    
  } catch (e) {
    print('Erro ao imprimir fecho de caixa: $e');
    return false;
  }
}

/// Método auxiliar para gerar linha com valor
static List<int> _gerarLinhaValor(Generator generator, String label, double valor) {
  List<int> bytes = [];
  
  final valorStr = Formatters.formatarMoeda(valor);
  final espacos = 48 - label.length - valorStr.length;
  
  bytes += generator.text('$label${' ' * espacos}$valorStr');
  
  return bytes;
}

/// Método auxiliar para gerar linha simples
static List<int> _gerarLinhaSimples(Generator generator, String label, String valor) {
  List<int> bytes = [];
  
  final espacos = 48 - label.length - valor.length;
  
  bytes += generator.text('$label${' ' * espacos}$valor');
  
  return bytes;
}
```

### ✅ Checkpoint Fase 8

- [ ] Método de impressão criado
- [ ] Impressão formatada corretamente
- [ ] Teste de impressão funciona

---

## 🔒 FASE 9: Bloqueio do Sistema

### 1. Tela de Bloqueio Após Fecho

Já implementamos no `main.dart` da Fase 5, mas vamos melhorar:

Edite `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'core/database/database_service.dart';
import 'core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/modules/caixa/caixa_controller.dart';
import 'app/modules/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar banco de dados
  print('🔄 Conectando ao PostgreSQL...');
  try {
    await Get.putAsync(() => DatabaseService().init());
    print('✅ Conexão estabelecida!');
  } catch (e) {
    print('❌ Erro ao conectar: $e');
  }
  
  // Inicializar controller de caixa
  Get.put(CaixaController());
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PDV System - Frentex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: CaixaVerificador(),
      getPages: AppPages.routes,
    );
  }
}

/// Widget que verifica o status do caixa
class CaixaVerificador extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final CaixaController caixaController = Get.find<CaixaController>();
    
    return Obx(() {
      // Se caixa está fechado, mostrar tela de bloqueio
      if (caixaController.isCaixaFechado.value) {
        return TelaBloqueio();
      }
      
      // Senão, ir para home normal
      return HomePage();
    });
  }
}

/// Tela de Sistema Bloqueado
class TelaBloqueio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade700,
              Colors.red.shade900,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone animado
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(seconds: 2),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.lock,
                      size: 120,
                      color: Colors.white.withOpacity(value),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 30),
              
              // Título
              Text(
                'CAIXA FECHADO',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              
              SizedBox(height: 10),
              
              // Subtítulo
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sistema Bloqueado',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ),
              
              SizedBox(height: 40),
              
              // Informação
              Container(
                margin: EdgeInsets.symmetric(horizontal: 60),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white70, size: 40),
                    SizedBox(height: 15),
                    Text(
                      'O fecho de caixa foi realizado.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Para continuar, feche o sistema completamente\ne abra novamente para um novo turno.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 60),
              
              // Botão de fechar
              ElevatedButton.icon(
                onPressed: () {
                  // Fechar aplicação completamente
                  SystemNavigator.pop();
                },
                icon: Icon(Icons.exit_to_app, size: 30),
                label: Text(
                  'FECHAR SISTEMA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red.shade900,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Data/Hora
              Text(
                Formatters.formatarData(DateTime.now()),
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 2. Integrar com Despesas

Edite o método `adicionarDespesa` no Admin Controller:

```dart
Future<void> adicionarDespesa(DespesaModel despesa) async {
  // Verificar se caixa está aberto
  final caixaController = Get.find<CaixaController>();
  if (caixaController.caixaAtual.value == null) {
    Get.snackbar('Aviso', 'Nenhum caixa aberto. Será aberto automaticamente.');
  }
  
  try {
    await _despesaRepo.inserir(despesa);
    
    // Atualizar totais do caixa
    if (caixaController.caixaAtual.value != null) {
      await caixaController.atualizarTotais();
    }
    
    await carregarDados();
    Get.back();
    Get.snackbar('Sucesso', 'Despesa registrada!');
  } catch (e) {
    Get.snackbar('Erro', 'Erro ao adicionar: $e');
  }
}
```

### 3. Integrar com Pagamento de Dívidas

Edite o método de registrar pagamento em `detalhes_divida_page.dart`:

```dart
// Após registrar pagamento com sucesso, adicione:
final caixaController = Get.find<CaixaController>();
if (caixaController.caixaAtual.value != null) {
  await caixaController.atualizarTotais();
}
```

### ✅ Checkpoint Fase 9

- [ ] Tela de bloqueio funciona
- [ ] Sistema fecha após fecho de caixa
- [ ] Precisa fechar e abrir app para novo turno
- [ ] Despesas atualizam totais do caixa
- [ ] Pagamentos de dívidas atualizam caixa

---

## ✅ FASE 10: Integração Completa e Testes

### 1. Checklist de Implementação

#### **Banco de Dados**
- [ ] Tabela `caixas` criada
- [ ] Views criadas (v_caixa_atual, v_movimentos_caixa)
- [ ] Functions criadas (abrir_caixa, calcular_totais_caixa, fechar_caixa)
- [ ] Testes de abertura/fechamento funcionam

#### **Models e Repositories**
- [ ] CaixaModel criado
- [ ] CaixaRepository criado
- [ ] Todos os métodos implementados

#### **Controllers**
- [ ] CaixaController criado e inicializado no main.dart
- [ ] VendasController integrado
- [ ] AdminController integrado

#### **Telas**
- [ ] FechoCaixaPage criada
- [ ] RelatorioFechoPage criada
- [ ] TelaBloqueio criada
- [ ] Botão no AppBar de Vendas

#### **Funcionalidades**
- [ ] Caixa abre automaticamente na primeira venda
- [ ] Totais atualizam após cada operação
- [ ] Fecho de caixa funciona
- [ ] Relatório completo funciona
- [ ] Impressão funciona
- [ ] Sistema bloqueia após fecho
- [ ] Precisa reiniciar para novo turno

### 2. Fluxo Completo de Teste

**Teste 1: Primeiro Dia de Trabalho**

```bash
# 1. SQL Shell - Verificar estado inicial
psql -U postgres -d pdv_system

SELECT * FROM caixas;
# Deve estar vazio ou só com caixas fechados

\q
```

```
2. Abrir aplicativo pela primeira vez
3. Vendas → Fazer primeira venda
4. Sistema abre caixa automaticamente
5. Verificar no SQL:
```

```sql
SELECT * FROM v_caixa_atual;
# Deve mostrar caixa aberto
```

**Teste 2: Operações Durante o Dia**

```
1. Fazer várias vendas (CASH, eMOLA, M-PESA, POS)
2. Fazer dívida para cliente
3. Registrar despesa no Admin
4. Pagar uma dívida
5. Clicar em "Fechar Caixa" no AppBar
6. Ver preview dos totais
```

**Teste 3: Fecho de Caixa**

```
1. Vendas → Botão "Fechar Caixa"
2. Ver resumo completo:
   - Total de vendas por forma de pagamento
   - Dívidas feitas
   - Dívidas pagas
   - Despesas
   - Saldo final
3. Adicionar observações (opcional)
4. Clicar "VER RELATÓRIO" → Ver relatório completo
5. Clicar "FECHAR CAIXA" → Confirmar
6. Ver relatório final
7. Imprimir (opcional)
8. Sistema trava → Tela de bloqueio aparece
```

**Teste 4: Após Fecho**

```
1. Tentar fazer venda → Sistema bloqueado
2. Fechar aplicativo completamente
3. Abrir aplicativo novamente
4. Fazer primeira venda → Novo caixa abre automaticamente
```

### 3. Queries SQL Úteis

```sql
-- Conectar
psql -U postgres -d pdv_system

-- Ver caixa atual
SELECT * FROM v_caixa_atual;

-- Ver movimentos do caixa atual
SELECT * FROM v_movimentos_caixa ORDER BY caixa_id DESC LIMIT 1;

-- Ver histórico de caixas
SELECT 
    numero,
    data_abertura,
    data_fechamento,
    total_vendas,
    total_despesas,
    saldo_final,
    status
FROM caixas
ORDER BY data_abertura DESC
LIMIT 10;

-- Ver vendas do caixa atual
SELECT 
    v.numero,
    v.total,
    fp.nome as forma_pagamento,
    v.data_venda,
    v.tipo_venda
FROM vendas v
INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
INNER JOIN v_caixa_atual c ON v.data_venda >= c.data_abertura
ORDER BY v.data_venda DESC;

-- Ver dívidas do período do caixa
SELECT 
    c.nome as cliente,
    d.valor_total,
    d.valor_pago,
    d.valor_restante,
    d.status,
    d.data_divida
FROM dividas d
INNER JOIN clientes c ON d.cliente_id = c.id
INNER JOIN v_caixa_atual cx ON d.data_divida >= cx.data_abertura
ORDER BY d.data_divida DESC;

-- Ver pagamentos de dívidas do período
SELECT 
    pd.valor,
    fp.nome as forma_pagamento,
    pd.data_pagamento
FROM pagamentos_divida pd
INNER JOIN formas_pagamento fp ON pd.forma_pagamento_id = fp.id
INNER JOIN v_caixa_atual c ON pd.data_pagamento >= c.data_abertura
ORDER BY pd.data_pagamento DESC;

-- Ver despesas do período
SELECT 
    descricao,
    valor,
    categoria,
    data_despesa
FROM despesas
CROSS JOIN v_caixa_atual c
WHERE data_despesa >= c.data_abertura
ORDER BY data_despesa DESC;

-- Calcular totais manualmente (para verificação)
SELECT 
    -- Vendas
    COALESCE(SUM(CASE WHEN v.tipo_venda = 'NORMAL' THEN v.total ELSE 0 END), 0) as total_vendas,
    COUNT(CASE WHEN v.tipo_venda = 'NORMAL' THEN 1 END) as qtd_vendas,
    
    -- Por forma de pagamento
    COALESCE(SUM(CASE WHEN UPPER(fp.nome) = 'CASH' AND v.tipo_venda = 'NORMAL' THEN v.total ELSE 0 END), 0) as total_cash,
    COALESCE(SUM(CASE WHEN UPPER(fp.nome) = 'EMOLA' AND v.tipo_venda = 'NORMAL' THEN v.total ELSE 0 END), 0) as total_emola,
    COALESCE(SUM(CASE WHEN UPPER(fp.nome) = 'MPESA' AND v.tipo_venda = 'NORMAL' THEN v.total ELSE 0 END), 0) as total_mpesa,
    COALESCE(SUM(CASE WHEN UPPER(fp.nome) = 'POS' AND v.tipo_venda = 'NORMAL' THEN v.total ELSE 0 END), 0) as total_pos
FROM vendas v
INNER JOIN formas_pagamento fp ON v.forma_pagamento_id = fp.id
CROSS JOIN v_caixa_atual c
WHERE v.data_venda >= c.data_abertura;

-- Fechar caixa manualmente (se necessário)
SELECT fechar_caixa(1, 'Fecho manual para teste');

-- Abrir novo caixa manualmente (se necessário)
SELECT abrir_caixa('CAIXA-01', 'Admin');

-- Ver último caixa fechado
SELECT * FROM caixas 
WHERE status = 'FECHADO' 
ORDER BY data_fechamento DESC 
LIMIT 1;

\q
```

### 4. Problemas Comuns e Soluções

**Problema: Caixa não abre automaticamente**
```dart
// Verificar se CaixaController está inicializado no main.dart
Get.put(CaixaController());

// Verificar integração em vendas_controller.dart
if (_caixaController.caixaAtual.value == null) {
  await _caixaController.abrirCaixa();
}
```

**Problema: Totais não atualizam**
```dart
// Adicionar após cada operação (venda, despesa, pagamento):
await caixaController.atualizarTotais();
```

**Problema: Sistema não bloqueia após fecho**
```dart
// Verificar no main.dart se está usando Obx
return Obx(() {
  if (caixaController.isCaixaFechado.value) {
    return TelaBloqueio();
  }
  return HomePage();
});
```

**Problema: Formas de pagamento não somam**
```sql
-- Verificar nomes das formas de pagamento
SELECT * FROM formas_pagamento;

-- Devem ser exatamente: CASH, EMOLA, MPESA, POS (case insensitive)
-- Se diferentes, ajustar a function calcular_totais_caixa
```

**Problema: Impressão não funciona**
```dart
// Verificar se esc_pos_printer está instalado
flutter pub add esc_pos_printer esc_pos_utils

// Verificar se impressora está configurada
// Editar network_printer_ip em printer_service.dart
```

### 5. Estrutura Final de Arquivos

```
lib/
├── app/
│   ├── data/
│   │   ├── models/
│   │   │   ├── caixa_model.dart ✅
│   │   │   ├── cliente_model.dart
│   │   │   ├── divida_model.dart
│   │   │   └── despesa_model.dart
│   │   └── repositories/
│   │       ├── caixa_repository.dart ✅
│   │       ├── cliente_repository.dart
│   │       ├── divida_repository.dart
│   │       └── despesa_repository.dart
│   └── modules/
│       ├── caixa/
│       │   ├── caixa_controller.dart ✅
│       │   ├── fecho_caixa_page.dart ✅
│       │   └── relatorio_fecho_page.dart ✅
│       ├── vendas/
│       │   └── controllers/
│       │       └── vendas_controller.dart (modificado) ✅
│       └── admin/
│           └── controllers/
│               └── admin_controller.dart (modificado) ✅
├── core/
│   └── utils/
│       └── printer_service.dart (modificado) ✅
└── main.dart (modificado) ✅
```

### 6. Melhorias Futuras (Opcionais)

**Dashboard com Gráficos de Caixa**
- Gráfico de vendas por hora
- Comparação entre dias
- Performance por forma de pagamento

**Relatórios Avançados**
- Exportar para PDF
- Enviar por email
- Histórico detalhado

**Múltiplos Terminais**
- Suporte a vários caixas simultâneos
- Consolidação de fechos

**Alertas**
- Notificar quando passar X horas sem fecho
- Alertar se saldo negativo

---

## 🎉 Conclusão

### ✅ Sistema Completo de Fecho de Caixa

**Funcionalidades Implementadas:**

1. **Abertura Automática**
   - Caixa abre na primeira venda do dia
   - Registra hora de abertura

2. **Controle de Movimentos**
   - Todas vendas registradas
   - Separação por forma de pagamento
   - Dívidas feitas e pagas
   - Despesas do período

3. **Fecho de Caixa**
   - Cálculo automático de totais
   - Relatório completo
   - Observações opcionais
   - Impressão térmica

4. **Bloqueio do Sistema**
   - Sistema trava após fecho
   - Tela de bloqueio visual
   - Obriga fechamento do app

5. **Reabertura**
   - Novo caixa abre automaticamente
   - Novo ciclo inicia

### 📊 Controles Implementados

✅ **Vendas**: Total + quantidade por forma de pagamento  
✅ **Dívidas**: Feitas + pagas no período  
✅ **Despesas**: Total + quantidade  
✅ **Saldo Final**: Vendas + dívidas pagas - despesas  
✅ **Relatório**: Completo e imprimível  
✅ **Segurança**: Sistema bloqueado após fecho  

---

**Desenvolvido com ❤️ para Frentex e Serviços**

*Sistema de Fecho de Caixa v1.0 - Completo e Funcional*
