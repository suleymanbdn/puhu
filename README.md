# Zaman Yönetimi - Flutter Uygulaması

Modern ve kullanıcı dostu bir zaman yönetimi ve üretkenlik uygulaması.

## Özellikler

### 📋 Görev Yönetimi
- Görev ekleme, düzenleme ve silme
- Kategorilere göre organize etme (İş, Kişisel, Eğitim, Sağlık)
- Öncelik seviyeleri (Düşük, Orta, Yüksek)
- Tarih bazlı planlama
- Filtreler: Bugün, Yaklaşan, Tamamlanan, Gecikmiş

### 🗓️ Takvim
- Aylık ve haftalık görünüm
- Görev yoğunluğu görselleştirme
- Günlük görev detayları

### ⏱️ Odak Modu (Pomodoro)
- 25 dakikalık çalışma seansları
- Kısa mola (5dk) ve uzun mola (15dk)
- Kategoriye göre zaman takibi
- Odak oturumu geçmişi
- Mood takibi

### 📊 İstatistikler
- Görev tamamlama oranı
- Haftalık zaman bütçesi
- Kategori bazlı analiz
- Motivasyon mesajları

### 🎨 Tasarım
- Modern Material Design 3
- Karanlık ve aydınlık tema
- Akıcı animasyonlar
- Responsive tasarım

### 👤 Kullanıcı Yönetimi
- Basit giriş/kayıt sistemi
- Yerel veri saklama

## Teknolojiler

- **Framework:** Flutter 3.5+
- **State Management:** Riverpod
- **Local Database:** Hive
- **Navigation:** GoRouter
- **UI Components:** Material Design 3

## Kurulum

```bash
# Bağımlılıkları yükle
flutter pub get

# Code generation çalıştır
dart run build_runner build --delete-conflicting-outputs

# Uygulamayı çalıştır
flutter run
```

## Release Build

```bash
# APK
flutter build apk --release

# App Bundle (Google Play için önerilen)
flutter build appbundle --release
```

## Lisans

MIT License - Bu bir eğitim/prototip projesidir.
