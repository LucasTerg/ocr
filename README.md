# Tesseract OCR dla KDE Plasma (SteamOS)

Narzędzie do optycznego rozpoznawania tekstu (OCR) z integracją z menu kontekstowym KDE Dolphin na SteamOS.

## ✨ Możliwości

| Funkcja | Opis |
|---|---|
| 🖼️ **OCR z pliku** | Kliknij prawym na obrazek → rozpoznaj tekst |
| 📐 **OCR z zaznaczonego obszaru** | Zaznacz dowolny prostokąt na ekranie → tekst w okienku i schowku |
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

### Menu kontekstowe - kliknij prawym na plik

Kliknij **prawym przyciskiem myszy** na obrazek, PSD, XCF lub PDF → **Tesseract OCR**:

| Opcja w menu | Działanie |
|---|---|
| **OCR - rozpoznaj tekst (polski+angielski)** | Rozpoznaje tekst, kopiuje do schowka |
| **OCR - tylko polski** | Rozpoznaje tylko w języku polskim |
| **OCR - tylko angielski** | Rozpoznaje tylko w języku angielskim |
| **OCR - zapisz do pliku...** | Zapisuje wynik jako `nazwapliku.txt` obok oryginału |
| **OCR - otwórz w edytorze** | Rozpoznaje i otwiera wynik w edytorze Kate |
| **OCR z obrazu w schowku** | Bierze obraz ze schowka i rozpoznaje tekst |

### Menu kontekstowe - kliknij prawym w dowolnym miejscu

Kliknij **prawym przyciskiem myszy** na pulpicie, w folderze, na pustym miejscu → **Tesseract OCR**:

| Opcja w menu | Działanie |
|---|---|
| **OCR - zaznacz obszar ekranu** | Otwiera terminal z krzyżykiem → zaznacz obszar → tekst w okienku i schowku |

**Jak to działa:**
1. Wybierz **OCR - zaznacz obszar ekranu**
2. Otworzy się okno terminala (xterm)
3. Kursor zmieni się w **krzyżyk** – kliknij i przeciągnij, by zaznaczyć prostokąt z tekstem
4. Po puszczeniu myszki tekst zostanie rozpoznany
5. Otworzy się okienko (**kdialog**) z rozpoznanym tekstem
6. Tekst jest też automatycznie kopiowany do schowka
7. Zamknij okienko – terminal zamknie się automatycznie

### Z menu aplikacji

KDE Menu → **Utility** → **Tesseract OCR - zaznacz obszar** → to samo co wyżej

### Z terminala

```bash
# Zaznacz obszar ekranu (otwiera terminal z krzyżykiem)
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
rm -f ~/.local/bin/ocr-region.sh
rm -f ~/.local/bin/tesseract-ocr-wrapper.sh
rm -f ~/.local/share/kio/servicemenus/ocr-tesseract*.desktop
rm -f ~/.local/share/applications/ocr-tesseract.desktop
rm -f ~/.local/share/icons/hicolor/scalable/apps/ocr-tesseract.svg

# Opcjonalnie: usuń Tesseract
brew uninstall tesseract
```

## 📁 Struktura projektu

```
tesseract-ocr-kde/
├── install.sh                        # Skrypt instalacyjny
├── README.md                         # Ta dokumentacja
├── bin/
│   ├── tesseract-ocr.sh              # Główny skrypt OCR
│   ├── tesseract-ocr-wrapper.sh      # Wrapper dla ścieżek ze spacjami
│   └── ocr-region.sh                 # Samodzielny skrypt do OCR obszaru
├── servicemenu/
│   ├── ocr-tesseract.desktop         # Menu dla plików (obrazy, PDF)
│   ├── ocr-tesseract-anywhere.desktop # Menu dla kliknięcia w dowolnym miejscu
│   └── ocr-tesseract-launcher.desktop # Skrót w menu aplikacji
└── icons/
    └── ocr-tesseract.svg             # Ikona
```

## 🔧 Jak to działa

1. **Dla plików:** ImageMagick konwertuje plik do PNG (dla PSD/XCF/PDF wyciąga pierwszą warstwę/stronę), obraz jest ulepszany (skala szarości, wyostrzenie, normalizacja), Tesseract OCR rozpoznaje tekst, wynik trafia do schowka
2. **Dla obszaru:** `import` (ImageMagick) pokazuje krzyżyk do zaznaczenia, robi zrzut, OCR, wynik w okienku **kdialog** i w schowku
3. **Dla PDF:** najpierw próbuje wyciągnąć tekst przez `pdftotext` (dla PDF z tekstem cyfrowym), jeśli nie ma tekstu - konwertuje strony na obrazy i robi OCR

## 📝 Licencja

MIT
