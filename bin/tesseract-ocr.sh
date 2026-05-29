#!/bin/bash
#===============================================================================
# Tesseract OCR - skrypt do optycznego rozpoznawania tekstu
# Dla KDE Plasma (SteamOS) - menu kontekstowe
#===============================================================================
# Użycie:
#   Zaznacz region:  tesseract-ocr.sh --region
#   OCR z pliku:     tesseract-ocr.sh --file /ścieżka/do/obrazka.png
#   OCR z schowka:   tesseract-ocr.sh --clipboard
#   Pomoc:           tesseract-ocr.sh --help
#===============================================================================

set -euo pipefail

# Ustaw PATH z brew (ważne przy uruchomieniu z servicemenu KDE - brak pełnego env)
BREW_PREFIX="/home/linuxbrew/.linuxbrew"
if [ -d "$BREW_PREFIX/bin" ]; then
    export PATH="$BREW_PREFIX/bin:$BREW_PREFIX/sbin:$PATH"
fi
export DISPLAY="${DISPLAY:-:0}"
# Ścieżka do pliku autoryzacji X (potrzebne przy uruchomieniu z servicemenu)
XAUTHORITY="${XAUTHORITY:-}"
for xauth_path in "$XAUTHORITY" "/run/user/$(id -u)/xauth"* "/tmp/xauth"*; do
    if [ -n "$xauth_path" ] && [ -f "$xauth_path" ] && [ -r "$xauth_path" ]; then
        export XAUTHORITY="$xauth_path"
        break
    fi
done
# Sesja DBus (potrzebna dla Spectacle i innych aplikacji KDE)
DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-}"
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    for dbus_path in "/run/user/$(id -u)/bus" "/run/user/$(id -u)/dbus"*; do
        if [ -S "$dbus_path" ] 2>/dev/null; then
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_path"
            break
        fi
    done
fi

# --- Konfiguracja -----------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Język OCR (domyślnie polski + angielski)
OCR_LANG="${OCR_LANG:-pol+eng}"

# Katalog tymczasowy
TEMP_DIR="${TEMP_DIR:-/tmp/tesseract-ocr}"
mkdir -p "$TEMP_DIR"

# Plik wyjściowy
OUTPUT_FILE=""

# --- Funkcje pomocnicze -----------------------------------------------------

notify() {
    local title="$1"
    local message="$2"
    local icon="${3:-dialog-information}"
    notify-send "$title" "$message" --icon="$icon" 2>/dev/null || true
}

error_exit() {
    local message="$1"
    notify "❌ Błąd OCR" "$message" "dialog-error"
    echo "ERROR: $message" >&2
    exit 1
}

show_help() {
    cat <<EOF
Tesseract OCR - narzędzie do rozpoznawania tekstu z obrazów

OPCJE:
  --region             Zaznacz obszar ekranu i wykonaj OCR
  --file <ścieżka>     Wykonaj OCR z pliku graficznego
  --clipboard          Wykonaj OCR z obrazu w schowku
  --output <ścieżka>   Zapisz wynik do pliku (opcjonalnie)
  --lang <język>       Ustaw język OCR (domyślnie: pol+eng)
  --copy               Kopiuj wynik do schowka (domyślnie)
  --no-copy            Nie kopiuj do schowka
  --help               Wyświetl tę pomoc

PRZYKŁADY:
  $0 --region
  $0 --file ~/Obrazy/skan.png
  $0 --clipboard --lang eng

JĘZYKI:
  Aby sprawdzić dostępne języki: tesseract --list-langs
  Aby zainstalować więcej: brew install tesseract-lang
EOF
    exit 0
}

copy_to_clipboard() {
    local text="$1"
    # Próbujemy różne narzędzia do schowka
    if command -v wl-copy &>/dev/null; then
        echo -n "$text" | wl-copy 2>/dev/null && return 0
    fi
    if command -v xclip &>/dev/null; then
        echo -n "$text" | xclip -selection clipboard 2>/dev/null && return 0
    fi
    if command -v xsel &>/dev/null; then
        echo -n "$text" | xsel --clipboard --input 2>/dev/null && return 0
    fi
    # KDE way (przekaż jako argument, nie przez pipe)
    if command -v qdbus &>/dev/null; then
        qdbus org.kde.klipper /klipper setClipboardContents "$text" 2>/dev/null && return 0
    fi
    return 1
}

