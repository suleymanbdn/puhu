# Puhu YKS — Yapay Zeka YKS Koçu: Ürün Yönü ve Yol Haritası

**Tarih:** 2026-06-13
**Durum:** Onaylandı (yön + isim + parçalama). P1 uygulamaya hazır.

## 1. Ürün kararı (onaylı)

Puhu bir **YKS çalışma takip uygulamasından**, **yapay zeka destekli YKS koçuna** dönüşüyor.

- **Felsefe (kodda zaten var):** Kural motoru (`AlgorithmicCoach`) kullanıcı verisinden
  gerçekleri çıkarır; AI katmanı (`AiSummarizer` → Groq/Gemini) bunları kişisel,
  motive edici, eyleme dönük mesaja çevirir. *"Kural motoru ne söyleyeceğini bilir,
  AI nasıl söyleyeceğini bilir."*
- **Seçilen yön (A):** Manuel veri girişi sürtünmesini öldür. Bunun için
  **denemeyi fotoğrafla → otomatik net analizi** (AI sadece okur, çözmez → düşük risk).
  Fotoğraftan **soru çözme** kırmızı okyanus + yüksek güven riski olduğu için **2. faza** atıldı.

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

| # | Parça | Boyut | Risk | Bağımsız ship? |
|---|---|---|---|---|
| **P1** | Koçu uygulamanın yüzü yap (Anasayfa = koç, dashboard sadeleştir, AI notu bağla) | Küçük | Düşük | Evet |
| **P2** | Denemeyi fotoğrafla → otomatik net analizi (AI vision → `MockExam.subjectNets`) | Orta-büyük | **Yüksek (AI doğruluk)** | Evet |
| **P3** | "Puhu YKS" rebrand (app adı, mağaza metası, subtitle, logo notu, tescil) | Küçük | Düşük | Evet |
| **P4** | *(sonra)* Fotoğraf-çöz — güven öncelikli, "emin değilim" diyebilen | — | Yüksek | — |

**Karar — sıra:** **P1 → P3 → P2 → P4.**

Gerekçe (P2'yi öne almak yerine): P1 düşük riskli, var olan `CoachView`/`coachReportProvider`'ı
kullanır, anında görünür değer üretir ve uygulamayı bugün iyileştirir. P2 ürünün asıl farkı ama
**en riskli bilinmeyeni** — AI'ın Türkçe optik/cevap kâğıdını güvenilir okuyup okuyamayacağı.
P2'ye tam plan yazmadan önce **gerçek bir optik fotoğrafıyla fizibilite testi (spike)** yapılmalı.
Bu doğrulanmadan P2 build'ine girmek riskli. → **Kullanıcıdan gerçek deneme optik/cevap kâğıdı
örneği gerekiyor (DANIŞMA NOKTASI).** P3 küçük olduğu için P2 spike'ı beklerken araya alınır.

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

## 5. Açık danışma noktaları
- **P2 öncesi:** Gerçek deneme optik/cevap kâğıdı fotoğrafı örneği (AI vision fizibilitesi için).
- **P3:** Marka tescili kullanıcı kararı (vekil/maliyet).
