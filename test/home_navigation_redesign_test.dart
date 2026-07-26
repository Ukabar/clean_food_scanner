import 'package:clean_food_scanner/app/app_shell.dart';
import 'package:clean_food_scanner/core/localization/app_localizations.dart';
import 'package:clean_food_scanner/core/theme/app_theme.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initStorage() async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  await LocalStorage.instance.initialize();
  await LocalStorage.instance.setOnboardingComplete(true);
  await LocalStorage.instance.clearHistory();
}

GoRouter _router({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/favorites',
            builder: (context, state) =>
                const _MarkerScreen('favorites-screen'),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const _MarkerScreen('history-screen'),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const _MarkerScreen('settings-screen'),
          ),
        ],
      ),
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
        path: '/onboarding',
        builder: (context, state) => const _MarkerScreen('onboarding-screen'),
      ),
    ],
  );
}

Widget _wrap(
  GoRouter router, {
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
}) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  Size? size,
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
  GoRouter? router,
}) async {
  await tester.binding.setSurfaceSize(size ?? const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    _wrap(router ?? _router(), themeMode: themeMode, textScale: textScale),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(_initStorage);

  testWidgets('home has no top settings button and bottom nav has no More', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
    expect(find.text('More'), findsNothing);
    for (final label in ['Home', 'Scan', 'Favorites', 'History', 'Settings']) {
      expect(find.text(label), findsAtLeastNWidgets(1));
    }
  });

  testWidgets('bottom Settings and Scan open their independent routes', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_settings')));
    await tester.pumpAndSettle();
    expect(find.text('settings-screen'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_scan')));
    await tester.pumpAndSettle();
    expect(find.text('scanner-screen'), findsOneWidget);
  });

  testWidgets('Scan now opens scanner', (tester) async {
    await _pumpHome(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('home_scan_now_action')),
    );
    await tester.tap(find.byKey(const ValueKey('home_scan_now_action')));
    await tester.pumpAndSettle();

    expect(find.text('scanner-screen'), findsOneWidget);
  });

  testWidgets('Manual quick action opens manual entry and never camera', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_manual_action')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home_manual_action')));
    await tester.pumpAndSettle();

    expect(find.text('manual-barcode-screen'), findsOneWidget);
    expect(find.text('scanner-screen'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == 'MobileScanner',
      ),
      findsNothing,
    );
  });

  testWidgets('quick actions are ordered Manual Favorites History', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('home_manual_action')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    final manualX = tester
        .getCenter(find.byKey(const ValueKey('home_manual_action')))
        .dx;
    final favoritesX = tester
        .getCenter(find.byKey(const ValueKey('home_favorites_action')))
        .dx;
    final historyX = tester
        .getCenter(find.byKey(const ValueKey('home_history_action')))
        .dx;

    expect(manualX, lessThan(favoritesX));
    expect(favoritesX, lessThan(historyX));
  });

  testWidgets('home visual proportions stay close to reference', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(390, 844));

    final screen = tester
        .binding
        .renderViews
        .first
        .configuration
        .logicalConstraints
        .biggest;
    final titleBox = tester.getRect(
      find.byKey(const ValueKey('home_hero_title')),
    );
    final illustrationBox = tester.getRect(
      find.byKey(const ValueKey('home_hero_product_illustration')),
    );
    final scanCard = tester.getRect(
      find.byKey(const ValueKey('home_scan_card')),
    );
    final quickActions = tester.getRect(
      find.byKey(const ValueKey('home_quick_actions_row')),
    );
    final bottomNav = tester.getRect(
      find.byKey(const ValueKey('home_bottom_nav')),
    );

    expect(titleBox.height, lessThanOrEqualTo(86));
    expect(illustrationBox.left, greaterThanOrEqualTo(0));
    expect(illustrationBox.right, lessThanOrEqualTo(screen.width));
    expect(scanCard.height, inInclusiveRange(180, 270));
    expect(quickActions.bottom, lessThan(bottomNav.top));
    expect(find.text('Recent scans'), findsOneWidget);
  });

  testWidgets('home primary copy is never truncated with ellipsis', (
    tester,
  ) async {
    for (final size in [
      const Size(320, 568),
      const Size(360, 800),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      for (final textScale in [1.0, 1.3, 1.5]) {
        await _pumpHome(tester, size: size, textScale: textScale);

        expect(
          find.text(
            'Understand ingredients, nutrition, and processing before you buy.',
          ),
          findsOneWidget,
        );
        expect(find.text('Scan a food product'), findsOneWidget);
        expect(
          find.text('Check ingredients, nutrition, and processing.'),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.text('Enter a barcode'),
          160,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Enter a barcode'), findsOneWidget);
        expect(find.text('View saved products'), findsOneWidget);
        expect(find.text('See recent scans'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text && (widget.data?.contains('...') ?? false),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    }
  });

  for (final size in [
    const Size(360, 800),
    const Size(390, 844),
    const Size(430, 932),
  ]) {
    testWidgets('home has no overflow on ${size.width}x${size.height}', (
      tester,
    ) async {
      await _pumpHome(tester, size: size, textScale: 1.3);

      expect(find.byKey(const ValueKey('home_scan_card')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('home_quick_actions_row')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('recent scans empty state and View all open History', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.text('No scanned products yet'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No scanned products yet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home_recent_scans_card')),
      findsOneWidget,
    );
    final illustrationRect = tester.getRect(
      find.byKey(const ValueKey('home_recent_empty_illustration')),
    );
    expect(illustrationRect.width, inInclusiveRange(180, 280));
    expect(
      find.text('Scan a product to see recent food checks'),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home_recent_view_all')));
    await tester.pumpAndSettle();

    expect(find.text('history-screen'), findsOneWidget);
  });

  testWidgets('small screen with large text has no overflow exception', (
    tester,
  ) async {
    await _pumpHome(tester, size: const Size(320, 568), textScale: 1.5);

    expect(find.byKey(const ValueKey('home_bottom_nav')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home supports dark mode', (tester) async {
    await _pumpHome(tester, themeMode: ThemeMode.dark);

    expect(find.text('Scan smarter.'), findsOneWidget);
    expect(find.byKey(const ValueKey('home_bottom_nav')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated bottom tab tap does not duplicate navigation', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('bottom_nav_favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bottom_nav_favorites')));
    await tester.pumpAndSettle();

    expect(find.text('favorites-screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
