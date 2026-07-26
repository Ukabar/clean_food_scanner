import 'package:clean_food_scanner/core/localization/app_localizations.dart';
import 'package:clean_food_scanner/core/theme/app_theme.dart';
import 'package:clean_food_scanner/data/local/local_storage.dart';
import 'package:clean_food_scanner/data/models/nutrition_model.dart';
import 'package:clean_food_scanner/data/models/product_model.dart';
import 'package:clean_food_scanner/data/providers.dart';
import 'package:clean_food_scanner/data/providers/food_data_provider.dart';
import 'package:clean_food_scanner/data/repositories/product_repository.dart';
import 'package:clean_food_scanner/features/product/product_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _initStorage() async {
  SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  await LocalStorage.instance.initialize();
  await LocalStorage.instance.clearCache();
  await LocalStorage.instance.clearHistory();
  await LocalStorage.instance.saveFavorites([]);
}

Future<void> _pumpDetails(
  WidgetTester tester,
  UnifiedProduct product, {
  ThemeData? theme,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        productRepositoryProvider.overrideWithValue(
          ProductRepository(
            providers: [_FakeProvider(product)],
            storage: LocalStorage.instance,
          ),
        ),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.light,
        darkTheme: AppTheme.dark,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [AppLocalizations.delegate],
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: _PushDetailsHost(barcode: product.barcode),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open_product_details')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(_initStorage);

  testWidgets('complete product shows a score card', (tester) async {
    await _pumpDetails(tester, _completeProduct());

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.text('Score unavailable'), findsNothing);
    expect(find.textContaining('--'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('incomplete product shows compact score unavailable', (
    tester,
  ) async {
    await _pumpDetails(tester, _incompleteProduct());

    expect(find.text('Score unavailable'), findsOneWidget);
    expect(
      find.text(
        'This product does not include enough nutrition information to calculate a score.',
      ),
      findsOneWidget,
    );
    expect(find.text('Not enough data'), findsNothing);
    expect(find.textContaining('--'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UNKNOWN and unavailable values are hidden from product info', (
    tester,
  ) async {
    await _pumpDetails(tester, _incompleteProduct());

    expect(find.text('Product information'), findsOneWidget);
    expect(find.text('UNKNOWN'), findsNothing);
    expect(find.text('Nutri-Score'), findsNothing);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('95 g'), findsOneWidget);
    expect(find.text('Serving size'), findsOneWidget);
    expect(find.text('2 g'), findsOneWidget);
    expect(find.text('Data completeness'), findsOneWidget);
    expect(find.text('Completeness'), findsNothing);
  });

  testWidgets('missing nutrition and allergens are merged into one section', (
    tester,
  ) async {
    await _pumpDetails(tester, _incompleteProduct());

    await tester.scrollUntilVisible(
      find.text('Unavailable information'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Unavailable information'), findsOneWidget);
    expect(find.text('Nutrition facts'), findsOneWidget);
    expect(find.text('Allergen information'), findsOneWidget);
    expect(find.text('Not available'), findsNWidgets(2));
    expect(find.text('Always verify the product package.'), findsOneWidget);
    expect(
      find.text('Nutrition information is unavailable for this product.'),
      findsNothing,
    );
    expect(find.text('Allergen information unavailable.'), findsNothing);
  });

  testWidgets('unavailable section is hidden when data is complete', (
    tester,
  ) async {
    await _pumpDetails(tester, _completeProduct());

    expect(find.text('Unavailable information'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Allergens'), findsOneWidget);
    expect(find.text('milk'), findsOneWidget);
  });

  testWidgets('long ingredients can show more and show less', (tester) async {
    await _pumpDetails(tester, _completeProduct(longIngredients: true));

    expect(find.text('Show more'), findsOneWidget);
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('why no score uses specific missing-data reasons once', (
    tester,
  ) async {
    await _pumpDetails(tester, _incompleteProduct());

    await tester.scrollUntilVisible(
      find.text('Why no score?'),
      220,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Why no score?'), findsOneWidget);
    expect(find.text('Nutrition information is unavailable.'), findsOneWidget);
    expect(
      find.text('Not enough core nutrition fields were found.'),
      findsOneWidget,
    );
    expect(find.text('Insufficient product data'), findsNothing);
  });

  testWidgets('favorite toggle works', (tester) async {
    await _pumpDetails(tester, _completeProduct());

    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove favorite'), findsOneWidget);
    expect(
      LocalStorage.instance.getFavorites().single.barcode,
      '3017620422003',
    );
  });

  testWidgets('back button returns to previous screen', (tester) async {
    await _pumpDetails(tester, _completeProduct());

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Open details'), findsOneWidget);
  });

  testWidgets('no overflow on 320x568 with text scale 1.5', (tester) async {
    await _pumpDetails(
      tester,
      _incompleteProduct(),
      size: const Size(320, 568),
      textScale: 1.5,
    );

    expect(find.text('Score unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('screen works in dark mode', (tester) async {
    await _pumpDetails(tester, _completeProduct(), theme: AppTheme.dark);

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Product information'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _PushDetailsHost extends StatelessWidget {
  const _PushDetailsHost({required this.barcode});

  final String barcode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey('open_product_details'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductResultScreen(barcode: barcode),
              ),
            );
          },
          child: const Text('Open details'),
        ),
      ),
    );
  }
}

class _FakeProvider implements FoodDataProvider {
  const _FakeProvider(this.product);

  final UnifiedProduct product;

  @override
  String get providerId => 'fake';

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) async =>
      ProviderProductFound(product);
}

UnifiedProduct _completeProduct({bool longIngredients = false}) {
  final ingredients = longIngredients
      ? List.filled(
          18,
          'whole grain oats, milk powder, cocoa, fiber, vitamins',
        ).join(', ')
      : 'whole grain oats, milk powder, cocoa';
  return UnifiedProduct(
    barcode: '3017620422003',
    name: 'Complete cereal',
    brand: 'Clean Brand',
    ingredientsText: ingredients,
    allergens: const ['milk'],
    additives: const ['e322'],
    categories: const ['breakfast cereals'],
    nutrition: const NutritionModel(
      energyKcalPer100g: 370,
      proteinsPer100g: 11,
      carbohydratesPer100g: 62,
      sugarsPer100g: 4,
      fatPer100g: 6,
      saturatedFatPer100g: 1,
      fiberPer100g: 7,
      saltPer100g: 0.1,
    ),
    nutriScoreGrade: 'A',
    novaGroup: 2,
    quantity: '350 g',
    servingSize: '40 g',
    completeness: 0.92,
  );
}

UnifiedProduct _incompleteProduct() => UnifiedProduct(
  barcode: '6111018501480',
  name: 'Nescafé',
  brand: 'Nescafe',
  ingredientsText: 'NESCAFE C CLASSIC 100% Alc',
  nutriScoreGrade: 'UNKNOWN',
  quantity: '95 g',
  servingSize: '2 g',
  completeness: 0.69,
);
