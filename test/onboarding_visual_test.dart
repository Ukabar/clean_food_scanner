import 'package:clean_food_scanner/core/localization/app_localizations.dart';
import 'package:clean_food_scanner/core/theme/app_theme.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/features/home/home_screen.dart';
import 'package:clean_food_scanner/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initStorage({bool onboardingComplete = false}) async {
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': onboardingComplete,
  });
  await LocalStorage.instance.initialize();
  await LocalStorage.instance.clearHistory();
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

Widget _wrapRouter(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
    ),
  );
}

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: _wrap(const OnboardingScreen()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding_next_action')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

void main() {
  testWidgets('each onboarding page shows the correct asset', (tester) async {
    await _initStorage();
    await _pumpOnboarding(tester);

    expect(
      find.byKey(
        const ValueKey(
          'onboarding_asset_assets/onboarding/onboarding_scan.png',
        ),
      ),
      findsOneWidget,
    );

    await _tapNext(tester);
    expect(
      find.byKey(
        const ValueKey(
          'onboarding_asset_assets/onboarding/onboarding_details.png',
        ),
      ),
      findsOneWidget,
    );

    await _tapNext(tester);
    expect(
      find.byKey(
        const ValueKey(
          'onboarding_asset_assets/onboarding/onboarding_score.png',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('reference phone chrome is not rendered as widgets', (
    tester,
  ) async {
    await _initStorage();
    await _pumpOnboarding(tester);

    expect(find.text('20:04'), findsNothing);
    expect(find.text('Navigation'), findsNothing);
    expect(find.text('Product analysis'), findsNothing);
    expect(find.text('Example score'), findsNothing);
    expect(find.text('Good Choice'), findsNothing);
  });

  testWidgets('Next moves to the next page and third page shows Get Started', (
    tester,
  ) async {
    await _initStorage();
    await _pumpOnboarding(tester);

    expect(find.text('Scan food products'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('Understand ingredients'), findsOneWidget);

    await _tapNext(tester);
    expect(find.text('Choose with more context'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'onboarding_asset_assets/onboarding/onboarding_score.png',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('third page keeps title on one line and illustration large', (
    tester,
  ) async {
    await _initStorage();
    await _pumpOnboarding(tester, size: const Size(390, 844));
    await _tapNext(tester);
    await _tapNext(tester);

    final titleRect = tester.getRect(find.text('Choose with more context'));
    final imageRect = tester.getRect(
      find.byKey(
        const ValueKey(
          'onboarding_asset_assets/onboarding/onboarding_score.png',
        ),
      ),
    );

    expect(titleRect.height, lessThan(48));
    expect(imageRect.width, greaterThan(300));
    expect(imageRect.height, greaterThan(330));
    expect(
      find.byKey(const ValueKey('onboarding_sample_score_ring')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding has no overflow on 320x568', (tester) async {
    await _initStorage();
    await _pumpOnboarding(tester, size: const Size(320, 568));

    expect(find.text('Scan food products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_next_action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(375, 667), const Size(390, 844)]) {
    testWidgets('onboarding has no overflow on ${size.width}x${size.height}', (
      tester,
    ) async {
      await _initStorage();
      await _pumpOnboarding(tester, size: size);

      expect(find.text('Scan food products'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('onboarding_next_action')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('onboarding supports text scale 1.3 without overflow', (
    tester,
  ) async {
    await _initStorage();
    await _pumpOnboarding(tester, size: const Size(375, 667), textScale: 1.3);

    expect(find.text('Scan food products'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding supports text scale 1.5 without overflow', (
    tester,
  ) async {
    await _initStorage();
    await _pumpOnboarding(tester, size: const Size(320, 568), textScale: 1.5);

    expect(find.text('Scan food products'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_next_action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample score is not saved to history', (tester) async {
    await _initStorage();
    await _pumpOnboarding(tester);
    await _tapNext(tester);
    await _tapNext(tester);

    expect(find.text('Choose with more context'), findsOneWidget);
    expect(LocalStorage.instance.getHistory(), isEmpty);
  });

  testWidgets('bottom controls remain above system navigation padding', (
    tester,
  ) async {
    await _initStorage();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          padding: EdgeInsets.only(bottom: 34),
        ),
        child: _wrap(const OnboardingScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final buttonBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('onboarding_next_action')))
        .dy;
    expect(buttonBottom, lessThan(844 - 20));
  });

  testWidgets('Get Started opens home and saves onboarding state', (
    tester,
  ) async {
    await _initStorage();
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Home ready'))),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
      ],
    );

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump(const Duration(milliseconds: 120));
    await _tapNext(tester);
    await _tapNext(tester);
    await tester.tap(find.byKey(const ValueKey('onboarding_next_action')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Home ready'), findsOneWidget);
    expect(LocalStorage.instance.onboardingComplete, isTrue);
  });

  testWidgets('home redirects to onboarding only on first launch', (
    tester,
  ) async {
    await _initStorage();
    final firstLaunchRouter = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Text('Onboarding route')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    await tester.pumpWidget(_wrapRouter(firstLaunchRouter));
    await tester.pumpAndSettle();
    expect(find.text('Onboarding route'), findsOneWidget);

    await _initStorage(onboardingComplete: true);
    final returningRouter = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Text('Onboarding route')),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(body: Text('Settings')),
        ),
      ],
    );
    await tester.pumpWidget(_wrapRouter(returningRouter));
    await tester.pumpAndSettle();
    expect(find.text('Scan smarter.'), findsOneWidget);
    expect(find.text('Choose better.'), findsOneWidget);
  });
}
