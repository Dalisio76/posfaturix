# Guia de Customização de Layout de Impressão

## Como Ajustar Tamanhos e Espaçamentos

Agora você pode ajustar TODO o layout dos recibos em um único arquivo:

**📁 lib/core/config/print_layout_config.dart**

---

## Exemplos Práticos

### 1️⃣ Aumentar TODAS as fontes em 20%

```dart
// No arquivo print_layout_config.dart, multiplique todos os valores:

static const double fonteTituloPrincipal = 21.6;  // era 18.0 * 1.2
static const double fonteTituloSecao = 14.4;      // era 12.0 * 1.2
static const double fonteSubtitulo = 13.2;        // era 11.0 * 1.2
static const double fonteNormal = 12.0;           // era 10.0 * 1.2
static const double fontePequena = 10.8;          // era 9.0 * 1.2
static const double fonteMuitoPequena = 9.6;      // era 8.0 * 1.2
```

### 2️⃣ Reduzir espaçamentos (layout mais compacto - economizar papel)

```dart
// Multiplique todos os espaços por 0.7:

static const double espacoAposTitulo = 7.0;       // era 10.0 * 0.7
static const double espacoAposDivisor = 7.0;      // era 10.0 * 0.7
static const double espacoEntreSecoes = 10.5;     // era 15.0 * 0.7
static const double espacoEntreLinhaDados = 1.4;  // era 2.0 * 0.7
static const double espacoEntreItens = 2.8;       // era 4.0 * 0.7
static const double espacoAntesRodape = 14.0;     // era 20.0 * 0.7
```

### 3️⃣ Ajustar apenas o título principal

```dart
// Aumentar só o título da empresa:
static const double fonteTituloPrincipal = 22.0;  // era 18.0
```

### 4️⃣ Mudar cores dos alertas

```dart
// Trocar laranja por vermelho nas diferenças:
static const PdfColor corAlerta = PdfColors.red;  // era orange
```

### 5️⃣ Ajustar largura das colunas

```dart
// Se os valores estão cortados, aumente:
static const double larguraValor = 80.0;  // era 70.0
```

---

## Valores Recomendados

### Layout Padrão (atual)
- Fontes: 18/12/11/10/9/8
- Espaços: 10/10/15/2/4/20
- **Papel usado:** Médio

### Layout Compacto (economizar papel)
- Fontes: 16/10/9/8/7/6
- Espaços: 6/6/10/1/2/12
- **Papel usado:** Baixo ⭐

### Layout Espaçado (mais legível)
- Fontes: 20/14/13/12/11/10
- Espaços: 15/15/20/4/6/25
- **Papel usado:** Alto

### Layout para Visão Reduzida
- Fontes: 22/16/15/14/13/12
- Espaços: 12/12/18/3/5/22
- **Papel usado:** Alto

---

## Dica Rápida

**Quer testar rápido?** Ajuste apenas esses 3 valores:

```dart
// TAMANHO GERAL DAS FONTES
static const double fonteNormal = 12.0;  // ← Base (era 10.0)

// ESPAÇAMENTO GERAL
static const double espacoMedio = 10.0;  // ← Base (era 8.0)

// TAMANHO DO TÍTULO
static const double fonteTituloPrincipal = 20.0;  // ← Destaque (era 18.0)
```

Todos os outros valores se ajustam proporcionalmente!

---

## Aplicar Mudanças

1. Edite o arquivo: `lib/core/config/print_layout_config.dart`
2. Salve o arquivo
3. **Hot reload** no app (pressione `r` no terminal ou hot reload no VS Code)
4. Faça uma venda de teste
5. Verifique o recibo impresso

✅ **Não precisa reiniciar o app!**

---

## Troubleshooting

### Texto cortado na impressora
➜ Diminua: `fonteTituloPrincipal`, `fonteTituloSecao`

### Muito espaço em branco
➜ Diminua: `espacoEntreSecoes`, `espacoAntesRodape`

### Difícil de ler
➜ Aumente: `fonteNormal`, `espacoEntreLinhaDados`

### Gastando muito papel
➜ Diminua TODOS os valores de `espaco*` em 30%
