#!/bin/bash
# Puhu — geliştirme modunda çalıştır (key inject edilir).
set -e

cd "$(dirname "$0")/.."

if [ ! -f .secrets/puhu.env ]; then
  echo "❌ .secrets/puhu.env yok. Key olmadan AI tier devre dışı kalır."
  echo "   Devam ediliyor (key'siz)..."
else
  # shellcheck disable=SC1091
  source .secrets/puhu.env
fi

exec flutter run \
  --device-id 604FE6D9-7F17-469D-8E1E-E2347BB67EC4 \
  --dart-define=PUHU_GROQ_KEY="${PUHU_GROQ_KEY:-}" \
  "$@"
