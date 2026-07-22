#!/bin/bash
#===============================================================================
# Deinstalator Tesseract OCR dla KDE Plasma (SteamOS)
#===============================================================================
# Ten skrypt usuwa pliki utworzone przez instalator:
#   1. Skrypty z /home/deck/.local/bin/
#   2. ServiceMenu dla KDE Dolphin
#   3. Launcher z menu aplikacji
#   4. Ikonę
#===============================================================================

set -euo pipefail

# Kolory dla ładnego outputu
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }

BIN_DIR="${HOME}/.local/bin"
SERVICEMENU_DIR="${HOME}/.local/share/kio/servicemenus"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
ICON_DIR="${HOME}/.local/share/icons/hicolor/scalable/apps"

echo ""
echo "═══════════════════════════════════════════════"
echo "  🗑️  DEINSTALATOR TESSERACT OCR"
echo "═══════════════════════════════════════════════"
echo ""

info "Usuwanie skryptów..."
rm -f "$BIN_DIR/tesseract-ocr.sh"
rm -f "$BIN_DIR/tesseract-ocr-wrapper.sh"
rm -f "$BIN_DIR/ocr-region.sh"
ok "Skrypty usunięte."

info "Usuwanie ServiceMenu dla KDE Dolphin..."
rm -f "$SERVICEMENU_DIR/ocr-tesseract.desktop"
rm -f "$SERVICEMENU_DIR/ocr-tesseract-anywhere.desktop"
ok "ServiceMenu usunięte."

info "Usuwanie launchera z menu aplikacji..."
rm -f "$APPLICATIONS_DIR/ocr-tesseract.desktop"
ok "Launcher usunięty."

info "Usuwanie ikony..."
rm -f "$ICON_DIR/ocr-tesseract.svg"
if command -v gtk-update-icon-cache &>/dev/null; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi
ok "Ikona usunięta."

echo ""
echo "═══════════════════════════════════════════════"
echo -e "  ${GREEN}✅ Odinstalowano pomyślnie!${NC}"
echo "═══════════════════════════════════════════════"
echo ""
echo "Uwaga: Tesseract zainstalowany przez brew nie został usunięty."
echo "Jeśli chcesz go całkowicie usunąć z systemu, uruchom w terminalu:"
echo "  brew uninstall tesseract tesseract-lang"
echo ""

# Zaproponuj restart Dolphin jeśli jest uruchomiony
if pgrep -x dolphin &>/dev/null; then
    echo "⚠️  Dolphin jest uruchomiony. Aby zmiany były w pełni widoczne,"
    echo "   zrestartuj Dolphin (prawy klik na pulpicie → zamknij Dolphin, otwórz ponownie)"
    echo "   lub wykonaj: killall dolphin && dolphin &"
    echo ""
fi
