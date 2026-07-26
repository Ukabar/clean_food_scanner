import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/favorite_item.dart';
import '../models/product_model.dart';
import '../models/scan_history_item.dart';

class LocalStorage {
  LocalStorage._();

  static final instance = LocalStorage._();

  static const _historyKey = 'scan_history';
  static const _favoritesKey = 'favorites';
  static const _cacheKey = 'product_cache';
  static const _negativeCacheKey = 'negative_product_cache';
  static const _pendingKey = 'pending_products';
  static const _onboardingKey = 'onboarding_complete';
  static const _themeKey = 'theme_mode';
  static const _languageKey = 'language_code';

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get onboardingComplete => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingComplete(bool value) =>
      _prefs.setBool(_onboardingKey, value);

  String get themeMode => _prefs.getString(_themeKey) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_themeKey, value);

  String get languageCode => _prefs.getString(_languageKey) ?? 'en';
  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_languageKey, value);

  List<ScanHistoryItem> getHistory() => _readList(_historyKey)
      .map(ScanHistoryItem.fromJson)
      .where((item) => item.barcode.isNotEmpty)
      .toList();

  Future<void> saveHistory(List<ScanHistoryItem> items) =>
      _writeList(_historyKey, items.map((item) => item.toJson()).toList());

  Future<void> upsertHistory(ScanHistoryItem item) async {
    final items = getHistory()
        .where((old) => old.barcode != item.barcode)
        .toList();
    items.insert(0, item);
    await saveHistory(items.take(AppConstants.maxHistoryItems).toList());
  }

  List<FavoriteItem> getFavorites() => _readList(_favoritesKey)
      .map(FavoriteItem.fromJson)
      .where((item) => item.barcode.isNotEmpty)
      .toList();

  Future<void> saveFavorites(List<FavoriteItem> items) =>
      _writeList(_favoritesKey, items.map((item) => item.toJson()).toList());

  Future<void> saveProduct(ProductModel product) async {
    final cache = getProductCache();
    cache[product.barcode] = product;
    final json = cache.map((key, value) => MapEntry(key, value.toJson()));
    await _prefs.setString(_cacheKey, jsonEncode(json));
  }

  ProductModel? getCachedProduct(String barcode, {Duration? maxAge}) {
    final product = getProductCache()[barcode];
    if (product == null) return null;
    final age = DateTime.now().difference(product.lastScannedAt);
    if (age > (maxAge ?? AppConstants.cacheDuration)) return null;
    return product.copyWith(isFromCache: true);
  }

  ProductModel? getAnyCachedProduct(String barcode) =>
      getProductCache()[barcode]?.copyWith(isFromCache: true);

  Map<String, ProductModel> getProductCache() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return {};
      return decoded.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, ProductModel.fromStorage(value));
        }
        return MapEntry(
          key,
          ProductModel(barcode: key, lastScannedAt: DateTime.now()),
        );
      });
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_cacheKey);
    await _prefs.remove(_negativeCacheKey);
  }

  Future<void> clearHistory() => _prefs.remove(_historyKey);

  Future<void> saveNegativeCache(
    String barcode, {
    Duration ttl = const Duration(hours: 24),
  }) async {
    final cache = _readStringMap(_negativeCacheKey);
    cache[barcode] = DateTime.now().add(ttl).toIso8601String();
    await _prefs.setString(_negativeCacheKey, jsonEncode(cache));
  }

  bool isNegativeCached(String barcode) {
    final expiresAt = DateTime.tryParse(
      _readStringMap(_negativeCacheKey)[barcode] ?? '',
    );
    if (expiresAt == null) return false;
    if (DateTime.now().isAfter(expiresAt)) return false;
    return true;
  }

  List<String> getPendingProducts() =>
      _prefs.getStringList(_pendingKey) ?? const [];

  Future<void> addPendingProduct(String barcode) async {
    final items = {...getPendingProducts(), barcode}.toList();
    await _prefs.setStringList(_pendingKey, items);
  }

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items));

  Map<String, String> _readStringMap(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on FormatException {
      return {};
    } on TypeError {
      return {};
    }
  }
}
