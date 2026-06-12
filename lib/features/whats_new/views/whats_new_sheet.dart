import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../whats_new_data.dart';

/// SharedPreferences anahtarı — en son hangi versiyon için sheet
/// gösterildiğini tutar.
const String _kPrefsLastSeenVersion = 'whats_new_last_seen_version_v1';

/// Sheet'i kullanıcıya bir kez gösterip görüldüğünü işaretler.
/// Aynı uygulama oturumunda yeniden açılmaz.
bool _shownThisSession = false;

Future<void> maybeShowWhatsNewSheet(BuildContext context) async {
  if (_shownThisSession) return;
  final prefs = await SharedPreferences.getInstance();
  final lastSeen = prefs.getString(_kPrefsLastSeenVersion);
  if (lastSeen == kCurrentWhatsNewVersion) return;
  _shownThisSession = true;
  if (!context.mounted) return;
  await showWhatsNewSheet(context);
  await prefs.setString(_kPrefsLastSeenVersion, kCurrentWhatsNewVersion);
}

/// Sheet'i her durumda gösterir (Settings'ten manuel açılış için).
Future<void> showWhatsNewSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _WhatsNewSheet(),
  );
}

/// Sheet içeriği — şu an tek statik kayıt. İleride versiyon-anahtarlı
/// liste eklenirse buradan seçilir.
const _entry = WhatsNewEntry(
  version: kCurrentWhatsNewVersion,
  headline: 'Puhu yeniden doğdu 🎉',
  subhead: 'Bu güncellemede 15+ yeni özellik var — bir göz at.',
  items: [
    WhatsNewItem(
      icon: Icons.local_fire_department_rounded,
      title: 'Streak Dondurma',
      description: 'Bir gün çalışamadın mı? Premium kullanıcılar streak\'i '
          'donmuş gibi koruyabilir, seri kırılmaz.',
      color: AppColors.streak,
    ),
    WhatsNewItem(
      icon: Icons.bookmark_outline_rounded,
      title: 'Hata Sepeti',
      description: 'Yanlış çözdüğün soruları kaydet, aralıklı tekrarla '
          '(1-3-7-21-60 gün) hatasız çöz.',
      color: AppColors.danger,
      routeOnTap: '/mistakes',
    ),
    WhatsNewItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Kişisel Koç',
      description: 'Her dersin için 0-100 skor, haftalık plan ve bugün için '
          'tek-tıkla öneri.',
      color: AppColors.focus,
      routeOnTap: '/coach',
    ),
    WhatsNewItem(
      icon: Icons.psychology_alt_rounded,
      title: 'Puhu AI — kurulumsuz',
      description: 'Hiçbir ayar yapmadan AI koç notu ve konu özeti al — '
          'günde 10 hak, tamamen ücretsiz.',
      color: AppColors.premium,
      routeOnTap: '/coach',
    ),
    WhatsNewItem(
      icon: Icons.flash_on_rounded,
      title: 'Hızlı Soru Ekle',
      description: 'Anasayfadan tek dokunuşla doğru / yanlış / boş kaydet, '
          'akış kesilmesin.',
      color: AppColors.quickAction,
    ),
    WhatsNewItem(
      icon: Icons.notifications_active_outlined,
      title: 'Akıllı Bildirimler',
      description: 'Streak kırılma uyarısı, günlük hata tekrar hatırlatıcısı '
          've akıllı zamanlama.',
      color: AppColors.warning,
    ),
    WhatsNewItem(
      icon: Icons.palette_outlined,
      title: 'Tema Seçici',
      description: 'Açık, koyu, sistem — Ayarlar\'dan istediğin temayı seç.',
      color: AppColors.insight,
    ),
  ],
);

class _WhatsNewSheet extends StatelessWidget {
  const _WhatsNewSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final mq = MediaQuery.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.subtleOf(AppColors.focus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'v${_entry.version}',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.focus,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _entry.headline,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _entry.subhead,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Items
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: _entry.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final item = _entry.items[i];
                  return _WhatsNewTile(item: item);
                },
              ),
            ),
            // Footer CTA
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 12 + mq.viewPadding.bottom * 0),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Harika, başlayalım',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WhatsNewTile extends StatelessWidget {
  final WhatsNewItem item;
  const _WhatsNewTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.subtleOf(item.color),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.routeOnTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                context.push(item.routeOnTap!);
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (item.routeOnTap != null)
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: item.color,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
