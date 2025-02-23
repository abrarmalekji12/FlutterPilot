abstract class Migrator {
  static migrateIfNeeded(
      Future<bool> Function() isOld, Future<void> Function() migrate,
      [Future<void> Function()? normally]) async {
    if (await isOld.call()) {
      await migrate.call();
    } else {
      await normally?.call();
    }
  }
}
