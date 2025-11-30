#!/usr/bin/env python3
"""
Script para converter SVG para PNG em múltiplos tamanhos
Requer: pip install cairosvg pillow
"""

import os
from pathlib import Path

try:
    import cairosvg
    from PIL import Image
    import io
except ImportError:
    print("❌ ERRO: Instale as dependências primeiro:")
    print("pip install cairosvg pillow")
    exit(1)

# Diretório base
BASE_DIR = Path(__file__).parent
OUTPUT_DIR = BASE_DIR / "generated"

# Tamanhos para gerar
SIZES = {
    "windows": [16, 32, 48, 64, 128, 256, 512],
    "android": [48, 72, 96, 144, 192, 512],
}

def convert_svg_to_png(svg_path, output_path, size):
    """Converte SVG para PNG em tamanho específico"""
    try:
        # Converter SVG para PNG usando cairosvg
        png_data = cairosvg.svg2png(
            url=str(svg_path),
            output_width=size,
            output_height=size,
        )

        # Salvar PNG
        with open(output_path, 'wb') as f:
            f.write(png_data)

        print(f"✅ {output_path.name} - {size}x{size}px")
        return True
    except Exception as e:
        print(f"❌ Erro ao converter {svg_path.name}: {e}")
        return False

def create_ico(png_files, output_path):
    """Cria arquivo .ico a partir de múltiplos PNGs"""
    try:
        images = []
        for png_path in png_files:
            img = Image.open(png_path)
            images.append(img)

        # Salvar como .ico (primeiro será o ícone padrão)
        images[0].save(
            output_path,
            format='ICO',
            sizes=[(img.width, img.height) for img in images]
        )
        print(f"✅ {output_path.name} criado com {len(images)} tamanhos")
        return True
    except Exception as e:
        print(f"❌ Erro ao criar .ico: {e}")
        return False

def main():
    print("🎨 Conversor de Ícones Faturix\n")

    # Criar diretório de saída
    OUTPUT_DIR.mkdir(exist_ok=True)

    # SVG files
    svg_files = {
        "completo": BASE_DIR / "faturix_icon.svg",
        "simples": BASE_DIR / "faturix_icon_simple.svg",
        "adaptativo": BASE_DIR / "faturix_icon_adaptive.svg",
    }

    # Verificar se SVG existe
    for name, path in svg_files.items():
        if not path.exists():
            print(f"❌ Arquivo não encontrado: {path}")
            return

    print("📁 Convertendo ícones...\n")

    # ===== ÍCONE COMPLETO (tamanhos grandes) =====
    print("🖼️  Ícone Completo (grandes):")
    completo_pngs = []
    for size in [256, 512]:
        output = OUTPUT_DIR / f"faturix_{size}.png"
        if convert_svg_to_png(svg_files["completo"], output, size):
            completo_pngs.append(output)

    # ===== ÍCONE SIMPLES (tamanhos pequenos) =====
    print("\n🖼️  Ícone Simples (pequenos):")
    simples_pngs = []
    for size in [16, 32, 48, 64, 96, 128, 144, 192]:
        output = OUTPUT_DIR / f"faturix_{size}.png"
        if convert_svg_to_png(svg_files["simples"], output, size):
            simples_pngs.append(output)

    # ===== ÍCONE ADAPTATIVO (Android) =====
    print("\n🖼️  Ícone Adaptativo (Android):")
    adaptive_pngs = []
    for size in [48, 72, 96, 144, 192, 512]:
        output = OUTPUT_DIR / f"faturix_adaptive_{size}.png"
        if convert_svg_to_png(svg_files["adaptativo"], output, size):
            adaptive_pngs.append(output)

    # ===== CRIAR .ICO PARA WINDOWS =====
    print("\n🪟 Criando .ico para Windows:")
    ico_files = []
    # Usar tamanhos específicos para .ico (do simples para pequenos, completo para grandes)
    for size in [16, 32, 48]:
        ico_files.append(OUTPUT_DIR / f"faturix_{size}.png")
    for size in [256]:
        ico_files.append(OUTPUT_DIR / f"faturix_{size}.png")

    create_ico(ico_files, OUTPUT_DIR / "app_icon.ico")

    # ===== ORGANIZAR PARA ANDROID =====
    print("\n📱 Organizando para Android:")
    android_dirs = {
        "mdpi": 48,
        "hdpi": 72,
        "xhdpi": 96,
        "xxhdpi": 144,
        "xxxhdpi": 192,
    }

    android_output = OUTPUT_DIR / "android"
    for density, size in android_dirs.items():
        density_dir = android_output / f"mipmap-{density}"
        density_dir.mkdir(parents=True, exist_ok=True)

        # Copiar arquivo simples
        src = OUTPUT_DIR / f"faturix_{size}.png"
        dst = density_dir / "ic_launcher.png"

        if src.exists():
            import shutil
            shutil.copy(src, dst)
            print(f"  ✅ {density_dir.name}/ic_launcher.png")

        # Copiar arquivo adaptativo
        src_adaptive = OUTPUT_DIR / f"faturix_adaptive_{size}.png"
        dst_adaptive = density_dir / "ic_launcher_foreground.png"

        if src_adaptive.exists():
            shutil.copy(src_adaptive, dst_adaptive)
            print(f"  ✅ {density_dir.name}/ic_launcher_foreground.png")

    print("\n" + "="*50)
    print("✨ CONCLUÍDO!")
    print("="*50)
    print(f"\n📂 Arquivos gerados em: {OUTPUT_DIR.absolute()}\n")
    print("📋 Próximos passos:")
    print("  1. Copie 'app_icon.ico' para windows/runner/resources/")
    print("  2. Copie pasta 'android/mipmap-*' para android/app/src/main/res/")
    print("  3. Execute: flutter clean && flutter build windows")
    print()

if __name__ == "__main__":
    main()
