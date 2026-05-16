/// Birincil "Güncelle" aksiyonunun sonucu.
enum PlayUpdateActionResult {
  /// Play tam ekran güncelleme tamamlandı veya esnek güncelleme başlatıldı.
  completedInApp,

  /// Kullanıcı mağazaya veya market URI'ına yönlendirildi.
  openedStore,

  /// Kullanıcı güncellemeyi iptal etti.
  userDeclined,

  /// Bu platformda işlem yok (web / masaüstü).
  unsupported,
}
