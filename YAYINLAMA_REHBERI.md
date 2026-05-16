# Google Play Yayınlama Rehberi

## Hazırlık Durumu ✅

Uygulamanız Google Play yayını için hazır! Aşağıdaki adımları takip edin:

### 1. Gereken Hesaplar
- **Google Play Console hesabı** (25$ tek seferlik ücret)
- Google hesabınızla https://play.google.com/console adresinden kayıt olun

### 2. Uygulama Detayları

**Paket Adı:** `com.zamanyonetimi.app`  
**Uygulama Adı:** Zaman Yönetimi  
**Versiyon:** 1.0.0+1  
**Min SDK:** API 21 (Android 5.0)  
**Target SDK:** API 34 (Android 14)

### 3. Release APK/Bundle Oluşturma

#### App Bundle Oluştur (ÖNERİLEN):
```bash
cd "c:\Users\ASUS\OneDrive\Desktop\flutter\zaman_yonetimi"
flutter build appbundle --release
```

Dosya konumu: `build\app\outputs\bundle\release\app-release.aab`

#### Veya APK Oluştur:
```bash
flutter build apk --release
```

Dosya konumu: `build\app\outputs\apk\release\app-release.apk`

### 4. Google Play Console Adımları

1. **Yeni Uygulama Oluştur**
   - Play Console'a giriş yapın
   - "Uygulama oluştur" butonuna tıklayın
   - Varsayılan dil: Türkçe
   - Uygulama adı: Zaman Yönetimi
   - Uygulama türü: Uygulama

2. **Store Sayfası Bilgileri**
   - **Kısa açıklama** (max 80 karakter):
     "Zaman yönetimi ve üretkenlik artırma uygulaması. Pomodoro, görev takibi."
   
   - **Tam açıklama** (max 4000 karakter):
     ```
     Zaman Yönetimi uygulaması ile günlük görevlerinizi organize edin, 
     Pomodoro tekniği ile odaklanın ve üretkenliğinizi artırın!
     
     ÖZELLİKLER:
     
     📋 GÖREV YÖNETİMİ
     • Görev ekleme, düzenleme ve silme
     • Kategorilere göre organize etme (İş, Kişisel, Eğitim, Sağlık)
     • Öncelik seviyeleri (Düşük, Orta, Yüksek)
     • Tarih bazlı planlama
     • Gecikmiş görev takibi
     
     🗓️ TAKVİM GÖRÜNÜMÜ
     • Aylık ve haftalık takvim
     • Günlere göre görev görüntüleme
     • Görev yoğunluğu görselleştirme
     
     ⏱️ ODAK MODU (POMODORO)
     • 25 dakikalık çalışma seansları
     • Kısa ve uzun mola süreleri
     • Kategoriye göre zaman takibi
     • Odak oturumu geçmişi
     
     📊 İSTATİSTİKLER
     • Tamamlanan görev sayısı
     • Haftalık odak süresi
     • Kategori bazlı zaman bütçesi
     • Tamamlanma oranı
     
     🎨 MODERN TASARIM
     • Karanlık ve aydınlık tema desteği
     • Kullanıcı dostu arayüz
     • Akıcı animasyonlar
     
     Üretkenliğinizi artırmaya bugün başlayın!
     ```

3. **Grafikler** (gerekli):
   - **Uygulama ikonu**: 512x512 px (✅ Mevcut)
   - **Öne çıkan grafik**: 1024x500 px
   - **Ekran görüntüleri**: En az 2 adet (1080x1920 veya 1080x2340)
   - **Promo videosu**: (Opsiyonel)

4. **Kategori Seçimi**
   - Kategori: **Verimlilik**
   - Etiketler: Zaman yönetimi, Pomodoro, Görev yönetimi, Üretkenlik

5. **İçerik Derecelendirmesi**
   - Anketi doldurun (genellikle "Herkes" olur)

6. **Fiyatlandırma**
   - Ücretsiz

7. **Gizlilik Politikası**
   - URL gereklidir (basit bir sayfa oluşturun):
   ```
   Bu uygulama kullanıcı verilerini yerel cihazda saklar. 
   Hiçbir veri sunucuya gönderilmez veya üçüncü taraflarla paylaşılmaz.
   ```

8. **Uygulama İçeriği**
   - Reklam: Yok
   - İçerik derecelendirmesi: Herkes
   - Hedef kitle: Tüm yaşlar

9. **Release**
   - Test edilmiş → İç test
   - Açık test
   - Production

### 5. Signing Info (Önemli!)

**Keystore Bilgileri:**
- Dosya: `android/app/upload-keystore.jks`
- Store Password: `android`
- Key Alias: `upload`
- Key Password: `android`

**ÖNEMLİ:** Gerçek yayında güvenli parolalar kullanın ve keystore'u güvenli yedekleyin!

### 6. Test Etme

Release versiyonunu test etmek için:
```bash
flutter build apk --release
flutter install
```

### 7. Yayınlama Kontrol Listesi

- [✅] Uygulama ikonu eklendi
- [✅] Uygulama adı ayarlandı
- [✅] Benzersiz paket adı (com.zamanyonetimi.app)
- [✅] Release signing yapılandırıldı
- [✅] Proguard/minify etkinleştirildi
- [✅] Debug kodları temizlendi
- [ ] Ekran görüntüleri hazırlanmalı (emülatörden alabilirsiniz)
- [ ] Gizlilik politikası URL'si oluşturulmalı
- [ ] Play Console'da uygulama oluşturulmalı

### 8. Versiyon Güncelleme

Yeni versiyon yayınlarken:
```yaml
# pubspec.yaml
version: 1.0.1+2  # 1.0.1 görünen versiyon, +2 build numarası
```

### 9. Sorun Giderme

**"Upload failed" hatası:**
- Versiyon kodunu artırın
- Bundle boyutu kontrolü (max 150MB)

**Signing hatası:**
- keystore dosya yolunu kontrol edin
- Parolaları doğrulayın

### 10. İlk Yayın Süresi

Google Play incelemesi genellikle **1-3 gün** sürer.

---

## Hızlı Yayınlama Komutları

```bash
# 1. Release bundle oluştur
flutter clean
flutter pub get
flutter build appbundle --release

# 2. Dosyayı bul
# build\app\outputs\bundle\release\app-release.aab

# 3. Play Console'a yükle
```

## Destek

Sorun yaşarsanız:
- Flutter dokümanı: https://docs.flutter.dev/deployment/android
- Play Console yardım: https://support.google.com/googleplay/android-developer
