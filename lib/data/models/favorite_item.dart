class FavoriteItem {
  const FavoriteItem({
    required this.barcode,
    required this.productName,
    required this.addedAt,
    this.brand,
    this.imageUrl,
    this.score,
    this.rating,
  });

  final String barcode;
  final String productName;
  final String? brand;
  final String? imageUrl;
  final int? score;
  final String? rating;
  final DateTime addedAt;

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'score': score,
    'rating': rating,
    'addedAt': addedAt.toIso8601String(),
  };

  factory FavoriteItem.fromJson(Map<String, dynamic> json) => FavoriteItem(
    barcode: json['barcode']?.toString() ?? '',
    productName: json['productName']?.toString() ?? 'Unnamed product',
    brand: json['brand']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
    score: json['score'] is num ? (json['score'] as num).toInt() : null,
    rating: json['rating']?.toString(),
    addedAt:
        DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
  );
}
