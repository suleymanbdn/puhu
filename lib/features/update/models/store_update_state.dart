/// Play / mağaza tarafında güncelleme gerekip gerekmediği.
class StoreUpdateState {
  const StoreUpdateState._({
    required this.needsPrompt,
    required this.immediateUpdateAllowed,
    required this.flexibleUpdateAllowed,
    this.availableVersionCode,
  });

  /// Güncelleme yok veya kontrol edilemedi.
  factory StoreUpdateState.none() => const StoreUpdateState._(
        needsPrompt: false,
        immediateUpdateAllowed: false,
        flexibleUpdateAllowed: false,
      );

  factory StoreUpdateState.updateAvailable({
    required bool immediateUpdateAllowed,
    required bool flexibleUpdateAllowed,
    int? availableVersionCode,
  }) =>
      StoreUpdateState._(
        needsPrompt: true,
        immediateUpdateAllowed: immediateUpdateAllowed,
        flexibleUpdateAllowed: flexibleUpdateAllowed,
        availableVersionCode: availableVersionCode,
      );

  final bool needsPrompt;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
  final int? availableVersionCode;
}
