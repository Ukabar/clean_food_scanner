class AppConstants {
  const AppConstants._();

  static const appName = 'Labelora: Food Scanner';
  static const tagline = 'Scan food. Understand ingredients. Choose better.';
  static const openFoodFactsBaseUrl = 'https://world.openfoodfacts.org';
  static const fatSecretProxyBaseUrl = String.fromEnvironment(
    'FATSECRET_PROXY_BASE_URL',
  );
  static const userAgent = 'LabeloraFoodScanner/1.0 Flutter mobile app';
  static const cacheDuration = Duration(hours: 24);
  static const scanDebounce = Duration(seconds: 4);
  static const maxHistoryItems = 50;
  static const privacyPolicyUrl = 'https://example.com/privacy-policy';
  static const termsUrl = 'https://example.com/terms-of-use';
}