get_clipboard_image() {
    # Próbuje pobrać obraz ze schowka i zapisać do pliku
    local output_file="$1"
    
    if command -v wl-paste &>/dev/null; then
        wl-paste --type image/png 2>/dev/null > "$output_file" && return 0
    fi
    if command -v xclip &>/dev/null; then
        xclip -selection clipboard -t image/png -o 2>/dev/null > "$output_file" && return 0
    fi
    # KDE - użyj qdbus
    if command -v qdbus &>/dev/null; then
        qdbus org.kde.klipper /klipper getClipboardContents 2>/dev/null | base64 -d 2>/dev/null > "$output_file" && return 0
    fi
    return 1
}

run_ocr() {
    local input_file="$1"
    local output_base="$2"
    local lang="${3:-$OCR_LANG}"
    
    # Sprawdź czy plik istnieje i nie jest pusty
    if [ ! -s "$input_file" ]; then
        error_exit "Plik jest pusty lub nie istnieje: $input_file"
    fi
    
    # Sprawdź MIME type
    local mime_type
    mime_type=$(file --mime-type -b "$input_file" 2>/dev/null || echo "unknown")
    if [[ "$mime_type" != image/* ]] && [[ "$mime_type" != "application/pdf" ]]; then
        error_exit "Plik nie jest obrazem ani PDF (MIME: $mime_type): $input_file"
    fi
    
    echo "🔍 Rozpoznawanie tekstu (język: $lang)..." >&2
    
    local result_file="${output_base}.txt"
    
    # --- Obsługa PDF ---
    if [[ "$mime_type" == "application/pdf" ]]; then
        # Najpierw spróbuj wyciągnąć tekst bezpośrednio (dla PDF z tekstem cyfrowym)
        if command -v pdftotext &>/dev/null; then
            echo "📄 Próba wyciągnięcia tekstu z PDF..." >&2
            pdftotext -layout "$input_file" "$result_file" 2>/dev/null
            
            if [ -s "$result_file" ] && [ "$(head -c 200 "$result_file" | tr -d '[:space:]' | wc -c)" -gt 50 ]; then
                local line_count=$(wc -l < "$result_file")
                echo "✅ Wyciągnięto tekst z PDF ($line_count linii)." >&2
                echo "$result_file"
                return 0
            fi
            echo "📄 PDF nie zawiera tekstu cyfrowego - uruchamiam OCR..." >&2
        fi
        
        # OCR dla PDF (skany, obrazki w PDF)
        echo "📄 Konwertowanie PDF na obrazy..." >&2
        
        local pdf_dir="${TEMP_DIR}/pdf_$"
        mkdir -p "$pdf_dir"
        
        # Konwertuj PDF na PNG przy pomocy pdftoppm (najlepsza jakość)
        if command -v pdftoppm &>/dev/null; then
            pdftoppm -png -r 300 "$input_file" "${pdf_dir}/page" 2>/dev/null
        elif command -v gs &>/dev/null; then
            gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 \
                -sOutputFile="${pdf_dir}/page-%d.png" "$input_file" 2>/dev/null
        else
            magick -density 300 "$input_file" -quality 100 "${pdf_dir}/page-%d.png" 2>/dev/null
        fi
        
        local page_files=("$pdf_dir"/page*.png)
        if [ ! -e "${page_files[0]}" ]; then
            rm -rf "$pdf_dir"
            error_exit "Nie udało się przekonwertować PDF na obrazy."
        fi
        
        local page_count=${#page_files[@]}
        echo "📄 Przetwarzanie $page_count stron(y) przez OCR..." >&2
        
        > "$result_file"
        
        local pn=0
        for page_file in "${page_files[@]}"; do
            pn=$((pn + 1))
            echo "   Strona $pn/$page_count..." >&2
            
            local processed="${TEMP_DIR}/processed_$_${pn}.png"
            magick "$page_file" \
                -colorspace Gray \
                -sharpen 0x1 \
                -normalize \
                -deskew 40% \
                -resize "200%>" \
                "$processed" 2>/dev/null || cp "$page_file" "$processed"
            
            local page_result="${TEMP_DIR}/page_result_$_${pn}"
            tesseract "$processed" "$page_result" -l "$lang" 2>/dev/null || {
                tesseract "$page_file" "$page_result" -l "$lang" 2>/dev/null || true
            }
            
            if [ -f "${page_result}.txt" ]; then
                if [ "$page_count" -gt 1 ]; then
                    echo "" >> "$result_file"
                    echo "--- Strona $pn ---" >> "$result_file"
                    echo "" >> "$result_file"
                fi
                cat "${page_result}.txt" >> "$result_file"
                rm -f "${page_result}.txt"
            fi
            
            rm -f "$processed" "$page_file"
        done
        
        rm -rf "$pdf_dir"
        
        if [ ! -s "$result_file" ]; then
            error_exit "Nie rozpoznano tekstu z PDF."
        fi
        
        echo "✅ Przetworzono $page_count stron(y) przez OCR." >&2
        echo "$result_file"
        return 0
    fi
    
    # --- Obsługa obrazów (w tym PSD, XCF itp.) ---
    local processed_image="${TEMP_DIR}/processed_$.png"
    
    # Użyj ImageMagick do preprocessing
    magick "$input_file" \
        -density 300 \
        -colorspace Gray \
        -sharpen 0x1 \
        -normalize \
        -deskew 40% \
        -resize "200%>" \
        "$processed_image" 2>/dev/null || {
        # Fallback: prostsza konwersja
        magick "$input_file" -density 300 "$processed_image" 2>/dev/null || \
        cp "$input_file" "$processed_image"
    }
    
    # Uruchom Tesseract
    tesseract "$processed_image" "$output_base" -l "$lang" 2>/dev/null || {
        # Próbuj bez preprocessingu
        echo "⚠️  Próbuję bez preprocessingu..." >&2
        tesseract "$input_file" "$output_base" -l "$lang" 2>/dev/null || error_exit "Tesseract nie mógł rozpoznać tekstu."
    }
    
    # Wyczyść
    rm -f "$processed_image"
    
    # Zwróć ścieżkę do wyniku
    echo "$result_file"
}

# --- Główna logika ----------------------------------------------------------

# Domyślne zachowanie
DO_COPY=true
MODE=""
FILE_PATH=""

# Parsuj argumenty
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            show_help
            ;;
        --region|-r)
            MODE="region"
            shift
            ;;
        --file|-f)
            MODE="file"
            shift
            # KDE servicemenu rozbija ścieżki ze spacjami na wiele argumentów
            # Zbieraj wszystkie argumenty aż do następnej opcji (zaczynającej się od --)
            FILE_PATH=""
            while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                if [ -z "$FILE_PATH" ]; then
                    FILE_PATH="$1"
                else
                    FILE_PATH="$FILE_PATH $1"
                fi
                shift
            done
            ;;
        --clipboard|-c)
            MODE="clipboard"
            shift
            ;;
        --output|-o)
            shift
            OUTPUT_FILE=""
            while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                if [ -z "$OUTPUT_FILE" ]; then
                    OUTPUT_FILE="$1"
                else
                    OUTPUT_FILE="$OUTPUT_FILE $1"
                fi
                shift
            done
            ;;
        --lang|-l)
            shift
            OCR_LANG=""
            while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                if [ -z "$OCR_LANG" ]; then
                    OCR_LANG="$1"
                else
                    OCR_LANG="$OCR_LANG $1"
                fi
                shift
            done
            ;;
        --copy)
            DO_COPY=true
            shift
            ;;
        --no-copy)
            DO_COPY=false
            shift
            ;;
        *)
            # Jeśli argument nie zaczyna się od --, KDE mogło pominąć --file
            # i rozbić ścieżkę na wiele argumentów. Sklej wszystko w jedną ścieżkę.
            joined="$1"
            shift
            while [[ $# -gt 0 ]] && [[ "$1" != --* ]]; do
                joined="$joined $1"
                shift
            done
            # Zawsze traktuj jako plik (run_ocr sprawdzi czy istnieje)
            MODE="file"
            FILE_PATH="$joined"
            ;;
    esac
done

# Jeśli nie podano trybu, pokaż pomoc
if [ -z "$MODE" ]; then
    show_help
fi

case "$MODE" in
    "region")
        # Tryb regionu - zaznacz obszar ekranu myszką
        notify "🖼️ OCR" "Zaznacz obszar do rozpoznania tekstu..." "camera-photo"
        
        REGION_FILE="${TEMP_DIR}/region_$$.png"
        
        # 1. spectacle - interaktywne GUI do zaznaczania regionu (działa na SteamOS)
        if command -v spectacle &>/dev/null; then
            spectacle --region --output "$REGION_FILE" 2>/dev/null
        # 2. import (ImageMagick) - pokazuje krzyżyk, czeka na kliknięcie
        elif command -v import &>/dev/null; then
            import "$REGION_FILE" 2>/dev/null
        # 3. grim + slurp (dla Wayland/compositor)
        elif command -v grim &>/dev/null && command -v slurp &>/dev/null; then
            grim -g "$(slurp)" "$REGION_FILE"
        else
            error_exit "Brak narzędzia do wyboru regionu."
        fi
        
        if [ ! -s "$REGION_FILE" ]; then
            error_exit "Nie wybrano regionu lub zrzut jest pusty."
        fi
        
        RESULT_FILE=$(run_ocr "$REGION_FILE" "${TEMP_DIR}/result_$")
        rm -f "$REGION_FILE"
        ;;
        
    "file")
        # Tryb pliku
        if [ ! -f "$FILE_PATH" ]; then
            if [ -d "$FILE_PATH" ]; then
                # To jest katalog - uruchom tryb regionu przez terminal
                notify "📁 OCR" "To jest katalog. Uruchamiam zaznaczanie obszaru..." "camera-photo"
                konsole --hold -e /bin/bash -c "exec /home/deck/.local/bin/tesseract-ocr.sh --region" 2>/dev/null &
                exit 0
            fi
            error_exit "Plik nie istnieje: $FILE_PATH"
        fi
        
        notify "🖼️ OCR" "Przetwarzanie: $(basename "$FILE_PATH")" "image-x-generic"
        RESULT_FILE=$(run_ocr "$FILE_PATH" "${TEMP_DIR}/result_$")
        ;;
        
    "clipboard")
        # Tryb schowka
        notify "📋 OCR" "Pobieranie obrazu ze schowka..." "edit-paste"
        
        CLIP_FILE="${TEMP_DIR}/clipboard_$$.png"
        if ! get_clipboard_image "$CLIP_FILE"; then
            error_exit "Nie można pobrać obrazu ze schowka. Skopiuj obraz do schowka i spróbuj ponownie."
        fi
        
        RESULT_FILE=$(run_ocr "$CLIP_FILE" "${TEMP_DIR}/result_$$")
        rm -f "$CLIP_FILE"
        ;;
esac

# Odczytaj wynik
if [ ! -f "$RESULT_FILE" ]; then
    error_exit "Nie udało się wygenerować pliku z wynikiem."
fi

RESULT_TEXT=$(cat "$RESULT_FILE")

# Jeśli wynik jest pusty
if [ -z "$(echo "$RESULT_TEXT" | tr -d '[:space:]')" ]; then
    notify "⚠️ OCR" "Nie rozpoznano żadnego tekstu na obrazie." "dialog-warning"
    rm -f "$RESULT_FILE"
    exit 1
fi

# Zapisz do pliku jeśli podano
if [ -n "$OUTPUT_FILE" ]; then
    cp "$RESULT_FILE" "$OUTPUT_FILE"
    notify "💾 OCR" "Zapisano do: $OUTPUT_FILE" "document-save"
fi

# Kopiuj do schowka
if [ "$DO_COPY" = true ]; then
    if copy_to_clipboard "$RESULT_TEXT"; then
        notify "✅ OCR gotowe" "Tekst został skopiowany do schowka!" "edit-paste"
    else
        notify "✅ OCR gotowe" "Nie udało się skopiować do schowka, ale wynik jest w pliku." "dialog-information"
    fi
fi

# Wyświetl wynik (w terminalu lub przez kdialog)
if [ -t 1 ]; then
    # Terminal dostępny
    echo ""
    echo "═══════════════════════════════════════════════"
    echo "  ✅ ROZPOZNANY TEKST:"
    echo "═══════════════════════════════════════════════"
    echo "$RESULT_TEXT"
    echo "═══════════════════════════════════════════════"
    echo "Język: $OCR_LANG"
    echo "Plik:  $RESULT_FILE"
else
    # Bez terminala - pokaż przez kdialog
    if command -v kdialog &>/dev/null; then
        # Ogranicz długość dla kdialog (max ~1000 znaków)
        if [ ${#RESULT_TEXT} -gt 8000 ]; then
            kdialog --title "✅ OCR - Rozpoznany tekst" \
                --textbox "$RESULT_FILE" 800 600 2>/dev/null || true
        else
            kdialog --title "✅ OCR - Rozpoznany tekst" \
                --msgbox "$RESULT_TEXT" 2>/dev/null || true
        fi
    fi
fi

# Usuń plik tymczasowy jeśli nie zapisaliśmy do outputu
if [ -z "$OUTPUT_FILE" ]; then
    rm -f "$RESULT_FILE"
fi

exit 0
