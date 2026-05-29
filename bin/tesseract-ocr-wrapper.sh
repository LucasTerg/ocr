#!/bin/bash
# Wrapper dla tesseract-ocr.sh
# KDE servicemenu źle obsługuje %f w cudzysłowach przy spacjach
# Ten wrapper skleja wszystkie argumenty w ścieżkę pliku

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
OCR_SCRIPT="$SCRIPT_DIR/tesseract-ocr.sh"

# Jeśli nie ma argumentów, uruchom --help
if [ $# -eq 0 ]; then
    exec "$OCR_SCRIPT" --help
fi

# Sprawdź czy pierwszy argument to opcja (zaczyna się od --)
case "$1" in
    --region|--clipboard|--help)
        # Proste komendy bez pliku
        exec "$OCR_SCRIPT" "$@"
        ;;
    --file|--output|--lang)
        # Opcja z wartością - powinna działać normalnie
        exec "$OCR_SCRIPT" "$@"
        ;;
    *)
        # Jeśli pierwszy argument nie zaczyna się od --, to KDE rozbiło ścieżkę
        # Sklej wszystkie argumenty w jedną ścieżkę
        FILE_PATH="$*"
        exec "$OCR_SCRIPT" --file "$FILE_PATH"
        ;;
esac
