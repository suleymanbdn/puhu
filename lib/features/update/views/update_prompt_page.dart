import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../data/play_store_update_actions.dart';
import '../models/store_update_state.dart';

/// Mağazada güncelleme varken kullanıcıyı güncellemeye yönlendiren tam ekran sayfa.
class UpdatePromptPage extends StatefulWidget {
  const UpdatePromptPage({
    super.key,
    required this.initialState,
    required this.onRecheck,
  });

  final StoreUpdateState initialState;
  final VoidCallback onRecheck;

  @override
  State<UpdatePromptPage> createState() => _UpdatePromptPageState();
}

class _UpdatePromptPageState extends State<UpdatePromptPage> {
  bool _busy = false;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _packageInfo = info);
  }

  Future<void> _onPrimaryUpdate() async {
    setState(() => _busy = true);
    try {
      final result = await runPrimaryPlayUpdateAction();
      if (!mounted) return;
      switch (result) {
        case PlayUpdateActionResult.userDeclined:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Güncellemeyi tamamlamak için aşağıdan Play Store\'u açabilirsiniz.',
              ),
            ),
          );
          break;
        case PlayUpdateActionResult.completedInApp:
        case PlayUpdateActionResult.openedStore:
        case PlayUpdateActionResult.unsupported:
          break;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStore() async {
    setState(() => _busy = true);
    try {
      await openPlayStoreListing();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final versionLabel = _packageInfo == null
        ? '…'
        : '${_packageInfo!.version} (${_packageInfo!.buildNumber})';

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Icon(
                  Icons.system_update_rounded,
                  size: 88,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Yeni sürüm hazır',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Daha iyi performans ve düzeltmeler için uygulamayı güncellemeniz '
                  'gerekiyor. Devam etmek için Google Play üzerinden son sürümü yükleyin.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (widget.initialState.availableVersionCode != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Mağazadaki sürüm kodu: ${widget.initialState.availableVersionCode}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  'Yüklü sürüm: $versionLabel',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _onPrimaryUpdate,
                    child: _busy
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            widget.initialState.immediateUpdateAllowed
                                ? 'Şimdi güncelle'
                                : 'Play Store\'da güncelle',
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _busy ? null : _openStore,
                    child: const Text('Play Store\'u aç'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : widget.onRecheck,
                  child: const Text('Yeniden kontrol et'),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
