#!/bin/bash

# Hata oluşursa betiği durdur
set -e

# pubspec.yaml yolunu belirle
PUBSPEC="pubspec.yaml"

if [ ! -f "$PUBSPEC" ]; then
    echo "❌ Hata: pubspec.yaml bulunamadı!"
    exit 1
fi

# Mevcut versiyonu al (Sadece satır başındaki 'version:' ifadesini yakalar)
VERSION_LINE=$(grep "^version:" $PUBSPEC | head -n 1)

# Boşlukları ve varsa yorumları temizle
# Örn: "version: 1.0.0+1 # comment" -> "1.0.0+1"
VERSION=$(echo "$VERSION_LINE" | sed 's/version:[[:space:]]*//' | cut -d '#' -f 1 | tr -d '[:space:]')

if [ -z "$VERSION" ]; then
    echo "❌ Hata: pubspec.yaml içinde geçerli bir versiyon bulunamadı!"
    exit 1
fi

# Versiyon adı ve build numarasını ayır
VERSION_NAME=$(echo "$VERSION" | cut -d '+' -f 1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d '+' -f 2)

# Parçalara ayır (major.minor.patch)
IFS='.' read -r major minor patch <<< "$VERSION_NAME"

# Eğer patch boşsa (örn: 1.0) 0 olarak kabul et
patch=${patch:-0}

# Patch ve Build numarasını artır
NEW_PATCH=$((patch + 1))
NEW_BUILD=$((BUILD_NUMBER + 1))
NEW_VERSION="$major.$minor.$NEW_PATCH+$NEW_BUILD"

echo "--------------------------------------------------"
echo "🚀 Versiyon Güncelleniyor: $VERSION -> $NEW_VERSION"
echo "--------------------------------------------------"

# pubspec.yaml'ı güncelle (Sadece satır başındaki versiyonu değiştirir)
# macOS uyumlu sed kullanımı
sed -i '' "s/^version:.*/version: $NEW_VERSION/" $PUBSPEC

# Build al
echo "📦 Build başlatılıyor..."
flutter build appbundle

echo "✅ İşlem başarıyla tamamlandı!"
