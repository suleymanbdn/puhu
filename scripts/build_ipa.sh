#!/bin/bash
# Puhu — release IPA build (App Store).
# flutter-ios-build-safe skill kurallarına uyar.
set -e

cd "$(dirname "$0")/.."

if [ ! -f .secrets/puhu.env ]; then
  echo "❌ .secrets/puhu.env yok — bundled AI tier inactive olacak."
  echo "   Yine de devam ediyorum (kullanıcı kendi Gemini key'iyle kullanabilir)."
  PUHU_GROQ_KEY=""
else
  # shellcheck disable=SC1091
  source .secrets/puhu.env
fi

echo "🔨 flutter build ipa --release"
flutter build ipa --release \
  --dart-define=PUHU_GROQ_KEY="${PUHU_GROQ_KEY:-}"

echo "✅ IPA: build/ios/ipa/"
ls -la build/ios/ipa/*.ipa 2>/dev/null || echo "⚠️  IPA bulunamadı"
