# 🖨️ Configurar Impressora no Windows

## Passo 1: Instalar a Impressora no Windows

### Opção A: Impressora USB (Recomendado para testes)

1. **Conecte a impressora** ao computador via USB
2. **Ligue a impressora**
3. O Windows deve detectar automaticamente
4. Se não detectar:
   - Vá em **Configurações** → **Dispositivos** → **Impressoras e scanners**
   - Clique em **Adicionar impressora ou scanner**
   - Aguarde o Windows encontrar
   - Clique na impressora e em **Adicionar dispositivo**

### Opção B: Impressora de Rede

1. Vá em **Configurações** → **Dispositivos** → **Impressoras e scanners**
2. Clique em **Adicionar impressora ou scanner**
3. Clique em **A impressora que desejo não está na lista**
4. Selecione **Adicionar uma impressora usando endereço TCP/IP ou nome de host**
5. Digite o IP da impressora (exemplo: 192.168.1.100)
6. Siga o assistente

### Opção C: Criar Impressora Virtual (Para testes sem impressora física)

**Windows 10/11 já vem com a impressora "Microsoft Print to PDF"**, mas para testes vamos criar uma específica:

1. Vá em **Configurações** → **Dispositivos** → **Impressoras e scanners**
2. Clique em **Adicionar impressora ou scanner**
3. Clique em **A impressora que desejo não está na lista**
4. Selecione **Adicionar uma impressora local ou de rede**
5. Escolha **Usar porta existente** → **FILE: (Imprimir para arquivo)**
6. Fabricante: **Generic** → Impressora: **Generic / Text Only**
7. Clique em **Avançar**

---

## Passo 2: Renomear para "balcao"

**MUITO IMPORTANTE:** O sistema está configurado para procurar uma impressora chamada **"balcao"**

1. Vá em **Configurações** → **Dispositivos** → **Impressoras e scanners**
2. Clique na impressora que você instalou
3. Clique em **Gerenciar**
4. Clique em **Propriedades da impressora**
5. Na aba **Geral**, altere o nome para: **balcao**
6. Clique em **OK** e depois **Aplicar**

**OU renomeie diretamente:**
1. Abra o **Painel de Controle** → **Dispositivos e Impressoras**
2. Clique com botão direito na impressora
3. Selecione **Propriedades da impressora**
4. Mude o nome para **balcao**

---

## Passo 3: Testar no Sistema

1. **Execute o app:**
   ```bash
   flutter run -d windows
   ```

2. **Vá para ADMIN** (botão laranja na tela inicial)

3. **Clique no ícone de impressora** (canto superior direito)
   - Isso vai testar a impressora "balcao"
   - Deve imprimir uma página de teste

4. **Se não funcionar**, clique no ícone de **lista** (ao lado do ícone de impressora)
   - Isso mostra todas as impressoras disponíveis no console
   - Verifique se "balcao" aparece na lista

---

## Passo 4: Fazer uma Venda e Imprimir

1. **Vá para VENDAS** (botão verde na tela inicial)
2. **Adicione produtos** ao carrinho
3. **Clique em FINALIZAR VENDA**
4. **Aparecerá um diálogo** perguntando se deseja imprimir
5. **Clique em "SIM, IMPRIMIR"**
6. O cupom será impresso na impressora "balcao"

---

## 🔧 Solução de Problemas

### Erro: Impressora "balcao" não encontrada

**Causa:** A impressora não está com o nome "balcao" ou não está instalada.

**Solução:**
1. Abra o app e vá em **ADMIN**
2. Clique no ícone de **lista** (📋) no canto superior direito
3. Verifique no console do Flutter quais impressoras estão disponíveis
4. Renomeie uma impressora existente para "balcao"

### Alterar o Nome da Impressora no Código

Se preferir usar outro nome em vez de "balcao":

1. Edite o arquivo: `lib/core/utils/windows_printer_service.dart`
2. Linha 12, altere:
   ```dart
   static const String printerName = 'balcao';
   ```
   Para:
   ```dart
   static const String printerName = 'NOME_DA_SUA_IMPRESSORA';
   ```
3. Salve e reinicie o app

### A impressão não funciona

1. **Verifique se a impressora está ligada** e pronta
2. **Teste imprimir** do Notepad ou outro programa
3. **Verifique drivers** da impressora
4. **Execute como Administrador** o terminal do Flutter:
   ```bash
   # Abra PowerShell/CMD como Administrador
   flutter run -d windows
   ```

---

## 📝 Notas

- **Para impressoras térmicas 80mm:** O sistema está configurado para papel 80mm
- **Formato do cupom:** O cupom gerado é em PDF otimizado para impressoras térmicas
- **Impressão automática:** Não é automática, sempre pergunta antes de imprimir
- **Cupom fiscal:** Este é um cupom simples, não é cupom fiscal (NF-e)

---

## 🎯 Dicas

### Usar Impressora Padrão do Windows

Se quiser sempre imprimir na impressora padrão do Windows (sem procurar por nome):

1. Edite: `lib/core/utils/windows_printer_service.dart`
2. No método `imprimirCupom`, linha 23, substitua:
   ```dart
   final printer = await _buscarImpressora(printerName);
   ```
   Por:
   ```dart
   final printer = null; // Usa impressora padrão
   ```

### Ver Preview Antes de Imprimir

O sistema permite visualizar o cupom antes de imprimir. Para ativar essa opção, você pode adicionar um botão de preview na tela de vendas.

---

**Configuração concluída!** 🎉

Agora seu sistema está pronto para imprimir cupons na impressora "balcao".
