/// Statut de mémorisation d'un verset.
enum MemorizationStatus {
  notStarted,
  memorizing,
  memorized,
  needsReview,
}

extension MemorizationStatusX on MemorizationStatus {
  String get storageKey => name;

  static MemorizationStatus fromStorage(String? value) {
    if (value == null) return MemorizationStatus.notStarted;
    return MemorizationStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MemorizationStatus.notStarted,
    );
  }
}
