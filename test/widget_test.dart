// Baykuş — temel smoke testleri.

import 'package:baykus/core/constants/app_constants.dart';
import 'package:baykus/core/services/feature_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Uygulama sabitleri tanımlı', () {
    expect(AppConstants.appName, 'Baykuş');
    expect(AppConstants.androidApplicationId, 'com.zamanyonetimi.app');
  });

  test('Ücretsiz sürüm limitleri makul', () {
    expect(FreeLimits.questionLogsPerDay, greaterThan(0));
    expect(FreeLimits.mockExamsVisible, greaterThan(0));
  });

  test('Premium özellik başlıkları boş değil', () {
    for (final feature in PremiumFeature.values) {
      expect(feature.title.isNotEmpty, isTrue);
    }
  });
}
