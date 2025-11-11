# ⚠️ IMPORTANTE: EXECUTAR ANTES DE TESTAR

## 🔴 ERRO: "pagamento_venda does not exist"

Se você está recebendo esse erro ao finalizar uma venda, é porque a tabela de pagamentos ainda não foi criada no banco de dados.

## ✅ SOLUÇÃO

Execute o script SQL abaixo no PostgreSQL:

### Passo 1: Abrir pgAdmin ou psql

**Usando psql:**
```bash
psql -U postgres -d pdv_system
```

**Ou abra o pgAdmin e conecte ao database `pdv_system`**

### Passo 2: Executar o Script

Copie e execute todo este script:

```sql
-- ===================================
-- SCRIPT PARA ADICIONAR MÚLTIPLAS FORMAS DE PAGAMENTO POR VENDA
-- Execute este script no PostgreSQL
-- ===================================

-- ===================================
-- TABELA: pagamentos_venda
-- Armazena cada pagamento de uma venda (múltiplas formas permitidas)
-- ===================================
CREATE TABLE IF NOT EXISTS pagamentos_venda (
    id SERIAL PRIMARY KEY,
    venda_id INTEGER NOT NULL REFERENCES vendas(id) ON DELETE CASCADE,
    forma_pagamento_id INTEGER NOT NULL REFERENCES formas_pagamento(id),
    valor DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pagamentos_venda_valor_positivo CHECK (valor > 0)
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_pagamentos_venda_venda_id ON pagamentos_venda(venda_id);
CREATE INDEX IF NOT EXISTS idx_pagamentos_venda_forma_pagamento_id ON pagamentos_venda(forma_pagamento_id);

-- ===================================
-- VIEW: Vendas com pagamentos
-- ===================================
CREATE OR REPLACE VIEW v_vendas_com_pagamentos AS
SELECT
    v.id,
    v.numero,
    v.total,
    v.data_venda,
    v.terminal,
    json_agg(
        json_build_object(
            'forma_pagamento', fp.nome,
            'valor', pv.valor
        ) ORDER BY pv.id
    ) FILTER (WHERE pv.id IS NOT NULL) as pagamentos
FROM vendas v
LEFT JOIN pagamentos_venda pv ON v.id = pv.venda_id
LEFT JOIN formas_pagamento fp ON pv.forma_pagamento_id = fp.id
GROUP BY v.id, v.numero, v.total, v.data_venda, v.terminal;

-- ===================================
-- Comentários
-- ===================================
COMMENT ON TABLE pagamentos_venda IS 'Armazena os pagamentos de cada venda (permite múltiplas formas de pagamento)';
COMMENT ON COLUMN pagamentos_venda.venda_id IS 'ID da venda';
COMMENT ON COLUMN pagamentos_venda.forma_pagamento_id IS 'ID da forma de pagamento utilizada';
COMMENT ON COLUMN pagamentos_venda.valor IS 'Valor pago com esta forma de pagamento';

-- ===================================
-- VERIFICAÇÃO
-- ===================================
SELECT 'Tabela pagamentos_venda criada com sucesso!' as status;
```

### Passo 3: Verificar

Execute para confirmar que foi criado:

```sql
-- Ver estrutura da tabela
\d pagamentos_venda

-- Ou no pgAdmin:
SELECT * FROM pagamentos_venda;
```

## 🎯 Após Executar o Script

Agora você pode executar o app normalmente:

```bash
flutter run -d windows
```

E fazer vendas com múltiplas formas de pagamento sem erros!

---

## 📋 CHECKLIST

- [ ] Abri o pgAdmin ou psql
- [ ] Conectei ao database `pdv_system`
- [ ] Executei o script SQL completo
- [ ] Verifiquei que a tabela foi criada
- [ ] Executei `flutter run -d windows`
- [ ] Testei fazer uma venda

---

**Após executar este script, você NÃO precisará executá-lo novamente!**
