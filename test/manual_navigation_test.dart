import 'dart:async';

import 'package:clean_food_scanner/app/router.dart';
import 'package:clean_food_scanner/core/errors/app_exception.dart';
import 'package:clean_food_scanner/core/localization/app_localizations.dart';
import 'package:clean_food_scanner/core/theme/app_theme.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/providers.dart';
import 'package:clean_food_scanner/data/providers/food_data_provider.dart';
import 'package:clean_food_scanner/data/repositories/product_repository.dart';
import 'package:clean_food_scanner/features/home/home_screen.dart';
import 'package:clean_food_scanner/features/manual/manual_barcode_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initStorage() async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  await LocalStorage.instance.initialize();
  await LocalStorage.instance.clearCache();
  await LocalStorage.instance.clearHistory();
}

Widget _wrapWithRouter(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
    ),
  );
}

Widget _wrapWithRepository(GoRouter router, ProductRepository repository) {
  return ProviderScope(
    overrides: [productRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
    ),
  );
}

GoRouter _navigationRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const _MarkerScreen('scanner-screen'),
      ),
      GoRoute(
        path: '/manual-barcode',
        builder: (context, state) =>
            const _MarkerScreen('manual-barcode-screen'),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const _MarkerScreen('history-screen'),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const _MarkerScreen('favorites-screen'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const _MarkerScreen('settings-screen'),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const _MarkerScreen('onboarding-screen'),
      ),
    ],
  );
}

GoRouter _manualRouter() {
  return GoRouter(
    initialLocation: '/manual-barcode',
    routes: [
      GoRoute(
        path: '/manual-barcode',
        builder: (context, state) => const ManualBarcodeEntryScreen(),
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const _MarkerScreen('scanner-screen'),
      ),
      GoRoute(
        path: '/product/:barcode',
        builder: (context, state) =>
            _MarkerScreen('product-${state.pathParameters['barcode']}'),
      ),
      GoRoute(
        path: '/not-found/:barcode',
        builder: (context, state) =>
            _MarkerScreen('not-found-${state.pathParameters['barcode']}'),
      ),
    ],
  );
}

void main() {
  setUp(_initStorage);

  testWidgets('home quick actions open the expected routes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = _navigationRouter();
    await tester.pumpWidget(_wrapWithRouter(router));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_manual_action')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('home_manual_action')));
    await tester.pumpAndSettle();
    expect(find.text('manual-barcode-screen'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('home_scan_now_action')),
    );
    await tester.tap(find.byKey(const ValueKey('home_scan_now_action')));
    await tester.pumpAndSettle();
    expect(find.text('scanner-screen'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_history_action')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('home_history_action')));
    await tester.pumpAndSettle();
    expect(find.text('history-screen'), findsOneWidget);

    router.go('/');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_favorites_action')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('home_favorites_action')));
    await tester.pumpAndSettle();
    expect(find.text('favorites-screen'), findsOneWidget);
  });

  testWidgets('app router exposes a separate manual barcode route', (
    tester,
  ) async {
    Iterable<String> collectPaths(List<RouteBase> routes) sync* {
      for (final route in routes) {
        if (route is GoRoute) {
          yield route.path;
          yield* collectPaths(route.routes);
        } else if (route is ShellRouteBase) {
          yield* collectPaths(route.routes);
        }
      }
    }

    final paths = collectPaths(appRouter.configuration.routes);

    expect(paths, contains('/scanner'));
    expect(paths, contains('/manual-barcode'));
  });

  testWidgets('manual screen does not build the camera scanner', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapWithRouter(_manualRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Enter barcode'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'MobileScanner',
      ),
      findsNothing,
    );
  });

  testWidgets('valid manual input executes lookup and opens product result', (
    tester,
  ) async {
    final provider = _FakeProvider(
      (barcode) => ProviderProductFound(_product(barcode)),
    );
    await tester.pumpWidget(
      _wrapWithRepository(
        _manualRouter(),
        ProductRepository(
          providers: [provider],
          storage: LocalStorage.instance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manual_barcode_field')),
      '3017620422003',
    );
    await tester.tap(find.byKey(const ValueKey('manual_lookup_action')));
    await tester.pumpAndSettle();

    expect(provider.calls, ['3017620422003']);
    expect(find.text('product-3017620422003'), findsOneWidget);
  });

  testWidgets('empty manual input shows validation', (tester) async {
    final provider = _FakeProvider(
      (_) => throw const AppException(AppErrorType.unknown, 'Unexpected'),
    );
    await tester.pumpWidget(
      _wrapWithRepository(
        _manualRouter(),
        ProductRepository(
          providers: [provider],
          storage: LocalStorage.instance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manual_lookup_action')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a barcode.'), findsOneWidget);
    expect(provider.calls, isEmpty);
  });

  testWidgets('manual barcode keeps leading zero as a string', (tester) async {
    final provider = _FakeProvider(
      (barcode) => ProviderProductFound(_product(barcode)),
    );
    await tester.pumpWidget(
      _wrapWithRepository(
        _manualRouter(),
        ProductRepository(
          providers: [provider],
          storage: LocalStorage.instance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manual_barcode_field')),
      '01234567',
    );
    await tester.tap(find.byKey(const ValueKey('manual_lookup_action')));
    await tester.pumpAndSettle();

    expect(provider.calls.single, '01234567');
    expect(find.text('product-01234567'), findsOneWidget);
  });

  testWidgets('scan with camera button opens scanner only', (tester) async {
    final provider = _FakeProvider(
      (_) => throw const AppException(AppErrorType.unknown, 'Unexpected'),
    );
    await tester.pumpWidget(
      _wrapWithRepository(
        _manualRouter(),
        ProductRepository(
          providers: [provider],
          storage: LocalStorage.instance,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('manual_scan_with_camera_action')),
    );
    await tester.pumpAndSettle();

    expect(find.text('scanner-screen'), findsOneWidget);
    expect(provider.calls, isEmpty);
  });
}

class _MarkerScreen extends StatelessWidget {
  const _MarkerScreen(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

class _FakeProvider implements FoodDataProvider {
  _FakeProvider(this._handler);

  final FutureOr<ProviderProductResult> Function(String barcode) _handler;
  final calls = <String>[];

  @override
  String get providerId => 'fakeManualProvider';

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) async {
    calls.add(barcode);
    return _handler(barcode);
  }
}

UnifiedProduct _product(String barcode) => UnifiedProduct(
  barcode: barcode,
  name: 'Test product',
  primarySource: 'test',
  sourcesUsed: const ['test'],
  fieldSources: const {'name': 'test'},
  fetchedAt: DateTime(2026),
);
