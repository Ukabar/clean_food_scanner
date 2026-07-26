import 'package:clean_food_scanner/core/localization/app_localizations.dart';
import 'package:clean_food_scanner/core/theme/app_theme.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/features/home/home_screen.dart';
import 'package:clean_food_scanner/features/manual/manual_barcode_entry_screen.dart';
import 'package:clean_food_scanner/features/onboarding/onboarding_screen.dart';
import 'package:clean_food_scanner/features/product/product_not_found_screen.dart';
import 'package:clean_food_scanner/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initStorage() async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  await LocalStorage.instance.initialize();
  await LocalStorage.instance.setOnboardingComplete(true);
}

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      home: child,
    ),
  );
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size, {
  double textScale = 1,
  bool settle = true,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: _wrap(child),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  setUp(_initStorage);

  testWidgets('product not found fits on a small screen', (tester) async {
    await _pumpAtSize(
      tester,
      const ProductNotFoundScreen(barcode: '12345678'),
      const Size(320, 568),
      textScale: 1.5,
    );

    expect(find.text('Product not found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home quick actions keep Favorites on one line', (tester) async {
    await _pumpAtSize(
      tester,
      const HomeScreen(),
      const Size(320, 568),
      textScale: 1.3,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_favorites_action')),
      120,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('home_favorites_action')), findsOneWidget);
  });

  testWidgets('settings fits on a small screen', (tester) async {
    await _pumpAtSize(
      tester,
      const SettingsScreen(),
      const Size(320, 568),
      textScale: 1.3,
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(834, 1194),
    const Size(1366, 1024),
  ]) {
    testWidgets('home fits iPad layout at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpAtSize(tester, const HomeScreen(), size, textScale: 1.4);

      expect(find.text('Scan smarter.'), findsOneWidget);
      expect(find.text('Scan a food product'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('settings fits iPad layout at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpAtSize(tester, const SettingsScreen(), size, textScale: 1.4);

      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'manual entry fits iPad layout at ${size.width}x${size.height}',
      (tester) async {
        await _pumpAtSize(
          tester,
          const ManualBarcodeEntryScreen(),
          size,
          textScale: 1.4,
        );

        expect(find.text('Enter barcode'), findsOneWidget);
        expect(find.text('Look up product'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('not found fits iPad layout at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const ProductNotFoundScreen(barcode: '0123456789012'),
        size,
        textScale: 1.4,
      );

      expect(find.text('Product not found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding fits iPad layout at ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpAtSize(
        tester,
        const OnboardingScreen(),
        size,
        textScale: 1.4,
        settle: false,
      );

      expect(find.text('Scan food products'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
