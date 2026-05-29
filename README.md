# Tesseract OCR dla KDE Plasma (SteamOS)

Narzędzie do optycznego rozpoznawania tekstu (OCR) z integracją z menu kontekstowym KDE Dolphin na SteamOS.

## ✨ Możliwości

| Funkcja | Opis |
|---|---|
| 🖼️ **OCR z pliku** | Kliknij prawym na obrazek → rozpoznaj tekst |
| 📐 **OCR z zaznaczonego obszaru** | Zaznacz dowolny prostokąt na ekranie → tekst w schowku |
| 📋 **OCR ze schowka** | Skopiuj obraz → rozpoznaj tekst bez zapisywania |
| 🌐 **Wybór języka** | Polski, angielski, lub oba naraz |
| 🔧 **Preprocessing** | Automatyczne ulepszanie obrazu przed OCR |
| 🔔 **Powiadomienia** | Notyfikacje systemowe z wynikiem |

### Obsługiwane formaty plików

| Format | Rozszerzenia |
|---|---|
| 📷 Obrazy | PNG, JPG, JPEG, TIFF, BMP, WebP, GIF |
| 🎨 Grafika warstwowa | **PSD** (Photoshop), **XCF** (GIMP) |
| 📄 Dokumenty | **PDF** |
| Inne | SVG, TGA, PCX, PPM, PGM, PBM, PNM, XBM, XPM, Sun Raster |

> **Jak to działa:** ImageMagick konwertuje PSD/XCF/PDF do płaskiego obrazu, a Tesseract OCR rozpoznaje tekst.

## 📦 Wymagania

- SteamOS / KDE Plasma 6
- Homebrew (Linuxbrew) - [https://brew.sh/](https://brew.sh/)
- Tesseract (instalowany automatycznie przez `install.sh`)
- ImageMagick (instalowany automatycznie przez `install.sh`)

## 🚀 Instalacja

```bash
# 1. Sklonuj repozytorium
git clone https://github.com/TWOJA_NAZWA/tesseract-ocr-kde.git
cd tesseract-ocr-kde

# 2. Uruchom instalator
chmod +x install.sh
./install.sh

# 3. Zrestartuj Dolphin (lub wyloguj/zaloguj)
killall dolphin
dolphin &
```

## 🖱️ Użycie

### Menu kontekstowe w Dolphinie

Kliknij **prawym przyciskiem myszy** na plik (obrazek, PSD, XCF, PDF) → **Tesseract OCR**:

| Opcja w menu | Działanie |
|---|---|
| **OCR - rozpoznaj tekst (do schowka)** | polski+angielski, kopiuje do schowka |
| **OCR - rozpoznaj i kopiuj (polski)** | tylko polski, kopiuje do schowka |
| **OCR - rozpoznaj i kopiuj (angielski)** | tylko angielski, kopiuje do schowka |
| **OCR - rozpoznaj tekst i zapisz do pliku...** | zapisuje jako `nazwapliku.txt` obok oryginału |
| **OCR - otwórz w edytorze** | rozpoznaje i otwiera wynik w Kate |
| **OCR z obrazu w schowku** | bierze obraz ze schowka i rozpoznaje tekst |

### Zaznaczanie obszaru ekranu

1. Kliknij **prawym** na pulpicie (albo w dowolnym folderze)
2. Wybierz **Tesseract OCR - Region** → **OCR - zaznacz obszar ekranu**
3. Kursor zmieni się w krzyżyk – **zaznacz prostokąt** na ekranie
4. Tekst automatycznie w schowku! 🎉

### Z terminala

```bash
# Zaznacz obszar ekranu
tesseract-ocr.sh --region

# OCR z pliku (dowolny format: PNG, JPG, PSD, XCF, PDF...)
tesseract-ocr.sh --file skan.png
tesseract-ocr.sh --file projekt.psd
tesseract-ocr.sh --file grafikaxcf.xcf
tesseract-ocr.sh --file dokument.pdf

# OCR z obrazu w schowku
tesseract-ocr.sh --clipboard

# Wybór języka
tesseract-ocr.sh --file skan.png --lang eng       # tylko angielski
tesseract-ocr.sh --file skan.png --lang pol        # tylko polski
tesseract-ocr.sh --file skan.png --lang pol+eng    # polski i angielski (domyślnie)

# Zapisz do pliku
tesseract-ocr.sh --file skan.png --output wynik.txt

# Bez kopiowania do schowka
tesseract-ocr.sh --file skan.png --no-copy

# Pomoc
tesseract-ocr.sh --help
```

## 🌐 Dodawanie języków

```bash
# Przez brew (wszystkie języki)
brew install tesseract-lang

# Ręcznie (pojedynczy język)
curl -LO https://github.com/tesseract-ocr/tessdata/raw/main/deu.traineddata
mv deu.traineddata $(tesseract --print-parameters | grep tessdata | head -1 | awk '{print $2}')/
```

Dostępne języki: https://github.com/tesseract-ocr/tessdata

## 🗑️ Odinstalowanie

```bash
rm -f ~/.local/bin/tesseract-ocr.sh
rm -f ~/.local/share/kio/servicemenus/ocr-tesseract*.desktop
rm -f ~/.local/share/icons/hicolor/scalable/apps/ocr-tesseract.svg

# Opcjonalnie: usuń Tesseract
brew uninstall tesseract
```

## 📁 Struktura projektu

```
tesseract-ocr-kde/
├── install.sh                 # Skrypt instalacyjny
├── README.md                  # Ta dokumentacja
├── bin/
│   └── tesseract-ocr.sh       # Główny skrypt OCR
├── servicemenu/
│   ├── ocr-tesseract.desktop          # Menu dla plików
│   └── ocr-tesseract-region.desktop   # Menu dla regionu/pulpitu
└── icons/
    └── ocr-tesseract.svg      # Ikona
```

## 🔧 Jak to działa

1. ImageMagick konwertuje plik do PNG (dla PSD/XCF/PDF wyciąga pierwszą warstwę/stronę)
2. Obraz jest ulepszany: skala szarości, wyostrzenie, normalizacja, deskew
3. Tesseract OCR rozpoznaje tekst w wybranym języku
4. Wynik trafia do schowka i/lub pliku

## 📝 Licencja

MIT