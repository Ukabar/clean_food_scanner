import '../data/local/local_storage.dart';

class AppInitializer {
  const AppInitializer._();

  static Future<void> initialize() => LocalStorage.instance.initialize();
}
