#!/bin/bash
#===============================================================================
# Instalator Tesseract OCR dla KDE Plasma (SteamOS)
#===============================================================================
# Ten skrypt instaluje:
#   1. Tesseract OCR (przez brew, jeśli nie istnieje)
#   2. Języki OCR (polski, angielski)
#   3. Skrypt OCR do /home/deck/.local/bin/
#   4. ServiceMenu dla KDE Dolphin
#   5. Ikonę dla ServiceMenu
#===============================================================================

set -euo pipefail

# Kolory dla ładnego outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Katalog docelowy dla skryptów
BIN_DIR="${HOME}/.local/bin"
SERVICEMENU_DIR="${HOME}/.local/share/kio/servicemenus"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"

echo ""
echo "═══════════════════════════════════════════════"
echo "  🔧 INSTALATOR TESSERACT OCR"
echo "  Dla KDE Plasma (SteamOS)"
echo "═══════════════════════════════════════════════"
echo ""

# --- Krok 1: Sprawdzenie i instalacja Tesseract ---
echo ""
echo "📦 Krok 1/5: Sprawdzanie Tesseract OCR..."

if command -v tesseract &>/dev/null; then
    TESSERACT_VERSION=$(tesseract --version 2>&1 | head -1)
    ok "Tesseract już zainstalowany: $TESSERACT_VERSION"
else
    info "Tesseract nie znaleziony. Instalacja przez brew..."
    
    # Sprawdź czy brew istnieje
    if ! command -v brew &>/dev/null; then
        error "Brew nie jest zainstalowane!"
        echo "  Zainstaluj brew: https://brew.sh/"
        echo "  Lub uruchom:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        exit 1
    fi
    
    brew install tesseract || error "Nie udało się zainstalować Tesseract przez brew."
    ok "Tesseract zainstalowany."
fi

# --- Krok 2: Instalacja języków ---
echo ""
echo "🌐 Krok 2/5: Sprawdzanie języków OCR..."

AVAILABLE_LANGS=$(tesseract --list-langs 2>&1 || true)

install_lang_if_missing() {
    local lang_code="$1"
    local lang_name="$2"
    if echo "$AVAILABLE_LANGS" | grep -q "^$lang_code$"; then
        ok "  Język $lang_name ($lang_code) - dostępny"
    else
        info "  Instalowanie języka $lang_name ($lang_code)..."
        brew install "tesseract-lang" 2>/dev/null || {
            # Jeśli pakiet zbiorczy nie działa, pobierz pojedynczy plik
            warn "  Próbuję pobrać plik językowy $lang_code..."
            local tessdata_dir
            tessdata_dir=$(tesseract --print-parameters 2>/dev/null | grep -i "tessdata" | head -1 | awk '{print $2}') || true
            if [ -z "$tessdata_dir" ]; then
                tessdata_dir="/home/linuxbrew/.linuxbrew/share/tessdata"
            fi
            curl -sSL "https://github.com/tesseract-ocr/tessdata/raw/main/${lang_code}.traineddata" \
                -o "${tessdata_dir}/${lang_code}.traineddata" || {
                warn "  Nie udało się pobrać $lang_code. Możesz zrobić to ręcznie."
                return 1
            }
            ok "  Język $lang_name ($lang_code) - zainstalowany"
        }
    fi
}

install_lang_if_missing "pol" "polski"
install_lang_if_missing "eng" "angielski"

# Dodatkowe przydatne języki (opcjonalnie)
if [[ "${INSTALL_EXTRA_LANGS:-}" == "true" ]]; then
    install_lang_if_missing "deu" "niemiecki"
    install_lang_if_missing "fra" "francuski"
    install_lang_if_missing "spa" "hiszpański"
    install_lang_if_missing "rus" "rosyjski"
fi

# --- Krok 3: Kopiowanie skryptu ---
echo ""
echo "📜 Krok 3/5: Instalowanie skryptu OCR..."

mkdir -p "$BIN_DIR"

# Kopiuj skrypt
cp "$PROJECT_DIR/bin/tesseract-ocr.sh" "$BIN_DIR/tesseract-ocr.sh"
chmod +x "$BIN_DIR/tesseract-ocr.sh"
ok "Skrypt zainstalowany: $BIN_DIR/tesseract-ocr.sh"

