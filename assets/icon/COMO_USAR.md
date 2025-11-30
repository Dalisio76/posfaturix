# Como Usar os Ícones SVG do Faturix

## 📦 Arquivos Criados

1. **faturix_icon.svg** - Ícone completo com detalhes (para tamanhos grandes)
2. **faturix_icon_simple.svg** - Versão simplificada (para tamanhos pequenos)
3. **faturix_icon_adaptive.svg** - Versão adaptativa para Android

---

## 🖼️ Como Visualizar

### Opção 1: Abrir no Navegador
1. Clique duas vezes no arquivo `.svg`
2. Abrirá no navegador padrão
3. Você verá o ícone renderizado

### Opção 2: Abrir em Editor
- **Inkscape** (grátis): inkscape.org
- **Figma** (online grátis): figma.com
- **Adobe Illustrator** (pago)
- **VS Code** com extensão "SVG Preview"

---

## 🔄 Como Converter SVG para PNG

### Método 1: Navegador (Mais Fácil)

1. Abra o `.svg` no **Google Chrome** ou **Edge**
2. Clique com botão direito → **Inspecionar elemento**
3. No console, cole e execute:

```javascript
// Abrir em nova aba como PNG
const svg = document.querySelector('svg');
const canvas = document.createElement('canvas');
const ctx = canvas.getContext('2d');
const img = new Image();

canvas.width = 512;
canvas.height = 512;

img.onload = function() {
  ctx.drawImage(img, 0, 0);
  const pngUrl = canvas.toDataURL('image/png');
  const link = document.createElement('a');
  link.download = 'faturix_icon_512.png';
  link.href = pngUrl;
  link.click();
};

const svgData = new XMLSerializer().serializeToString(svg);
const svgBlob = new Blob([svgData], {type: 'image/svg+xml;charset=utf-8'});
const url = URL.createObjectURL(svgBlob);
img.src = url;
```

### Método 2: Site Online (Mais Rápido)

1. Acesse: **https://cloudconvert.com/svg-to-png**
2. Faça upload do `.svg`
3. Defina tamanho (512x512, 256x256, etc.)
4. Converta e baixe o PNG

Outros sites:
- **https://convertio.co/svg-png/**
- **https://svgtopng.com/**
- **https://onlineconvertfree.com/convert-format/svg-to-png/**

### Método 3: Inkscape (Melhor Qualidade)

1. Baixe Inkscape: https://inkscape.org/
2. Abra o arquivo `.svg`
3. **Arquivo → Exportar PNG**
4. Escolha tamanhos:
   - 512x512 (Android xxxhdpi)
   - 256x256 (Windows principal)
   - 192x192 (Android xxhdpi)
   - 144x144 (Android xhdpi)
   - 96x96 (Android hdpi)
   - 72x72 (Android mdpi)
   - 48x48 (Windows taskbar)
   - 32x32 (Windows pequeno)
   - 16x16 (Windows favicon)

### Método 4: ImageMagick (Linha de Comando)

```bash
# Instalar ImageMagick primeiro: https://imagemagick.org/

# Converter para vários tamanhos
magick faturix_icon.svg -resize 512x512 faturix_512.png
magick faturix_icon.svg -resize 256x256 faturix_256.png
magick faturix_icon.svg -resize 192x192 faturix_192.png
magick faturix_icon.svg -resize 144x144 faturix_144.png
magick faturix_icon.svg -resize 96x96 faturix_96.png
magick faturix_icon.svg -resize 48x48 faturix_48.png
magick faturix_icon.svg -resize 32x32 faturix_32.png
magick faturix_icon.svg -resize 16x16 faturix_16.png
```

---

## 🪟 Como Gerar .ICO para Windows

### Opção 1: Site Online
1. Acesse: **https://icoconvert.com/**
2. Faça upload do PNG 512x512
3. Selecione tamanhos: 16, 32, 48, 256
4. Baixe o `.ico`

### Opção 2: ImageMagick
```bash
magick faturix_512.png faturix_256.png faturix_48.png faturix_32.png faturix_16.png app_icon.ico
```

---

## 📱 Configurar no Flutter

### Para Android

1. **Instale o pacote:**
```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. **Configure:**
```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/faturix_512.png"
  adaptive_icon_background: "#1976D2"
  adaptive_icon_foreground: "assets/icon/faturix_icon_adaptive.svg"
```

3. **Execute:**
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Para Windows Desktop

1. Gere o `.ico` conforme acima
2. Coloque em: `windows/runner/resources/app_icon.ico`
3. Edite `windows/runner/Runner.rc`:
```cpp
IDI_APP_ICON ICON "resources\\app_icon.ico"
```

4. Rebuild:
```bash
flutter clean
flutter build windows
```

---

## 🎨 Personalizar as Cores

Abra o `.svg` em qualquer editor de texto e altere:

```xml
<!-- Azul escuro -->
<stop offset="0%" style="stop-color:#0D47A1;stop-opacity:1" />

<!-- Azul médio -->
<stop offset="50%" style="stop-color:#1976D2;stop-opacity:1" />

<!-- Verde -->
<stop offset="100%" style="stop-color:#00C853;stop-opacity:1" />
```

**Paleta alternativa (Roxo-Rosa):**
```xml
<stop offset="0%" style="stop-color:#6A1B9A;stop-opacity:1" />
<stop offset="50%" style="stop-color:#9C27B0;stop-opacity:1" />
<stop offset="100%" style="stop-color:#E91E63;stop-opacity:1" />
```

**Paleta alternativa (Laranja-Vermelho):**
```xml
<stop offset="0%" style="stop-color:#E65100;stop-opacity:1" />
<stop offset="50%" style="stop-color:#FF6F00;stop-opacity:1" />
<stop offset="100%" style="stop-color:#F44336;stop-opacity:1" />
```

---

## ✅ Checklist de Implementação

- [ ] Converter SVG para PNG (512x512)
- [ ] Gerar .ico para Windows
- [ ] Configurar flutter_launcher_icons
- [ ] Executar `flutter pub run flutter_launcher_icons`
- [ ] Testar no Windows (ver ícone na barra de tarefas)
- [ ] Testar no Android (ver ícone no launcher)
- [ ] Build final e verificar

---

## 🆘 Problemas Comuns

**Ícone não aparece no Windows:**
- Certifique-se que `app_icon.ico` está em `windows/runner/resources/`
- Faça `flutter clean` e rebuild
- Verifique `Runner.rc` tem a linha `IDI_APP_ICON ICON`

**Ícone aparece com fundo branco no Android:**
- Use `adaptive_icon_background` com cor sólida
- Use `faturix_icon_adaptive.svg` como foreground

**Qualidade ruim em tamanhos pequenos:**
- Use `faturix_icon_simple.svg` para gerar ícones pequenos (16x16, 32x32)
- Use `faturix_icon.svg` para ícones grandes (256x256, 512x512)

---

## 📞 Qual Usar?

| Tamanho | Arquivo Recomendado |
|---------|-------------------|
| 512x512 | faturix_icon.svg |
| 256x256 | faturix_icon.svg |
| 192x192 | faturix_icon.svg |
| 144x144 | faturix_icon_simple.svg |
| 96x96 | faturix_icon_simple.svg |
| 72x72 | faturix_icon_simple.svg |
| 48x48 | faturix_icon_simple.svg |
| 32x32 | faturix_icon_simple.svg |
| 16x16 | faturix_icon_simple.svg |
| Android | faturix_icon_adaptive.svg |
