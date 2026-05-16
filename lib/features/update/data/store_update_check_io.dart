import 'dart:io' show Platform;

import 'package:in_app_update/in_app_update.dart';

import '../models/store_update_state.dart';

Future<StoreUpdateState> checkStoreUpdate() async {
  if (!Platform.isAndroid) {
    return StoreUpdateState.none();
  }
  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return StoreUpdateState.none();
    }
    return StoreUpdateState.updateAvailable(
      immediateUpdateAllowed: info.immediateUpdateAllowed,
      flexibleUpdateAllowed: info.flexibleUpdateAllowed,
      availableVersionCode: info.availableVersionCode,
    );
  } catch (_) {
    // Debug, Play dışı yükleme veya API hatası — uygulamayı engelleme
    return StoreUpdateState.none();
  }
}