# Dodaj do PATH jeśli nie ma
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "Katalog $BIN_DIR nie jest w PATH."
    echo "  Dodaj go do ~/.bashrc lub ~/.zshrc:"
    echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
fi

# --- Krok 4: Instalacja ServiceMenu ---
echo ""
echo "🖱️  Krok 4/5: Instalowanie ServiceMenu dla KDE Dolphin..."

mkdir -p "$SERVICEMENU_DIR"

# Kopiuj pliki .desktop i ustaw uprawnienia wykonywalne
cp "$PROJECT_DIR/servicemenu/ocr-tesseract.desktop" "$SERVICEMENU_DIR/"
cp "$PROJECT_DIR/servicemenu/ocr-tesseract-region.desktop" "$SERVICEMENU_DIR/"
chmod +x "$SERVICEMENU_DIR/ocr-tesseract.desktop"
chmod +x "$SERVICEMENU_DIR/ocr-tesseract-region.desktop"
ok "ServiceMenu zainstalowane w: $SERVICEMENU_DIR"

# --- Krok 5: Instalacja launcher'a w menu aplikacji ---
echo ""
echo "🚀 Krok 5/6: Instalowanie launcher'a w menu aplikacji..."

APPLICATIONS_DIR="${HOME}/.local/share/applications"
mkdir -p "$APPLICATIONS_DIR"
cp "$PROJECT_DIR/servicemenu/ocr-tesseract-launcher.desktop" "$APPLICATIONS_DIR/ocr-tesseract.desktop"
chmod +x "$APPLICATIONS_DIR/ocr-tesseract.desktop"
ok "Launcher zainstalowany w: $APPLICATIONS_DIR/ocr-tesseract.desktop"

# --- Krok 6: Instalacja ikony ---
echo ""
echo "🎨 Krok 6/6: Instalowanie ikony..."

mkdir -p "$ICON_DIR"
cp "$PROJECT_DIR/icons/ocr-tesseract.svg" "$ICON_DIR/"
chmod 644 "$ICON_DIR/ocr-tesseract.svg"

# Aktualizacja cache ikon (jeśli dostępna)
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

ok "Ikona zainstalowana."

# --- Finalizacja ---
echo ""
echo "═══════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Instalacja zakończona!${NC}"
echo "═══════════════════════════════════════════════"
echo ""
echo "📋 Co zostało zainstalowane:"
echo "  • Tesseract OCR $(tesseract --version 2>&1 | head -1)"
echo "  • Języki: polski, angielski"
echo "  • Skrypt: $BIN_DIR/tesseract-ocr.sh"
echo "  • ServiceMenu: KDE Dolphin (kliknij prawym na obrazku)"
echo ""
echo "🔄 RESTARTUJ DOLPHINA (lub wyloguj/zaloguj), aby zobaczyć menu."
echo ""
echo "🚀 Sposoby użycia:"
echo "  1. Kliknij prawym na obrazku → Tesseract OCR → wybierz akcję"
echo "  2. Kliknij prawym na pulpicie → Tesseract OCR → zaznacz obszar"
echo "  3. Z terminala: tesseract-ocr.sh --region"
echo "  4. Z terminala: tesseract-ocr.sh --file obrazek.png"
echo ""
echo "⚙️  Aby odinstalować:"
echo "  rm -f $BIN_DIR/tesseract-ocr.sh"
echo "  rm -f $SERVICEMENU_DIR/ocr-tesseract*.desktop"
echo "  rm -f $ICON_DIR/ocr-tesseract.svg"
echo ""

# Sprawdź czy Dolphin działa i zaproponuj restart
if pgrep -x dolphin &>/dev/null; then
    echo "⚠️  Dolphin jest uruchomiony. Aby ServiceMenu działało,"
    echo "   zrestartuj Dolphin (prawy klik na pulpicie → zamknij Dolphin, otwórz ponownie)"
    echo "   lub wykonaj: killall dolphin && dolphin &"
    echo ""
fi

# Test skryptu
echo "🔍 Testowanie skryptu..."
if "$BIN_DIR/tesseract-ocr.sh" --help &>/dev/null; then
    ok "Skrypt działa poprawnie."
else
    warn "Skrypt ma problem - sprawdź logi."
fi

echo ""
echo "✨ Gotowe! Miłego używania OCR na SteamOS!"
