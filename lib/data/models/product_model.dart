import 'nutrition_model.dart';

typedef ProductModel = UnifiedProduct;

enum ProductDataSource { openFoodFacts, fatSecret, merged, unknown }

class ProductFieldSource {
  const ProductFieldSource({required this.field, required this.source});

  final String field;
  final ProductDataSource source;
}

class UnifiedProduct {
  UnifiedProduct({
    required this.barcode,
    DateTime? fetchedAt,
    DateTime? lastScannedAt,
    this.name,
    this.brand,
    this.imageUrl,
    this.ingredientsText,
    this.ingredients = const [],
    this.allergens = const [],
    this.additives = const [],
    this.categories = const [],
    this.nutrition = const NutritionModel(),
    this.nutriScoreGrade,
    this.nutriScoreValue,
    this.novaGroup,
    this.quantity,
    this.servingSize,
    this.completeness,
    this.primarySource = 'unknown',
    this.sourcesUsed = const [],
    this.fieldSources = const {},
    this.isFromCache = false,
    this.schemaVersion = 1,
  }) : fetchedAt =
           fetchedAt ?? lastScannedAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final String? ingredientsText;
  final List<String> ingredients;
  final List<String> allergens;
  final List<String> additives;
  final List<String> categories;
  final NutritionModel nutrition;
  final String? nutriScoreGrade;
  final int? nutriScoreValue;
  final int? novaGroup;
  final String? quantity;
  final String? servingSize;
  final double? completeness;
  final String primarySource;
  final List<String> sourcesUsed;
  final Map<String, String> fieldSources;
  final DateTime fetchedAt;
  final bool isFromCache;
  final int schemaVersion;

  DateTime get lastScannedAt => fetchedAt;
  String? get nutriScore => nutriScoreGrade;

  factory UnifiedProduct.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'];
    if (product is! Map<String, dynamic>) {
      throw const FormatException('Invalid product payload.');
    }
    const source = 'openFoodFacts';
    final quantity = _quantity(product['quantity']);
    final imageUrl =
        _string(product['image_front_url']) ?? _string(product['image_url']);

