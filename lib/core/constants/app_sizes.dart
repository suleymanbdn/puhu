/// Uygulama genelinde kullanılan boyut ve spacing sabitleri
///
/// Tüm padding, margin, border radius ve ikon boyutlarında
/// bu sınıfın sabitlerini kullan — magic number kullanma.
class AppSizes {
  AppSizes._();

  // ===========================================================================
  // SPACING
  // ===========================================================================

  /// 4px — en küçük boşluk
  static const double xs = 4.0;

  /// 8px — küçük boşluk
  static const double sm = 8.0;

  /// 12px — orta-küçük boşluk
  static const double md = 12.0;

  /// 16px — standart boşluk
  static const double lg = 16.0;

  /// 24px — büyük boşluk
  static const double xl = 24.0;

  /// 32px — çok büyük boşluk
  static const double xxl = 32.0;

  /// 48px — ekstra büyük boşluk
  static const double xxxl = 48.0;

  // ===========================================================================
  // BORDER RADIUS
  // ===========================================================================

  /// 6px — çok küçük yuvarlaklık
  static const double radiusXs = 6.0;

  /// 8px — küçük yuvarlaklık
  static const double radiusSm = 8.0;

  /// 12px — orta yuvarlaklık
  static const double radiusMd = 12.0;

  /// 16px — büyük yuvarlaklık (kartlar)
  static const double radiusLg = 16.0;

  /// 20px — çok büyük yuvarlaklık
  static const double radiusXl = 20.0;

  /// 24px — ekstra büyük yuvarlaklık
  static const double radiusXxl = 24.0;

  /// 999px — tam yuvarlak (pill/chip)
  static const double radiusFull = 999.0;

  // ===========================================================================
  // ICON SIZES
  // ===========================================================================

  /// 16px — küçük ikon
  static const double iconSm = 16.0;

  /// 20px — orta-küçük ikon
  static const double iconMd = 20.0;

  /// 24px — standart ikon
  static const double iconLg = 24.0;

  /// 32px — büyük ikon
  static const double iconXl = 32.0;

  // ===========================================================================
  // COMPONENT SIZES
  // ===========================================================================

  /// Bottom navigation bar yüksekliği
  static const double navBarHeight = 80.0;

  /// AppBar yüksekliği
  static const double appBarHeight = 56.0;

  /// FAB boyutu
  static const double fabSize = 56.0;

  /// Kart içi padding
  static const double cardPadding = 16.0;

  /// Liste öğesi min yüksekliği
  static const double listItemMinHeight = 56.0;

  /// Circular progress göstergesi boyutu
  static const double circularIndicatorSize = 48.0;

  // ===========================================================================
  // BORDER WIDTH
  // ===========================================================================

  /// İnce kenarlık (0.5px)
  static const double borderThin = 0.5;

  /// Normal kenarlık (1px)
  static const double borderNormal = 1.0;

  /// Kalın kenarlık (2px)
  static const double borderThick = 2.0;
}
