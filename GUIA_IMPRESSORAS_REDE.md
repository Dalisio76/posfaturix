# Guia: Impressoras de Rede e Mapeamento Múltiplo

## 🎯 Funcionalidades Implementadas

### 1. Impressoras Compartilhadas em Rede
Agora você pode configurar impressoras que estão instaladas em um computador e compartilhadas para outros na rede.

**Exemplo de Uso:**
- Computador X (Cozinha) tem a impressora instalada localmente
- Compartilha a impressora como `\\ComputadorX\ImpressoraCozinha`
- Computador Y (Caixa) pode imprimir nesta impressora remota

### 2. Mapeamento Múltiplo de Documentos
Você pode mapear vários tipos de documentos para a mesma impressora de duas formas:

**Forma 1: Por Documento** (aba "Por Documento")
- Veja todos os tipos de documento
- Selecione qual impressora usar para cada um
- Vários documentos podem usar a mesma impressora

**Forma 2: Por Impressora** (aba "Por Impressora") ✨ NOVO
- Veja todas as impressoras
- Marque quais documentos devem usar aquela impressora
- Mais rápido para configurar múltiplos documentos

## 📝 Como Usar

### Passo 1: Executar Script SQL
Execute o script para adicionar suporte a rede:
```bash
psql -U seu_usuario -d posfaturix -f database/add_impressora_rede.sql
```

### Passo 2: Cadastrar Impressora com Caminho de Rede

1. Vá em **Admin > Impressoras**
2. Clique em **ADICIONAR IMPRESSORA**
3. Preencha:
   - **Nome**: Ex: "Impressora Cozinha"
   - **Tipo**: Térmica / Matricial / Laser
   - **Largura**: 58mm ou 80mm
   - **Descrição**: Opcional
   - **Caminho de Rede**: `\\NomeComputador\NomeImpressora` ✨ NOVO
4. Ative a impressora
5. Clique em **SALVAR**

**Exemplo de Caminhos de Rede:**
- Windows: `\\ComputadorCozinha\EpsonTM-T20`
- Windows: `\\192.168.1.10\Impressora_Bar`
- Linux/Samba: `//servidor/impressora`

### Passo 3: Mapear Documentos para a Impressora

#### Opção A: Por Documento (forma tradicional)
1. Vá em **Admin > Mapeamento Impressão**
2. Na aba **"Por Documento"**
3. Para cada tipo de documento, selecione a impressora desejada
4. Vários documentos podem usar a mesma impressora

#### Opção B: Por Impressora (forma rápida) ✨ NOVO
1. Vá em **Admin > Mapeamento Impressão**
2. Na aba **"Por Impressora"**
3. Clique na impressora desejada
4. Marque todos os documentos que devem usar essa impressora
5. **Muito mais rápido para configurar múltiplos documentos!**

### Passo 4: Configurar Áreas (Opcional)
1. Vá em **Admin > Áreas**
2. Edite uma área (ex: "Cozinha")
3. Selecione a impressora para pedidos automáticos
4. Quando adicionar produtos desta área em pedidos, imprimirá automaticamente

## 💡 Exemplos de Configuração

### Exemplo 1: Bar e Cozinha com Impressoras Locais
```
Impressora 1: "Impressora Bar"
  - Caminho: (vazio - impressora local)
  - Documentos: Pedido Bar

Impressora 2: "Impressora Cozinha"
  - Caminho: (vazio - impressora local)
  - Documentos: Pedido Cozinha
```

### Exemplo 2: Impressora Compartilhada da Cozinha
```
Computador: PC-COZINHA
Impressora Local: "Epson TM-T88"
Compartilhamento: \\PC-COZINHA\Cozinha

No Sistema:
  - Nome: "Impressora Cozinha"
  - Caminho de Rede: \\PC-COZINHA\Cozinha
  - Documentos: Pedido Cozinha, Pedido Bar
```

### Exemplo 3: Múltiplos Documentos na Mesma Impressora
```
Impressora: "Impressora Principal"
  - Caminho: \\SERVIDOR\ImpressoraPrincipal
  - Documentos:
    ✅ Recibo de Venda
    ✅ Conta da Mesa
    ✅ Cotação
    ✅ Fecho de Caixa
```

