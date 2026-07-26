import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/manual/manual_barcode_entry_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/premium/premium_screen.dart';
import '../features/product/product_not_found_screen.dart';
import '../features/product/product_result_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/manual-barcode',
      builder: (context, state) => const ManualBarcodeEntryScreen(),
    ),
    GoRoute(
      path: '/product/:barcode',
      builder: (context, state) {
        final barcode = state.pathParameters['barcode'] ?? '';
        return ProductResultScreen(barcode: barcode);
      },
    ),
    GoRoute(
      path: '/not-found/:barcode',
      builder: (context, state) {
        final barcode = state.pathParameters['barcode'] ?? '';
        return ProductNotFoundScreen(barcode: barcode);
      },
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
  ],
);
