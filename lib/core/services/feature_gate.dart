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
///
/// Sıra = paywall'da gösterim sırası. Hero özellik (AI haftalık program) başta.
enum PremiumFeature {
  /// AI'ın kişiye özel ürettiği haftalık çalışma programı (hero).
  aiWeeklyPlan,

  /// Branş bazlı zayıf konu analizi.
  weakTopicAnalysis,

  /// Tüm deneme geçmişi + hedef-progres grafikleri.
  fullMockHistory,

  /// Gelişmiş istatistik grafikleri.
  advancedCharts,

  /// Aylık 5 streak freeze (ücretsizde 2).
  extraStreakFreeze,
}

extension PremiumFeatureInfo on PremiumFeature {
  /// Paywall'da gösterilecek kısa başlık.
  String get title {
    switch (this) {
      case PremiumFeature.aiWeeklyPlan:
        return 'Sana özel AI haftalık program';
      case PremiumFeature.weakTopicAnalysis:
        return 'Zayıf konularına derin analiz';
      case PremiumFeature.fullMockHistory:
        return 'Tüm deneme geçmişi';
      case PremiumFeature.advancedCharts:
        return 'Gelişmiş grafikler';
      case PremiumFeature.extraStreakFreeze:
        return 'Ayda 5 streak dondurma';
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
