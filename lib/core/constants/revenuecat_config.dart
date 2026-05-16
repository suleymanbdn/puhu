/// RevenueCat yapılandırması — API key'leri ve ürün kimlikleri.
///
/// API key'leri RevenueCat panelinde "Baykuş" projesi oluşturulduktan sonra
/// alınır (Project Settings > API Keys > Public app-specific keys).
class RevenueCatConfig {
  RevenueCatConfig._();

  /// iOS public SDK key (appl_... ile başlar).
  /// RevenueCat > Baykuş projesi > Apple App Store app > Public SDK key.
  static const String iosApiKey = 'appl_cOBdtUyoRibMFFVMWlFpspRehOh';

  /// Android public SDK key (goog_... ile başlar).
  /// RevenueCat > Baykuş projesi > Google Play app > Public SDK key.
  static const String androidApiKey = 'goog_PLACEHOLDER_ANDROID_KEY';

  /// Premium erişimi temsil eden entitlement kimliği.
  /// RevenueCat > Entitlements bölümünde bu isimle oluşturulmalı.
  static const String premiumEntitlement = 'premium';

  /// RevenueCat'te kullanılan offering kimliği (varsayılan).
  static const String defaultOffering = 'default';

  // Ürün kimlikleri (App Store Connect + Play Console ile birebir aynı).
  static const String productMonthly = 'baykus_premium_monthly';
  static const String productYearly = 'baykus_premium_yearly';
  static const String productLifetime = 'baykus_premium_lifetime';

  /// API key'lerin gerçek değerlerle doldurulup doldurulmadığını kontrol eder.
  /// Placeholder ise satın alma akışı devre dışı bırakılır.
  static bool get isConfigured =>
      !iosApiKey.contains('PLACEHOLDER') &&
      !androidApiKey.contains('PLACEHOLDER');
}
