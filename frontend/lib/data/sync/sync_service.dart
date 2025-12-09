abstract class SyncService {
  Future<void> syncUp();
  Future<void> syncDown();
}

class NoOpSyncService implements SyncService {
  @override
  Future<void> syncDown() async {
    // TODO: Implement syncDown
    // Placeholder for future sync implementation
  }

  @override
  Future<void> syncUp() async {
    // TODO: Implement syncUp
    // Placeholder for future sync implementation
  }
}