### Exemplo 4: Rede com IP
```
Impressora: "Impressora Bar"
  - Caminho: \\192.168.1.50\BarPrinter
  - Documentos: Pedido Bar, Conta da Mesa
```

## 🔧 Configuração de Rede no Windows

### Compartilhar Impressora (Computador que tem a impressora)
1. Painel de Controle > Dispositivos e Impressoras
2. Clique direito na impressora > Propriedades
3. Aba "Compartilhamento"
4. Marque "Compartilhar esta impressora"
5. Defina um nome (ex: "Cozinha")
6. Clique OK

### Adicionar Impressora de Rede (Computador que vai usar)
1. Painel de Controle > Dispositivos e Impressoras
2. Adicionar Impressora
3. "A impressora desejada não está na lista"
4. "Selecionar impressora compartilhada por nome"
5. Digite: `\\NomePC\NomeCompartilhamento`
6. Clique em Avançar e instale

### Permissões
- Certifique-se que ambos os computadores estão na mesma rede
- O compartilhamento de arquivos e impressoras deve estar ativado
- Pode ser necessário adicionar permissões para "Todos" na impressora

## 🎨 Interface Visual

### Indicadores Visuais
- **Ícone de Rede** (🔗): Mostra quando uma impressora tem caminho de rede configurado
- **Cor Roxa**: Caminho de rede aparece em roxo nos cards
- **Contador**: Mostra quantos documentos estão mapeados para cada impressora
- **Chips Coloridos**: Cada tipo de documento tem sua cor própria

### Abas de Mapeamento
1. **Por Documento** 📄
   - Lista todos os tipos de documento
   - Cada um com dropdown de impressora
   - Melhor para configurar um por vez

2. **Por Impressora** 🖨️
   - Lista todas as impressoras
   - Chips clicáveis para selecionar documentos
   - **Melhor para configurar vários documentos de uma vez**

## ⚠️ Resolução de Problemas

### Impressora de rede não funciona
1. Verifique se o caminho está correto: `\\ComputadorX\NomeImpressora`
2. Teste o caminho abrindo `\\ComputadorX` no Windows Explorer
3. Certifique-se que a impressora está compartilhada
4. Verifique se o firewall não está bloqueando

### Não consegue acessar impressora compartilhada
1. Ambos os computadores devem estar na mesma rede
2. Ative "Descoberta de rede" e "Compartilhamento de arquivos"
3. Use o IP ao invés do nome: `\\192.168.1.10\Impressora`
4. Verifique credenciais de rede se necessário

### Múltiplos documentos não aparecem mapeados
1. Use a aba "Por Impressora" para visualização mais clara
2. Cada documento pode ter apenas UMA impressora
3. Uma impressora pode ter VÁRIOS documentos

## 📊 Estrutura do Banco de Dados

### Tabela: impressoras
- `id`: ID único
- `nome`: Nome da impressora
- `tipo`: termica / matricial / laser
- `largura_papel`: 58 ou 80 mm
- `caminho_rede`: Caminho UNC (\\servidor\impressora) ✨ NOVO
- `ativo`: true/false

### Tabela: documento_impressora (N:N)
- `tipo_documento_id`: ID do tipo de documento
- `impressora_id`: ID da impressora
- Permite que UMA impressora tenha VÁRIOS documentos
- Permite que cada documento tenha UMA impressora

## 🚀 Próximos Passos

Depois de configurar:
1. Teste a impressão de cada tipo de documento
2. Verifique se documentos chegam na impressora correta
3. Configure áreas para impressão automática
4. Integre com biblioteca de impressão real (esc_pos_printer)

## 📞 Dúvidas Comuns

**P: Posso ter vários documentos na mesma impressora?**
R: Sim! Use a aba "Por Impressora" para selecionar múltiplos documentos de uma vez.

**P: Posso usar impressora de rede e local ao mesmo tempo?**
R: Sim! Deixe o campo "Caminho de Rede" vazio para impressoras locais.

**P: O que acontece se eu mudar a impressora de um documento?**
R: O mapeamento antigo é removido e o novo é criado automaticamente.

**P: Como saber quais documentos estão usando uma impressora?**
R: Vá na aba "Por Impressora" - mostra contador e chips selecionados.
