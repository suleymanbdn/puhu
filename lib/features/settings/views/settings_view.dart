import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/feature_gate.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/services/settings_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../coach/providers/ai_provider.dart';
import '../../exam/providers/exam_profile_provider.dart';
import '../../whats_new/views/whats_new_sheet.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final profile = ref.watch(examProfileProvider);
    final profileNotifier = ref.read(examProfileProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
          // ============= BAYKUŞ+ =============
          const _SectionTitle(title: 'Puhu+'),
          const _PremiumSettingsCard(),
          const SizedBox(height: 24),

          // ============= YKS PROFİL =============
          if (profile != null) ...[
            const _SectionTitle(title: 'YKS Profili'),
            GlassContainer(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: profile.examType.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(profile.examType.icon,
                            color: profile.examType.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.examType.title,
                                style: textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              '${profile.daysUntilExam} gün kaldı',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sınav tarihi
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.event_outlined,
                        color: colorScheme.primary),
                    title: Text('Sınav Tarihi',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      DateFormat('d MMMM yyyy', 'tr_TR')
                          .format(profile.examDate),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: profile.examDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        await profileNotifier.updateExamDate(picked);
                        await NotificationService.instance
                            .scheduleExamReminders(picked);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  // Günlük hedef
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.flag_outlined,
                                color: colorScheme.primary, size: 20),
                            const SizedBox(width: 12),
                            Text('Günlük Hedef',
                                style: textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text(
                              '${profile.dailyTargetHours.toStringAsFixed(1)} sa',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: profile.dailyTargetHours,
                          min: 1,
                          max: 12,
                          divisions: 22,
                          label:
                              '${profile.dailyTargetHours.toStringAsFixed(1)} sa',
                          onChanged: (v) async {
                            await profileNotifier.updateDailyTarget(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Hedef bilgileri
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.school_outlined,
                        color: colorScheme.primary),
                    title: Text('Hedef',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      [
                        if (profile.targetUniversity != null)
                          profile.targetUniversity!,
                        if (profile.targetDepartment != null)
                          profile.targetDepartment!,
                        if (profile.targetNet != null)
                          '${profile.targetNet!.toStringAsFixed(0)} net',
                      ].join(' • '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showTargetDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Profil sıfırla
            TextButton.icon(
              onPressed: () => _confirmReset(context, ref),
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Profili Sıfırla (Onboarding)'),
            ),
          ],

          const SizedBox(height: 24),
          // ============= POMODORO =============
          const _SectionTitle(title: 'Pomodoro Süreleri'),
          _DurationTile(
            title: 'Çalışma (Odak)',
            value: settings.workDuration,
            icon: Icons.work_outline_rounded,
            color: colorScheme.primary,
            onChanged: (val) => notifier.setWorkDuration(val.round()),
            min: 5,
            max: 120,
          ),
          _DurationTile(
            title: 'Kısa Mola',
            value: settings.shortBreakDuration,
            icon: Icons.coffee_outlined,
            color: const Color(0xFF10B981),
            onChanged: (val) => notifier.setShortBreakDuration(val.round()),
            min: 1,
            max: 30,
          ),
          _DurationTile(
            title: 'Uzun Mola',
            value: settings.longBreakDuration,
            icon: Icons.weekend_outlined,
            color: const Color(0xFF8B5CF6),
            onChanged: (val) => notifier.setLongBreakDuration(val.round()),
            min: 5,
            max: 60,
          ),

          const SizedBox(height: 24),
          // ============= YAPAY ZEKA (BYOK) =============
          const _SectionTitle(title: 'Yapay Zeka Koçluğu'),
          GlassContainer(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: const _GeminiKeySection(),
          ),

          const SizedBox(height: 24),
          // ============= GÖRÜNÜM =============
          const _SectionTitle(title: 'Görünüm'),
          GlassContainer(
            padding: const EdgeInsets.all(12),
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: _ThemeSelector(
              current: ref.watch(themeModeNotifierProvider),
              onChanged: (mode) => ref
                  .read(themeModeNotifierProvider.notifier)
                  .setThemeMode(mode),
            ),
          ),

          const SizedBox(height: 24),
          // ============= AKIŞ + BİLDİRİM =============
          const _SectionTitle(title: 'Akış ve Bildirimler'),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Otomatik Geçiş',
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Süre bitince mola/çalışma otomatik başlasın',
                      style: textTheme.bodySmall),
                  value: settings.autoFlow,
                  onChanged: notifier.setAutoFlow,
                  activeThumbColor: colorScheme.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
                Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withAlpha(50)),
                SwitchListTile(
                  title: Text('Bildirimler',
                      style: textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      'Pomodoro, tekrar ve sınav uyarıları',
                      style: textTheme.bodySmall),
                  value: settings.notificationsEnabled,
                  onChanged: (v) async {
                    notifier.setNotificationsEnabled(v);
                    if (!v) {
                      await NotificationService.instance.cancelAll();
                    } else if (profile != null) {
                      await NotificationService.instance
                          .scheduleExamReminders(profile.examDate);
                      await NotificationService.instance
                          .scheduleDailyReminder();
                      await NotificationService.instance
                          .scheduleStreakBreakReminder();
                      await NotificationService.instance
                          .scheduleMistakeReviewReminder();
                    }
                  },
                  activeThumbColor: colorScheme.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // ============= EKSTRA =============
          const _SectionTitle(title: 'Diğer'),
          ListTile(
            leading: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.focus),
            title: const Text('Kişisel Koç'),
            subtitle:
                const Text('Bugün önerisi, haftalık plan, ders skorları'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/coach'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colorScheme.surface,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.bookmark_outline_rounded,
                color: AppColors.danger),
            title: const Text('Hata Sepeti'),
            subtitle: const Text(
                'Yanlışlarını sepete at, aralıklı tekrar et'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/mistakes'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colorScheme.surface,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.auto_awesome_motion_outlined,
                color: AppColors.premium),
            title: const Text('Bu Sürümde Yeni'),
            subtitle: const Text('v1.1.x güncellemesinin tüm yenilikleri'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showWhatsNewSheet(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colorScheme.surface,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('Takvim'),
            subtitle: const Text('Görev ve deneme tarihleri görünümü'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/calendar'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colorScheme.surface,
          ),
          ],
        ),
      ),
    );
  }

  void _showTargetDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(examProfileProvider);
    if (profile == null) return;

    final uniController =
        TextEditingController(text: profile.targetUniversity);
    final deptController =
        TextEditingController(text: profile.targetDepartment);
    final netController = TextEditingController(
        text: profile.targetNet?.toStringAsFixed(0) ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hedef Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uniController,
              decoration: const InputDecoration(labelText: 'Üniversite'),
            ),
            TextField(
              controller: deptController,
              decoration: const InputDecoration(labelText: 'Bölüm'),
            ),
            TextField(
              controller: netController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hedef Net'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              await ref.read(examProfileProvider.notifier).updateTarget(
                    university: uniController.text.trim().isEmpty
                        ? null
                        : uniController.text.trim(),
                    department: deptController.text.trim().isEmpty
                        ? null
                        : deptController.text.trim(),
                    targetNet: double.tryParse(
                        netController.text.replaceAll(',', '.')),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili Sıfırla'),
        content: const Text(
            'Sınav profilin silinecek ve onboarding ekranı tekrar gösterilecek. Çalışma verilerin (konular, sorular, denemeler) silinmez.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              await ref.read(examProfileProvider.notifier).reset();
              await NotificationService.instance.cancelAll();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.go('/onboarding');
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }
}

/// Ayarlar ekranındaki Puhu+ üyelik kartı.
class _PremiumSettingsCard extends ConsumerWidget {
  const _PremiumSettingsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final purchase = ref.watch(purchaseProvider);

    if (purchase.isPremium) {
      return GlassContainer(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_rounded,
                color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Puhu+ Üyesi',
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    'Tüm premium özelliklere erişimin var',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded,
                color: theme.colorScheme.primary),
          ],
        ),
      );
    }

    return Column(
      children: [
        InkWell(
          onTap: () => showPaywall(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Puhu+ Edin',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                      Text(
                        'Sınırsız özellik, reklamsız deneyim',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final restored = await ref
                .read(purchaseProvider.notifier)
                .restorePurchases();
            messenger.showSnackBar(SnackBar(
              content: Text(restored
                  ? 'Puhu+ geri yüklendi 🎉'
                  : 'Aktif bir abonelik bulunamadı.'),
            ));
          },
          child: const Text('Satın Alımları Geri Yükle'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _DurationTile extends StatelessWidget {
  const _DurationTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$value dk',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withAlpha(50),
              thumbColor: color,
              overlayColor: color.withAlpha(30),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tema seçici — 3 segmentli (Sistem / Aydınlık / Karanlık).
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.current,
    required this.onChanged,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final options = <(ThemeMode, IconData, String)>[
      (ThemeMode.system, Icons.brightness_auto_outlined, 'Sistem'),
      (ThemeMode.light, Icons.light_mode_outlined, 'Aydınlık'),
      (ThemeMode.dark, Icons.dark_mode_outlined, 'Karanlık'),
    ];

    return Row(
      children: options.map((opt) {
        final (mode, icon, label) = opt;
        final selected = current == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withAlpha(60),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Gemini API key (BYOK) bölümü — kullanıcı ücretsiz key'ini yapıştırır.
///
/// Gizlilik notu: key sadece kullanıcının cihazında SharedPreferences'ta
/// saklanır; Puhu sunucusu yok, anahtar başkasıyla paylaşılmaz.
class _GeminiKeySection extends ConsumerStatefulWidget {
  const _GeminiKeySection();

  @override
  ConsumerState<_GeminiKeySection> createState() => _GeminiKeySectionState();
}

class _GeminiKeySectionState extends ConsumerState<_GeminiKeySection> {
  late final TextEditingController _ctl;
  bool _obscured = true;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _ctl = TextEditingController(text: ref.read(geminiApiKeyProvider));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(geminiApiKeyProvider.notifier).setKey(_ctl.text);
    setState(() => _editing = false);
  }

  Future<void> _clear() async {
    _ctl.text = '';
    await ref.read(geminiApiKeyProvider.notifier).setKey('');
    setState(() => _editing = false);
  }

  String _maskKey(String key) {
    if (key.isEmpty) return '';
    if (key.length <= 8) return '${'•' * (key.length - 4)}${key.substring(key.length - 4)}';
    return '${'•' * 8}${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stored = ref.watch(geminiApiKeyProvider);
    final hasKey = stored.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: AppColors.focus, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gemini ücretsiz katmanı (BYOK)',
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (hasKey && !_editing)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.subtleOf(AppColors.success),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AKTİF',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Kendi ücretsiz Gemini key\'ini bağlarsan koç notu ve konu özeti '
          'üretebilir. Key sadece cihazında saklanır.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final url = Uri.parse('https://aistudio.google.com/app/apikey');
            await launchUrlIfPossible(url);
          },
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded,
                  size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                'Ücretsiz key al → aistudio.google.com',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (hasKey && !_editing) ...[
          // Mevcut key'i göster (maskelenmiş) + düzenle/sil
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.key_rounded,
                    size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _maskKey(stored),
                    style: textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _editing = true),
                  child: const Text('Değiştir'),
                ),
                TextButton(
                  onPressed: _clear,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Kaldır'),
                ),
              ],
            ),
          ),
        ] else ...[
          TextField(
            controller: _ctl,
            obscureText: _obscured,
            decoration: InputDecoration(
              hintText: 'AIza... ile başlayan Gemini key',
              prefixIcon: const Icon(Icons.key_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Kaydet'),
                  onPressed: _ctl.text.trim().isEmpty ? null : _save,
                ),
              ),
              if (_editing) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editing = false;
                      _ctl.text = stored;
                    });
                  },
                  child: const Text('İptal'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

Future<void> launchUrlIfPossible(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
