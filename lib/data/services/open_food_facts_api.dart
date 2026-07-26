import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';
import '../../core/utils/barcode_validator.dart';
import '../models/product_model.dart';
import '../providers/food_data_provider.dart';

class OpenFoodFactsProvider implements FoodDataProvider {
  OpenFoodFactsProvider({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  String get providerId => 'openFoodFacts';

  @override
  Future<ProviderProductResult> findByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (!BarcodeValidator.isValid(cleanBarcode)) {
      return const ProviderInvalidBarcode();
    }

    final uri =
        Uri.parse(
          '${AppConstants.openFoodFactsBaseUrl}/api/v2/product/$cleanBarcode.json',
        ).replace(
          queryParameters: {
            'fields': [
              'code',
              'product_name',
              'brands',
              'image_front_url',
              'image_url',
              'ingredients_text',
              'ingredients',
              'nutriments',
              'allergens',
              'allergens_tags',
              'additives_tags',
              'additives_n',
              'nutriscore_grade',
              'nutriscore_score',
              'nova_group',
              'categories',
              'categories_tags',
              'quantity',
              'serving_size',
              'countries',
              'labels',
              'labels_tags',
              'completeness',
            ].join(','),
          },
        );

    try {
      final response = await _client
          .get(uri, headers: {'User-Agent': AppConstants.userAgent})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 401 || response.statusCode == 403) {
        return const ProviderUnauthorized();
      }
      if (response.statusCode == 404) {
        return const ProviderProductNotFound();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return ProviderServerFailure(response.statusCode);
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return const ProviderMalformedResponse();
      }
      if (body['status'] == 0 || body['product'] == null) {
        return const ProviderProductNotFound();
      }

      final product = UnifiedProduct.fromOpenFoodFacts(
        body,
      ).copyWith(fetchedAt: DateTime.now());
      return ProviderProductFound(product);
    } on TimeoutException {
      return const ProviderTimeout();
    } on SocketException {
      return const ProviderNoConnection();
    } on FormatException {
      return const ProviderMalformedResponse();
    }
  }
}

typedef OpenFoodFactsApi = OpenFoodFactsProvider;
