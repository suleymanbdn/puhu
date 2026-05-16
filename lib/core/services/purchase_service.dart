import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/revenuecat_config.dart';

/// Satın alma katmanının anlık durumu.
@immutable
class PurchaseState {
  const PurchaseState({
    this.isPremium = false,
    this.isLoading = false,
    this.offering,
    this.error,
  });

  /// Kullanıcının premium (Baykuş+) erişimi var mı?
  final bool isPremium;

  /// Offering / satın alma işlemi sürüyor mu?
  final bool isLoading;

  /// RevenueCat'ten gelen varsayılan offering (paket listesi).
  final Offering? offering;

  /// Son hata mesajı (kullanıcıya göstermek için).
  final String? error;

  /// RevenueCat yapılandırılmış mı? (API key placeholder değil mi)
  bool get isAvailable => RevenueCatConfig.isConfigured;

  PurchaseState copyWith({
    bool? isPremium,
    bool? isLoading,
    Offering? offering,
    String? error,
    bool clearError = false,
  }) {
    return PurchaseState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      offering: offering ?? this.offering,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// RevenueCat satın alma akışını yöneten Riverpod notifier'ı.
///
/// Uygulama açılışında [configureSdk] çağrılmış olmalıdır.
class PurchaseNotifier extends Notifier<PurchaseState> {
  @override
  PurchaseState build() {
    if (RevenueCatConfig.isConfigured) {
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      ref.onDispose(() {
        Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
      });
      // Asenkron ilk yükleme.
      Future.microtask(refresh);
    }
    return const PurchaseState();
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    state = state.copyWith(isPremium: _hasPremium(info));
  }

  bool _hasPremium(CustomerInfo info) {
    final entitlement =
        info.entitlements.all[RevenueCatConfig.premiumEntitlement];
    return entitlement?.isActive ?? false;
  }

  /// Premium durumunu ve offering'leri RevenueCat'ten yeniden çeker.
  Future<void> refresh() async {
    if (!RevenueCatConfig.isConfigured) return;
    try {
      final info = await Purchases.getCustomerInfo();
      Offering? offering;
      try {
        final offerings = await Purchases.getOfferings();
        offering = offerings.current ??
            offerings.getOffering(RevenueCatConfig.defaultOffering);
      } on PlatformException catch (e) {
        debugPrint('Offerings yüklenemedi: $e');
      }
      state = state.copyWith(
        isPremium: _hasPremium(info),
        offering: offering,
        clearError: true,
      );
    } on PlatformException catch (e) {
      debugPrint('Satın alma durumu yüklenemedi: $e');
      state = state.copyWith(error: e.message);
    }
  }

  /// Verilen paketi satın alır. Başarılıysa true döner.
  Future<bool> purchasePackage(Package package) async {
    if (!RevenueCatConfig.isConfigured) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await Purchases.purchasePackage(package);
      final premium = _hasPremium(info);
      state = state.copyWith(isPremium: premium, isLoading: false);
      return premium;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      // Kullanıcı iptal ettiyse hata gösterme.
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Satın alma tamamlanamadı. Lütfen tekrar deneyin.',
      );
      return false;
    }
  }

  /// Önceki satın almaları geri yükler. Premium aktifse true döner.
  Future<bool> restorePurchases() async {
    if (!RevenueCatConfig.isConfigured) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await Purchases.restorePurchases();
      final premium = _hasPremium(info);
      state = state.copyWith(isPremium: premium, isLoading: false);
      return premium;
    } on PlatformException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Satın almalar geri yüklenemedi: ${e.message}',
      );
      return false;
    }
  }

  /// Hata mesajını temizler.
  void clearError() => state = state.copyWith(clearError: true);
}

/// Satın alma durumunu sağlayan global provider.
final purchaseProvider =
    NotifierProvider<PurchaseNotifier, PurchaseState>(PurchaseNotifier.new);

/// Sadece premium olup olmadığını dinlemek için kısayol provider.
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(purchaseProvider.select((s) => s.isPremium));
});

/// RevenueCat SDK'sını yapılandırır. Uygulama açılışında bir kez çağrılır.
Future<void> configureRevenueCat() async {
  if (!RevenueCatConfig.isConfigured) {
    debugPrint('RevenueCat API key girilmemiş — satın alma devre dışı.');
    return;
  }
  try {
    await Purchases.setLogLevel(
      kDebugMode ? LogLevel.debug : LogLevel.warn,
    );
    final apiKey = Platform.isIOS
        ? RevenueCatConfig.iosApiKey
        : RevenueCatConfig.androidApiKey;
    await Purchases.configure(PurchasesConfiguration(apiKey));
  } on PlatformException catch (e) {
    debugPrint('RevenueCat yapılandırılamadı: $e');
  }
}
