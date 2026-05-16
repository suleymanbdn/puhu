import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/revenuecat_config.dart';
import '../../../core/services/feature_gate.dart';
import '../../../core/services/purchase_service.dart';

/// Baykuş+ premium tanıtım / satın alma ekranı.
class PaywallView extends ConsumerStatefulWidget {
  const PaywallView({super.key, this.highlightFeature});

  /// Paywall'ı tetikleyen özellik (vurgulanır).
  final PremiumFeature? highlightFeature;

  @override
  ConsumerState<PaywallView> createState() => _PaywallViewState();
}

class _PaywallViewState extends ConsumerState<PaywallView> {
  /// Seçili plan: 0 = aylık, 1 = yıllık, 2 = lifetime.
  int _selected = 1;

  static const _privacyUrl = 'https://github.com/suleymanbdn';
  static const _termsUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final purchase = ref.watch(purchaseProvider);
    final plans = _buildPlans(purchase.offering);

    // Premium zaten aktifse teşekkür ekranı.
    if (purchase.isPremium) {
      return _PremiumActiveScreen(onClose: () => Navigator.of(context).pop());
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.xl, AppSizes.sm, AppSizes.xl, 140),
              children: [
                const SizedBox(height: 40),
                _buildHeader(theme),
                const SizedBox(height: AppSizes.xl),
                _buildFeatureList(theme),
                const SizedBox(height: AppSizes.xl),
                ...List.generate(plans.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: _PlanCard(
                      plan: plans[i],
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                  );
                }),
                const SizedBox(height: AppSizes.sm),
                _buildLegal(theme),
              ],
            ),
            // Kapatma butonu
            Positioned(
              top: AppSizes.xs,
              right: AppSizes.xs,
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                color: theme.colorScheme.onSurfaceVariant,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            // Alt sabit CTA
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomCta(theme, plans, purchase),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusXl),
          ),
          child: const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 40),
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Baykuş+', style: theme.textTheme.headlineLarge),
        const SizedBox(height: AppSizes.xs),
        Text(
          'YKS yolculuğunu tam potansiyelinle sürdür',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureList(ThemeData theme) {
    const features = PremiumFeature.values;
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: features.map((f) {
          final highlighted = f == widget.highlightFeature;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: AppSizes.iconMd,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    f.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          highlighted ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(
                      'Bunun için',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomCta(
    ThemeData theme,
    List<_PlanOption> plans,
    PurchaseState purchase,
  ) {
    final plan = plans[_selected];
    final ctaText = plan.hasTrial
        ? '3 Gün Ücretsiz Dene'
        : 'Baykuş+ Edin';

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.xl, AppSizes.md, AppSizes.xl, AppSizes.lg),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (purchase.error != null) ...[
            Text(
              purchase.error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  purchase.isLoading ? null : () => _onPurchase(plan),
              child: purchase.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(ctaText),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          TextButton(
            onPressed: purchase.isLoading ? null : _onRestore,
            child: const Text('Satın Alımları Geri Yükle'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegal(ThemeData theme) {
    final style = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      children: [
        Text(
          'Abonelikler dönem sonunda otomatik yenilenir. İstediğin zaman '
          'mağaza ayarlarından iptal edebilirsin. Lifetime tek seferlik '
          'ödemedir, yenilenmez.',
          style: style,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSizes.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => _openUrl(_termsUrl),
              child: Text('Kullanım Şartları', style: style),
            ),
            Text('•', style: style),
            TextButton(
              onPressed: () => _openUrl(_privacyUrl),
              child: Text('Gizlilik', style: style),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onPurchase(_PlanOption plan) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (plan.package == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Satın alma şu anda kullanılamıyor. Lütfen daha '
            'sonra tekrar deneyin.'),
      ));
      return;
    }
    final success =
        await ref.read(purchaseProvider.notifier).purchasePackage(plan.package!);
    if (success && mounted) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Baykuş+ aktifleştirildi 🎉'),
      ));
      navigator.maybePop();
    }
  }

  Future<void> _onRestore() async {
    final messenger = ScaffoldMessenger.of(context);
    final restored =
        await ref.read(purchaseProvider.notifier).restorePurchases();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(restored
          ? 'Baykuş+ geri yüklendi 🎉'
          : 'Aktif bir abonelik bulunamadı.'),
    ));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// RevenueCat offering'inden plan listesi oluşturur.
  /// Offering yoksa plana göre statik fallback fiyatlar kullanılır.
  List<_PlanOption> _buildPlans(Offering? offering) {
    Package? pkgFor(String productId, PackageType type) {
      if (offering == null) return null;
      for (final p in offering.availablePackages) {
        if (p.storeProduct.identifier == productId ||
            p.packageType == type) {
          return p;
        }
      }
      return null;
    }

    final monthly =
        pkgFor(RevenueCatConfig.productMonthly, PackageType.monthly);
    final yearly =
        pkgFor(RevenueCatConfig.productYearly, PackageType.annual);
    final lifetime =
        pkgFor(RevenueCatConfig.productLifetime, PackageType.lifetime);

    return [
      _PlanOption(
        title: 'Aylık',
        priceLabel: monthly?.storeProduct.priceString ?? '₺49,99',
        periodLabel: '/ ay',
        package: monthly,
      ),
      _PlanOption(
        title: 'Yıllık',
        priceLabel: yearly?.storeProduct.priceString ?? '₺299,99',
        periodLabel: '/ yıl',
        subtitle: 'Ayda ₺25 — %50 tasarruf',
        badge: 'EN AVANTAJLI',
        package: yearly,
      ),
      _PlanOption(
        title: 'YKS\'ye Kadar',
        priceLabel: lifetime?.storeProduct.priceString ?? '₺449,99',
        periodLabel: 'tek seferlik',
        subtitle: 'Abonelik yok — bir kez öde',
        package: lifetime,
      ),
    ];
  }
}

/// Tek bir satın alma planının görsel modeli.
class _PlanOption {
  const _PlanOption({
    required this.title,
    required this.priceLabel,
    required this.periodLabel,
    this.subtitle,
    this.badge,
    this.package,
  });

  final String title;
  final String priceLabel;
  final String periodLabel;
  final String? subtitle;
  final String? badge;
  final Package? package;

  /// Pakette ücretsiz deneme süresi tanımlı mı?
  bool get hasTrial =>
      package?.storeProduct.introductoryPrice?.price == 0;
}

/// Seçilebilir plan kartı.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _PlanOption plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: selected ? accent : theme.colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? accent : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(plan.title, style: theme.textTheme.titleMedium),
                      if (plan.badge != null) ...[
                        const SizedBox(width: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
                          ),
                          child: Text(
                            plan.badge!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (plan.subtitle != null)
                    Text(
                      plan.subtitle!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(plan.priceLabel, style: theme.textTheme.titleMedium),
                Text(plan.periodLabel, style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium zaten aktifken gösterilen teşekkür ekranı.
class _PremiumActiveScreen extends StatelessWidget {
  const _PremiumActiveScreen({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: AppSizes.lg),
                Text('Baykuş+ aktif', style: theme.textTheme.headlineMedium),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Tüm premium özelliklere erişimin var. '
                  'YKS yolculuğunda başarılar!',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xl),
                FilledButton(onPressed: onClose, child: const Text('Kapat')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
