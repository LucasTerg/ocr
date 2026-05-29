#!/bin/bash
# Prosty skrypt do OCR regionu - uruchamiany przez terminal
# Nie wymaga env, bo terminal ma wszystko

# Ustaw env
export DISPLAY="${DISPLAY:-:0}"
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
XAUTHORITY="${XAUTHORITY:-}"
for x in "$XAUTHORITY" /run/user/$(id -u)/xauth*; do
    if [ -n "$x" ] && [ -f "$x" ]; then export XAUTHORITY="$x"; break; fi
done
DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}"
for d in "/run/user/$(id -u)/bus" "/run/user/$(id -u)/dbus"*; do
    if [ -S "$d" ] 2>/dev/null; then export DBUS_SESSION_BUS_ADDRESS="unix:path=$d"; break; fi
done

TEMP_DIR="/tmp/tesseract-ocr"
mkdir -p "$TEMP_DIR"
REGION_FILE="$TEMP_DIR/region_$$.png"

echo "Zaznacz obszar myszka (przeciagnij prostokat)..."
echo ""

# Użyj import z ImageMagick - pokazuje krzyżyk
if ! import "$REGION_FILE" 2>/dev/null; then
    echo "Nie wybrano regionu."
    read -p "Nacisnij Enter aby zamknac..."
    exit 1
fi

if [ ! -s "$REGION_FILE" ]; then
    echo "Zrzut jest pusty."
    read -p "Nacisnij Enter aby zamknac..."
    exit 1
fi

echo "Rozpoznawanie tekstu..."
echo ""

# OCR
PROCESSED="$TEMP_DIR/processed_$$.png"
magick "$REGION_FILE" -density 300 -colorspace Gray -sharpen 0x1 -normalize -deskew 40% -resize "200%>" "$PROCESSED" 2>/dev/null || cp "$REGION_FILE" "$PROCESSED"

RESULT_FILE="$TEMP_DIR/result_$$"
tesseract "$PROCESSED" "$RESULT_FILE" -l pol+eng 2>/dev/null || tesseract "$REGION_FILE" "$RESULT_FILE" -l pol+eng 2>/dev/null

rm -f "$PROCESSED" "$REGION_FILE"

if [ ! -f "${RESULT_FILE}.txt" ] || [ ! -s "${RESULT_FILE}.txt" ]; then
    echo "Nie rozpoznano tekstu."
    read -p "Nacisnij Enter aby zamknac..."
    exit 1
fi

RESULT_TEXT=$(cat "${RESULT_FILE}.txt")

# Kopiuj do schowka
if command -v qdbus &>/dev/null; then
    qdbus org.kde.klipper /klipper setClipboardContents "$RESULT_TEXT" 2>/dev/null || true
fi

echo "=========================================="
echo "  ROZPOZNANY TEKST:"
echo "=========================================="
echo "$RESULT_TEXT"
echo "=========================================="
echo ""
echo "Tekst skopiowany do schowka!"
echo ""

# Pokaż okienko
if command -v kdialog &>/dev/null; then
    if [ ${#RESULT_TEXT} -gt 8000 ]; then
        kdialog --title "OCR - Rozpoznany tekst" --textbox "${RESULT_FILE}.txt" 800 600 2>/dev/null
    else
        kdialog --title "OCR - Rozpoznany tekst" --msgbox "$RESULT_TEXT" 2>/dev/null
    fi
fi

rm -f "${RESULT_FILE}.txt"
read -p "Nacisnij Enter aby zamknac..."
