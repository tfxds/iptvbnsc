#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/.."
OUT="out/saplayer-roku.zip"
mkdir -p out
rm -f "$OUT"
cd app
zip -r -q "../$OUT" manifest source components images fonts locale json \
    -x "*.bak" -x "*.DS_Store" -x "*/error_log"
cd ..
echo "Pacote: $OUT"
unzip -l "$OUT" | tail -4
