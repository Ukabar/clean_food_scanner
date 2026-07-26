import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';
import '../../data/models/favorite_item.dart';
import '../../data/models/product_model.dart';
import '../../data/services/food_scoring_engine.dart';

class FavoritesController extends Notifier<List<FavoriteItem>> {
  final _storage = LocalStorage.instance;
  final _scoring = const FoodScoringEngine();

  @override
  List<FavoriteItem> build() => _storage.getFavorites();

  bool contains(String barcode) => state.any((item) => item.barcode == barcode);

  Future<void> toggle(ProductModel product) async {
    if (contains(product.barcode)) {
      state = state.where((item) => item.barcode != product.barcode).toList();
    } else {
      final score = _scoring.score(product);
      state = [
        FavoriteItem(
          barcode: product.barcode,
          productName: product.name ?? 'Unnamed product',
          brand: product.brand,
          imageUrl: product.imageUrl,
          score: score.score?.round(),
          rating: score.rating,
          addedAt: DateTime.now(),
        ),
        ...state,
      ];
    }
    await _storage.saveFavorites(state);
  }
}

final favoritesControllerProvider =
    NotifierProvider<FavoritesController, List<FavoriteItem>>(
      FavoritesController.new,
    );
