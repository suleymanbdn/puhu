import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Uygulama genelinde kullanılan semantic renk token'ları.
///
/// Tüm view'ler `Color(0xFFNNNNNN)` hardcoded sabitler yerine **buradan**
/// renk çekmeli. Bir kavram yeniden renklendirilirse (örn. streak rengi
/// turuncu→altın) tek noktadan değişir.
///
/// İki kullanım katmanı vardır:
/// 1. **Semantic kavramlar** (success/streak/focus/premium…): doğrudan tek
///    renk olarak `AppColors.streak` gibi erişilir.
/// 2. **Alpha skalası** (subtle/soft/medium/strong): bir rengin opacity'sini
///    sihirli sayı yerine `AppColors.alphas.soft` ile uygulamak için.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Semantic — kavramsal renkler
  // ---------------------------------------------------------------------------

  /// Başarı, tamamlanmış hedef, doğru cevap.
  static const Color success = AppTheme.success; // 0xFF10B981

  /// Uyarı, dikkat, eksik bilgi.
  static const Color warning = AppTheme.warning; // 0xFFF59E0B

  /// Hata, yanlış cevap, deneme net düşüşü.
  static const Color danger = AppTheme.danger; // 0xFFEF4444

  /// Streak (gün sayacı, motivasyon).
  static const Color streak = Color(0xFFF97316); // Orange 500

  /// Streak inaktif (bugün çalışılmadı).
  static const Color streakInactive = Color(0xFF6B7280); // Gray 500

  /// Odak/pomodoro vurgusu (çalışma seansı).
  static const Color focus = Color(0xFF6366F1); // Indigo 500

  /// Premium / Puhu+ vurgusu.
  static const Color premium = Color(0xFF8B5CF6); // Violet 500

  /// Deneme/mock exam vurgusu.
  static const Color mockExam = Color(0xFFEF4444); // Red (Apple "exam red")

  /// Konu çalışma / ders vurgusu.
  static const Color study = Color(0xFF8B5CF6); // Violet 500

  /// Hızlı eylem — soru ekle (positif aksiyon).
  static const Color quickAction = Color(0xFF10B981); // Emerald 500

  /// Hızlı eylem — analiz/grafik.
  static const Color insight = Color(0xFFF59E0B); // Amber 500

  // ---------------------------------------------------------------------------
  // Alpha skalası — opacity sihirli sayılarını kaldırır
  // ---------------------------------------------------------------------------

  /// Alpha (0-255) değerlerinin standart skalası.
  ///
  /// Kullanım: `color.withAlpha(AppColors.alpha.soft)` veya doğrudan
  /// `AppColors.softOf(color)`.
  static const alpha = _AlphaScale();

  /// Bir rengin "subtle" (zayıf/arka plan) tonunu döner.
  static Color subtleOf(Color c) => c.withAlpha(alpha.subtle);

  /// Bir rengin "soft" (yumuşak vurgu) tonunu döner.
  static Color softOf(Color c) => c.withAlpha(alpha.soft);

  /// Bir rengin "medium" (orta vurgu) tonunu döner.
  static Color mediumOf(Color c) => c.withAlpha(alpha.medium);

  /// Bir rengin "strong" (güçlü ama solid olmayan) tonunu döner.
  static Color strongOf(Color c) => c.withAlpha(alpha.strong);
}

/// Alpha (0-255) skalası. View'lerde `withAlpha(220)` gibi sihirli sayı yerine
/// `AppColors.alpha.strong` kullanılır.
class _AlphaScale {
  const _AlphaScale();

  /// ~%8 — Çok zayıf arka plan (badge/chip bg).
  final int subtle = 20;

  /// ~%14 — Yumuşak vurgu (kart bg, hover).
  final int soft = 36;

  /// ~%47 — Orta vurgu (border, divider güçlü).
  final int medium = 120;

  /// ~%70 — Güçlü ama solid olmayan (subtitle on gradient).
  final int strong = 180;

  /// ~%86 — Neredeyse solid (overlay text üstünde).
  final int near = 220;
}
