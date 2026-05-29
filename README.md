# Tesseract OCR dla KDE Plasma (SteamOS)

Narzędzie do optycznego rozpoznawania tekstu (OCR) z integracją z menu kontekstowym KDE Dolphin na SteamOS.

## ✨ Funkcje

- **OCR z pliku** - kliknij prawym na obrazek → rozpoznaj tekst
- **OCR z regionu** - zaznacz obszar ekranu → tekst w schowku
- **OCR ze schowka** - skopiuj obraz → rozpoznaj tekst
- **Wsparcie dla języków** - polski, angielski (łatwo dodać więcej)
- **Preprocessing obrazu** - automatyczne ulepszanie przed OCR
- **Powiadomienia** - notyfikacje systemowe o wyniku
- **Wiele formatów** - PNG, JPG, TIFF, BMP, WebP, GIF, PDF i inne

## 📦 Wymagania

- SteamOS / KDE Plasma 6
- Homebrew (Linuxbrew) - [https://brew.sh/](https://brew.sh/)
- Tesseract (instalowany automatycznie)
- ImageMagick (instalowany automatycznie)

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

### Z menu kontekstowego Dolphin

1. Kliknij **prawym przyciskiem myszy** na obrazek
2. Wybierz **Tesseract OCR**
3. Wybierz akcję:
   - **OCR - rozpoznaj tekst (do schowka)** - domyślnie polski+angielski
   - **OCR - rozpoznaj i zapisz do pliku** - zapisuje jako `nazwa.png.txt`
   - **OCR - rozpoznaj i kopiuj (angielski)** - tylko angielski
   - **OCR - otwórz w edytorze** - rozpoznaje i otwiera w Kate

### Z pulpitu / dowolnego miejsca

1. Kliknij **prawym** na pulpicie
2. Wybierz **Tesseract OCR - Region**
3. Wybierz **OCR - zaznacz obszar ekranu**
4. Zaznacz prostokąt na ekranie
5. Tekst automatycznie w schowku! 🎉

### Z terminala

```bash
# Zaznacz region
tesseract-ocr.sh --region

# OCR z pliku
tesseract-ocr.sh --file skan.png

# OCR z obrazu w schowku
tesseract-ocr.sh --clipboard

# Zmiana języka
tesseract-ocr.sh --file skan.png --lang eng

# Zapisz do pliku
tesseract-ocr.sh --file skan.png --output wynik.txt

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
├── install.sh              # Skrypt instalacyjny
├── README.md               # Ta dokumentacja
├── bin/
│   └── tesseract-ocr.sh    # Główny skrypt OCR
├── servicemenu/
│   ├── ocr-tesseract.desktop       # Menu dla plików
│   └── ocr-tesseract-region.desktop # Menu dla regionu/pulpitu
└── icons/
    └── ocr-tesseract.svg   # Ikona
```

## 🔧 Działanie

1. Obraz jest przetwarzany przez ImageMagick (skala szarości, wyostrzenie, normalizacja)
2. Tesseract OCR rozpoznaje tekst w wybranym języku
3. Wynik jest kopiowany do schowka i wyświetlany

## 📝 Licencja

MIT
