import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ar'), Locale('fr')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String get appName => 'Clean Food Scanner';
  String get tagline => 'Scan food. Understand ingredients. Choose better.';
  String get scanProduct => 'Scan a Product';
  String get history => 'History';
  String get favorites => 'Favorites';
  String get settings => 'Settings';
  String get premium => 'Premium';
  String get homeWelcome => 'Welcome back';
  String get recentScans => 'Recent scans';
  String get noScansYet => 'No scanned products yet.';
  String get productNotFound => 'Product not found';
  String get productNotFoundMessage =>
      'This product is not available in our current database yet.';
  String get scanAgain => 'Scan Again';
  String get enterBarcodeManually => 'Enter Barcode Manually';
  String get reportMissingProduct => 'Report Missing Product';
  String get retry => 'Retry';
  String get notEnoughData => 'Not enough data to calculate a reliable score.';
  String get disclaimer =>
      'This app provides general informational and educational content only. It does not provide medical advice, diagnosis, or treatment.\n\nProduct information is obtained from third-party and community-maintained databases and may be incomplete, outdated, or inaccurate.\n\nAlways verify ingredients, allergens, nutrition facts, and warnings directly on the product packaging before consumption.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