    return UnifiedProduct(
      barcode: _string(product['code']) ?? _string(json['code']) ?? '',
      name: _string(product['product_name']),
      brand: _string(product['brands']),
      imageUrl: imageUrl,
      ingredientsText: _string(product['ingredients_text']),
      ingredients: _ingredients(product['ingredients']),
      allergens: _tags(
        product['allergens_tags'],
        fallback: product['allergens'],
      ),
      additives: _tags(product['additives_tags']),
      categories: _tags(
        product['categories_tags'],
        fallback: product['categories'],
      ),
      nutrition: NutritionModel.fromJson(_map(product['nutriments'])),
      nutriScoreGrade: _string(product['nutriscore_grade'])?.toUpperCase(),
      nutriScoreValue: _int(product['nutriscore_score']),
      novaGroup: _int(product['nova_group']),
      quantity: quantity,
      servingSize: _string(product['serving_size']),
      completeness: _double(product['completeness']),
      primarySource: source,
      sourcesUsed: const [source],
      fieldSources: _fieldSources(source, {
        'name': _string(product['product_name']),
        'brand': _string(product['brands']),
        'imageUrl': imageUrl,
        'ingredientsText': _string(product['ingredients_text']),
        'ingredients': product['ingredients'],
        'allergens': product['allergens_tags'] ?? product['allergens'],
        'additives': product['additives_tags'],
        'categories': product['categories_tags'] ?? product['categories'],
        'nutrition': product['nutriments'],
        'nutriScore': product['nutriscore_grade'],
        'novaGroup': product['nova_group'],
        'quantity': quantity,
        'servingSize': product['serving_size'],
        'completeness': product['completeness'],
      }),
      fetchedAt: DateTime.now(),
    );
  }

  UnifiedProduct copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? imageUrl,
    String? ingredientsText,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? additives,
    List<String>? categories,
    NutritionModel? nutrition,
    String? nutriScoreGrade,
    int? nutriScoreValue,
    int? novaGroup,
    String? quantity,
    String? servingSize,
    double? completeness,
    String? primarySource,
    List<String>? sourcesUsed,
    Map<String, String>? fieldSources,
    DateTime? fetchedAt,
    DateTime? lastScannedAt,
    bool? isFromCache,
    int? schemaVersion,
  }) {
    return UnifiedProduct(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      additives: additives ?? this.additives,
      categories: categories ?? this.categories,
      nutrition: nutrition ?? this.nutrition,
      nutriScoreGrade: nutriScoreGrade ?? this.nutriScoreGrade,
      nutriScoreValue: nutriScoreValue ?? this.nutriScoreValue,
      novaGroup: novaGroup ?? this.novaGroup,
      quantity: quantity ?? this.quantity,
      servingSize: servingSize ?? this.servingSize,
      completeness: completeness ?? this.completeness,
      primarySource: primarySource ?? this.primarySource,
      sourcesUsed: sourcesUsed ?? this.sourcesUsed,
      fieldSources: fieldSources ?? this.fieldSources,
      fetchedAt: fetchedAt ?? lastScannedAt ?? this.fetchedAt,
      isFromCache: isFromCache ?? this.isFromCache,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'brand': brand,
    'imageUrl': imageUrl,
    'ingredientsText': ingredientsText,
    'ingredients': ingredients,
    'allergens': allergens,
    'additives': additives,
    'categories': categories,
    'nutrition': nutrition.toJson(),
    'nutriScoreGrade': nutriScoreGrade,
    'nutriScoreValue': nutriScoreValue,
    'novaGroup': novaGroup,
    'quantity': quantity,
    'servingSize': servingSize,
    'completeness': completeness,
    'primarySource': primarySource,
    'sourcesUsed': sourcesUsed,
    'fieldSources': fieldSources,
    'fetchedAt': fetchedAt.toIso8601String(),
    'lastScannedAt': fetchedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory UnifiedProduct.fromStorage(Map<String, dynamic> json) =>
      UnifiedProduct(
        barcode: _string(json['barcode']) ?? '',
        name: _string(json['name']),
        brand: _string(json['brand']),
        imageUrl: _string(json['imageUrl']),
        ingredientsText: _string(json['ingredientsText']),
        ingredients: _list(json['ingredients']),
        allergens: _list(json['allergens']),
        additives: _list(json['additives']),
        categories: _list(json['categories']),
        nutrition: NutritionModel.fromStorage(_map(json['nutrition'])),
        nutriScoreGrade: _string(json['nutriScoreGrade']),
        nutriScoreValue: _int(json['nutriScoreValue']),
        novaGroup: _int(json['novaGroup']),
        quantity: _quantity(json['quantity']),
        servingSize: _string(json['servingSize']),
        completeness: _double(json['completeness']),
        primarySource: _string(json['primarySource']) ?? 'unknown',
        sourcesUsed: _list(json['sourcesUsed']),
        fieldSources: _stringMap(json['fieldSources']),
        fetchedAt:
            DateTime.tryParse(
              _string(json['fetchedAt']) ??
                  _string(json['lastScannedAt']) ??
                  '',
            ) ??
            DateTime.now(),
        isFromCache: true,
        schemaVersion: _int(json['schemaVersion']) ?? 1,
      );

  static Map<String, dynamic> _map(Object? raw) =>
      raw is Map<String, dynamic> ? raw : <String, dynamic>{};

  static String? _string(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  static int? _int(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  static double? _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static List<String> _list(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _tags(Object? raw, {Object? fallback}) {
    final fromList = _list(
      raw,
    ).map(_cleanTag).where((item) => item.isNotEmpty).toList();
    if (fromList.isNotEmpty) return fromList;
    final text = _string(fallback);
    if (text == null) return const [];
    return text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<String> _ingredients(Object? raw) {
    if (raw is List) {
      return raw
          .map((item) => item is Map ? _string(item['text']) : _string(item))
          .nonNulls
          .toList();
    }
    return const [];
  }

  static String _cleanTag(String tag) {
    final normalized = tag.contains(':') ? tag.split(':').last : tag;
    return normalized.replaceAll('-', ' ').trim();
  }

  static String? _quantity(Object? raw) {
    final value = _string(raw);
    if (value == null) return null;
    final lower = value.toLowerCase();
    if (RegExp(r'(\bmad\b|\bdh\b|€|\$|£)').hasMatch(lower)) return null;
    final quantityPattern = RegExp(
      r'(^|\s)\d+([.,]\d+)?\s*(g|kg|mg|ml|cl|l|oz|fl oz|lb|lbs)\b',
      caseSensitive: false,
    );
    return quantityPattern.hasMatch(value) ? value : null;
  }

  static Map<String, String> _fieldSources(
    String source,
    Map<String, Object?> values,
  ) {
    final result = <String, String>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      if (value is List && value.isEmpty) continue;
      if (value is Map && value.isEmpty) continue;
      result[entry.key] = source;
    }
    return result;
  }

  static Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(key.toString(), value.toString()));
  }
}
