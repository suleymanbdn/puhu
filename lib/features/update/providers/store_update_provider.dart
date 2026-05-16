import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/store_update_check.dart';
import '../models/store_update_state.dart';

/// Play'de daha yeni bir sürüm varsa [StoreUpdateState.needsPrompt] true olur.
final storeUpdateCheckProvider = FutureProvider<StoreUpdateState>((ref) async {
  return checkStoreUpdate();
});
