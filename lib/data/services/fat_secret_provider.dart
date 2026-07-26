import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/utils/barcode_normalizer.dart';
import '../../core/utils/barcode_validator.dart';
import '../models/nutrition_model.dart';
import '../models/product_model.dart';
import '../providers/food_data_provider.dart';

class FatSecretProvider implements FoodDataProvider {
  FatSecretProvider({
    required this.backendBaseUrl,
    http.Client? client,
    this.regionFallbacks = const ['MA', 'FR', ''],
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final Uri backendBaseUrl;
  final http.Client _client;
  final List<String> regionFallbacks;
  final Duration timeout;

  @override
  String get providerId => 'fatSecret';

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) async {
    final originalBarcode = barcode.trim();
    if (!BarcodeValidator.isValid(originalBarcode)) {
      return const ProviderInvalidBarcode();
    }

    final String gtin13;
    try {
      gtin13 = normalizeToGtin13(originalBarcode);
    } on FormatException {
      return const ProviderInvalidBarcode();
    }
    try {
      for (final region in regionFallbacks) {
        final response = await _client
            .get(_uriFor(gtin13, region))
            .timeout(timeout);
        final result = _parseResponse(response, originalBarcode, gtin13);
        if (result is ProviderProductNotFound && region.isNotEmpty) {
          continue;
        }
        return result;
      }
      return const ProviderProductNotFound();
    } on TimeoutException {
      return const ProviderTimeout();
    } on SocketException {
      return const ProviderNoConnection();
    } on http.ClientException {
      return const ProviderNoConnection();
    } on FormatException {
      return const ProviderMalformedResponse();
    }
  }

  Uri _uriFor(String gtin13, String region) {
    final basePath = backendBaseUrl.path.endsWith('/')
        ? backendBaseUrl.path.substring(0, backendBaseUrl.path.length - 1)
        : backendBaseUrl.path;
    final path = '$basePath/api/products/barcode/$gtin13';
    return backendBaseUrl.replace(
      path: path,
      queryParameters: region.isEmpty ? null : {'region': region},
    );
  }

  ProviderProductResult _parseResponse(
    http.Response response,
    String originalBarcode,
    String gtin13,
  ) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const ProviderUnauthorized();
    }
    if (response.statusCode == 404) return const ProviderProductNotFound();
    if (response.statusCode == 429) return const ProviderRateLimited();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return ProviderServerFailure(response.statusCode);
    }

    final body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      return const ProviderMalformedResponse();
    }
    if (body['found'] != true) return const ProviderProductNotFound();
    final payload = body['product'];
    if (payload is! Map<String, dynamic>) {
      return const ProviderMalformedResponse();
    }
    final backendBarcode = _string(body['barcode']);
    if (backendBarcode != null && backendBarcode != gtin13) {
      return const ProviderMalformedResponse();
    }

    final source = providerId;
    final nutrition = _nutrition(payload);
    final servingSizeGrams = _double(payload['servingSizeGrams']);
    return ProviderProductFound(
      UnifiedProduct(
        barcode: originalBarcode,
        name: _string(payload['name']),
        brand: _string(payload['brand']),
        nutrition: nutrition,
        servingSize: servingSizeGrams == null
            ? null
            : '${servingSizeGrams.toStringAsFixed(1)} g',
        primarySource: source,
        sourcesUsed: [source],
        fieldSources: _fieldSources(source, {
          'name': payload['name'],
          'brand': payload['brand'],
          'nutrition': nutrition.hasAnyData ? 'nutrition' : null,
          'servingSize': servingSizeGrams,
        }),
        fetchedAt: DateTime.now(),
      ),
    );
  }

  NutritionModel _nutrition(Map<String, dynamic> payload) {
    final basis = _string(payload['nutritionBasis']);
    if (basis == 'per_100g' || basis == 'per_100ml') {
      return NutritionModel(
        energyKcalPer100g: _double(payload['energyKcal']),
        fatPer100g: _double(payload['fat']),
        saturatedFatPer100g: _double(payload['saturatedFat']),
        carbohydratesPer100g: _double(payload['carbohydrates']),
        sugarsPer100g: _double(payload['sugars']),
        proteinsPer100g: _double(payload['protein']),
        fiberPer100g: _double(payload['fiber']),
        sodiumPer100g: _double(payload['sodium']),
        saltPer100g: _double(payload['salt']),
      );
    }
    if (basis == 'per_serving') {
      final grams = _double(payload['servingSizeGrams']);
      if (grams == null || grams <= 0) return const NutritionModel();
      double? convert(Object? value) {
        final number = _double(value);
        return number == null ? null : number * 100 / grams;
      }

      return NutritionModel(
        energyKcalPer100g: convert(payload['energyKcal']),
        fatPer100g: convert(payload['fat']),
        saturatedFatPer100g: convert(payload['saturatedFat']),
        carbohydratesPer100g: convert(payload['carbohydrates']),
        sugarsPer100g: convert(payload['sugars']),
        proteinsPer100g: convert(payload['protein']),
        fiberPer100g: convert(payload['fiber']),
        sodiumPer100g: convert(payload['sodium']),
        saltPer100g: convert(payload['salt']),
      );
    }
    return const NutritionModel();
  }

  String? _string(Object? raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  double? _double(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  Map<String, String> _fieldSources(
    String source,
    Map<String, Object?> values,
  ) {
    final result = <String, String>{};
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      result[entry.key] = source;
    }
    return result;
  }
}
