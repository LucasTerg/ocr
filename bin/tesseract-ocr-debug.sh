#!/bin/bash
# Debug - zapisz argumenty do pliku i uruchom właściwy skrypt
echo "$(date): $# args" >> /tmp/ocr-debug.log
echo "ARGV: $0 $@" >> /tmp/ocr-debug.log
for i in "$@"; do
  echo "  ARG[$i]: '$i'" >> /tmp/ocr-debug.log
done
echo "---" >> /tmp/ocr-debug.log

# Teraz uruchom właściwy skrypt
exec /home/deck/.local/bin/tesseract-ocr.sh "$@"
