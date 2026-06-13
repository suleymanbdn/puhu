# Puhu YKS — Yapay Zeka YKS Koçu: Ürün Yönü ve Yol Haritası

**Tarih:** 2026-06-13
**Durum:** Onaylandı (yön + isim + parçalama). P1 uygulamaya hazır.

## 1. Ürün kararı (onaylı)

Puhu bir **YKS çalışma takip uygulamasından**, **yapay zeka destekli YKS koçuna** dönüşüyor.

- **Felsefe (kodda zaten var):** Kural motoru (`AlgorithmicCoach`) kullanıcı verisinden
  gerçekleri çıkarır; AI katmanı (`AiSummarizer` → Groq/Gemini) bunları kişisel,
  motive edici, eyleme dönük mesaja çevirir. *"Kural motoru ne söyleyeceğini bilir,
  AI nasıl söyleyeceğini bilir."*
- **Farklılaşma:** Yapay zeka destekli koç (kural motoru + AI mesaj katmanı) +
  birleşik tek uygulama deneyimi. Veri girişi manuel kalır (soru/deneme/net) — yeterli.
- **GÜNCELLEME (2026-06-13):** "Denemeyi fotoğrafla → otomatik net" (eski Yön A / P2)
  **iptal edildi.** Gerekçe: net hesabı için optik formdaki dolu baloncukları okumak gerekir;
  AI vision bunu güvenilir yapamaz (120 baloncuk, açı/ışık/silik kalem → yanlış net → güven kaybı).
  Manuel net girişi zaten çalışıyor ve yeterli. Fotoğraftan soru çözme de kırmızı okyanus +
  yüksek risk olduğu için yapılmıyor.

### Pazar gerekçesi (araştırma bulgusu)

- **Kalabalık/riskli alanlar:** Fotoğraf-çöz (Kunduz, Photomath — en çok şikayet: *yanlış çözüm*),
  AI koçluk (Kopilot ~3.700 TL/ay — fahiş), manuel net takibi (onlarca aynı app, yapışkan değil).
- **Boş alanlar (bizim hedefimiz):**
  1. **Denemeyi fotoğrafla → otomatik net analizi** — tüketici uygulaması olarak yok. En düşük risk.
  2. **Tek uygulamada birleşik akış** — öğrenci 3-4 ayrı app kullanıyor; Puhu parçaları zaten içeriyor.
  3. **Dürüst + uygun fiyat** — sektörün en derin güven yarası iade/iptal kâbusu.

## 2. İsim / marka kararı (onaylı)

- **Mağaza adı:** **Puhu YKS** — alt başlık: *"Yapay Zeka YKS Koçun"*
- Gerekçe: "Puhu" jenerik kelime (baykuş), tek başına PuhuTV (Doğuş, streaming) ile
  **düşük-orta** çakışma riski taşır. "YKS" eki sektörü ayırır, karışıklık argümanını çürütür.
  "AI" kelimesini isme gömmek spam sinyali + güven pozisyonunu bozar → subtitle/keyword'de taşınır.
- **Korunma adımları (P3):** TÜRKPATENT'e "Puhu" tescili (sınıf 9/41/42), PuhuTV'den belirgin
  farklı logo/renk (baykuş logosu konusunda dikkat), marka vekiline resmî sınıf sorgusu.

## 3. Parçalama ve sıra

Tüm vizyon tek plana sığmaz. Bağımsız parçalara bölündü; her biri kendi spec→plan→uygulama
döngüsünü alır.

| # | Parça | Boyut | Risk | Durum |
|---|---|---|---|---|
| **P1** | Koçu uygulamanın yüzü yap (Anasayfa = koç, dashboard sadeleştir, AI notu bağla) | Küçük | Düşük | ✅ Tamam |
| **P3** | "Puhu YKS" rebrand (app adı, subtitle) | Küçük | Düşük | ✅ Tamam |
| **P2** | ~~Denemeyi fotoğrafla → otomatik net analizi~~ | — | Yüksek | ❌ **İptal** |
| **P4** | ~~Fotoğraf-çöz~~ | — | Yüksek | ❌ **İptal** |

**Karar — sıra:** **P1 → P3 yapıldı. P2 ve P4 iptal edildi (2026-06-13).**

