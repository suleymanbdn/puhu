import 'dart:io' show Platform;

import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import 'play_store_update_result.dart';

Future<void> openPlayStoreListing() async {
  if (!Platform.isAndroid) return;

  final market = Uri.parse(
    'market://details?id=${AppConstants.androidApplicationId}',
  );
  final web = Uri.parse(AppConstants.playStoreListingUrl);

  try {
    if (await canLaunchUrl(market)) {
      await launchUrl(market, mode: LaunchMode.externalApplication);
      return;
    }
  } catch (_) {}
  if (await canLaunchUrl(web)) {
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}

/// Önce tam ekran (immediate) güncellemeyi dener; olmazsa Play Store'u açar.
Future<PlayUpdateActionResult> runPrimaryPlayUpdateAction() async {
  if (!Platform.isAndroid) {
    return PlayUpdateActionResult.unsupported;
  }
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      await openPlayStoreListing();
      return PlayUpdateActionResult.openedStore;
    }
    if (info.immediateUpdateAllowed) {
      final result = await InAppUpdate.performImmediateUpdate();
      switch (result) {
        case AppUpdateResult.success:
          return PlayUpdateActionResult.completedInApp;
        case AppUpdateResult.userDeniedUpdate:
          return PlayUpdateActionResult.userDeclined;
        case AppUpdateResult.inAppUpdateFailed:
          await openPlayStoreListing();
          return PlayUpdateActionResult.openedStore;
      }
    }
    await openPlayStoreListing();
    return PlayUpdateActionResult.openedStore;
  } catch (_) {
    await openPlayStoreListing();
    return PlayUpdateActionResult.openedStore;
  }
}
