import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/paywall/views/paywall_view.dart';
import '../../features/questions/providers/question_log_provider.dart';
import 'purchase_service.dart';

/// Ücretsiz sürümün sayısal sınırları.
class FreeLimits {
  FreeLimits._();

  /// Ücretsiz kullanıcının günde ekleyebileceği soru günlüğü kaydı sayısı.
  static const int questionLogsPerDay = 3;

  /// Ücretsiz kullanıcıya gösterilen en yeni deneme sayısı.
  static const int mockExamsVisible = 2;
}

/// Premium (Baykuş+) ile açılan özellikler.
enum PremiumFeature {
  /// Sınırsız soru günlüğü kaydı.
  unlimitedQuestionLog,

  /// Tüm deneme geçmişi + hedef-progres grafikleri.
  fullMockHistory,

  /// Branş bazlı zayıf konu analizi.
  weakTopicAnalysis,

  /// Gelişmiş istatistik grafikleri.
  advancedCharts,

  /// Özel temalar ve uygulama ikonları.
  customThemes,

  /// PDF rapor dışa aktarma.
  pdfExport,
}

extension PremiumFeatureInfo on PremiumFeature {
  /// Paywall'da gösterilecek kısa başlık.
  String get title {
    switch (this) {
      case PremiumFeature.unlimitedQuestionLog:
        return 'Sınırsız soru günlüğü';
      case PremiumFeature.fullMockHistory:
        return 'Tüm deneme geçmişi';
      case PremiumFeature.weakTopicAnalysis:
        return 'Zayıf konu analizi';
      case PremiumFeature.advancedCharts:
        return 'Gelişmiş grafikler';
      case PremiumFeature.customThemes:
        return 'Özel tema ve ikonlar';
      case PremiumFeature.pdfExport:
        return 'PDF rapor dışa aktarma';
    }
  }
}

/// Ücretsiz kullanıcının bugün kaç soru günlüğü kaydı kaldığını verir.
/// Premium kullanıcıda her zaman sınırsızdır.
final remainingQuestionLogsProvider = Provider<int>((ref) {
  if (ref.watch(isPremiumProvider)) return 9999;
  final logs = ref.watch(questionLogProvider);
  final now = DateTime.now();
  final todayCount = logs.where((l) {
    return l.date.year == now.year &&
        l.date.month == now.month &&
        l.date.day == now.day;
  }).length;
  final remaining = FreeLimits.questionLogsPerDay - todayCount;
  return remaining < 0 ? 0 : remaining;
});

/// Yeni bir soru günlüğü kaydı eklenebilir mi?
final canAddQuestionLogProvider = Provider<bool>((ref) {
  return ref.watch(remainingQuestionLogsProvider) > 0;
});

/// Baykuş+ paywall ekranını tam ekran modal olarak açar.
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