P2/P4 iptal gerekçesi: AI vision'ın optik form / soru fotoğrafını güvenilir okuyamaması →
yanlış sonuç → güven kaybı riski. Manuel veri girişi zaten yeterli. Ürünün farkı **AI koç**
(P1'de öne çıkarıldı), ek riskli özelliklere gerek yok.

Bu oturumda ayrıca yapılan ek iyileştirmeler (yol haritası dışı, kullanıcı talebiyle):
ölü kod temizliği (tasks/whats_new/calendar, ~2800 satır), eksi net düzeltmesi, Puhu+
sadeleştirme + haftalık plan Plus kilidi + AI strateji notu, koç ekranı redesign,
pomodoro dayatmasının kaldırılması (çalışma yolu seçimi).

## 4. P1 — Koçu Anasayfa yap (bu spec'in uygulanabilir kısmı)

### Amaç
Kalabalık Anasayfa'yı (7 yarışan öğe) koç-merkezli, tek odaklı bir ekrana dönüştür. Koç
artık ikincil bir `/coach` push-route'u değil, uygulamanın açılış yüzü.

### Mevcut durum
- Alt menü: Anasayfa(dashboard) / Dersler / Çalış / Soru / Analiz. Koç navigasyonda yok.
- `DashboardView` (745 satır): countdown + streak hero + Soru Ekle + koç baloncuğu (sadece
  `rec.title`) + günlük hedef/bugün + hata kartı + Puhu+ promo.
- `CoachView` (`/coach`): maskot + (AI notu üretebiliyor) + bugün hero + zayıf dersler + haftalık plan.
- Veri hazır: `coachReportProvider`, `todayRecommendationProvider`, `aiSummarizerProvider`.

### Hedef düzen (onaylı mockup — `layout-before-after.html`)
Anasayfa, yukarıdan aşağıya:
1. **İnce üst şerit:** geri sayım (SAY · 7 gün) + streak (1 gün) — küçük, ikincil.
2. **Maskot + AI koç notu:** `aiSummarizerProvider.generateCoachNote(...)` çıktısı (2-3 cümle,
   kişisel). AI yoksa/yüklenirken `rec.title` fallback. Cache + rate-limit mevcut altyapıdan.
3. **"Bugün Yap" hero:** `todayRecommendation` (başlık + süre + Başla butonu → `actionRoute`).
4. **İkincil satır:** sıradaki zayıf ders kısa.
5. **Hızlı eylemler:** Soru Ekle + Haftalık plan (→ koç detay).
6. Hata sepeti / Puhu+ promo: en alta iner ya da yalnızca tetikleyici anda.

### Yaklaşım
`DashboardView`'i yeniden düzenle (ayrı yeni ekran açmaktansa, mevcut veri bağlamasını koru):
countdown ve streak'i kompakt şeride indir, koç notu + bugün hero'yu üste al, tekrarlayan maskot
baloncuğunu kaldır, hata/promo'yu aşağı it. `CoachView` tam detay sayfası olarak `/coach`'ta kalır
("Haftalık plan" oradan açılır). Nav etiketi "Anasayfa" kalır (koç = ana deneyim, ayrı sekme değil).

### Sınırlar / YAGNI
- Yeni veri modeli yok. Yeni route yok. Sadece Anasayfa yeniden düzeni + AI notu bağlama.
- AI notu sadece Anasayfa hero'sunda; tüm uygulamaya AI serpiştirme yok.

### Doğrulama
- Simülatörde Anasayfa: şerit + AI notu (veya fallback) + bugün hero + hızlı eylemler görünür,
  kalabalık dağılmış. `flutter analyze` temiz. AI tier yokken fallback düzgün çalışır.

## 5. Yayın öncesi kullanıcı işleri (kodla bitmez)
- **TestFlight:** Premium (Puhu+) akışını sandbox hesapla doğrula (haftalık plan açılıyor mu, AI notu geliyor mu).
- **Mağaza metası:** App Store Connect + Play Console → ad "Puhu YKS", alt başlık "Yapay Zeka YKS Koçun".
- **Marka tescili (opsiyonel):** "Puhu" — eğitim sınıfları 9/41/42, marka vekiliyle.
