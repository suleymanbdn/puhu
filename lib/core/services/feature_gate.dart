import 'package:flutter/material.dart';

import '../../features/paywall/views/paywall_view.dart';

/// Ücretsiz sürümün sayısal sınırları.
///
/// NOT (v1.2.0): Soru günlüğü limiti KALDIRILDI. Soru kaydı uygulamanın
/// core loop'u — kilitlemek kullanıcıyı ilk gün kaybettirir. Premium değer
/// artık analiz tarafında: tüm deneme geçmişi, zayıf konu analizi, grafikler.
class FreeLimits {
  FreeLimits._();

  /// Ücretsiz kullanıcıya gösterilen en yeni deneme sayısı.
  static const int mockExamsVisible = 2;
}

/// Premium (Puhu+) ile açılan özellikler.
enum PremiumFeature {
  /// Tüm deneme geçmişi + hedef-progres grafikleri.
  fullMockHistory,

  /// Branş bazlı zayıf konu analizi.
  weakTopicAnalysis,

  /// Gelişmiş istatistik grafikleri.
  advancedCharts,

  /// Aylık 5 streak freeze (ücretsizde 2).
  extraStreakFreeze,

  /// Özel temalar ve uygulama ikonları.
  customThemes,

  /// PDF rapor dışa aktarma.
  pdfExport,
}

extension PremiumFeatureInfo on PremiumFeature {
  /// Paywall'da gösterilecek kısa başlık.
  String get title {
    switch (this) {
      case PremiumFeature.fullMockHistory:
        return 'Tüm deneme geçmişi';
      case PremiumFeature.weakTopicAnalysis:
        return 'Zayıf konu analizi';
      case PremiumFeature.advancedCharts:
        return 'Gelişmiş grafikler';
      case PremiumFeature.extraStreakFreeze:
        return 'Ayda 5 streak dondurma';
      case PremiumFeature.customThemes:
        return 'Özel tema ve ikonlar';
      case PremiumFeature.pdfExport:
        return 'PDF rapor dışa aktarma';
    }
  }
}

/// Puhu+ paywall ekranını tam ekran modal olarak açar.
Future<void> showPaywall(
  BuildContext context, {
  PremiumFeature? feature,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PaywallView(highlightFeature: feature),
    ),
  );
}
