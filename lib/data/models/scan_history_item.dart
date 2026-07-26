class ScanHistoryItem {
  const ScanHistoryItem({
    required this.barcode,
    required this.productName,
    required this.scannedAt,
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
  final DateTime scannedAt;

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'productName': productName,
    'brand': brand,
    'imageUrl': imageUrl,
    'score': score,
    'rating': rating,
    'scannedAt': scannedAt.toIso8601String(),
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) =>
      ScanHistoryItem(
        barcode: json['barcode']?.toString() ?? '',
        productName: json['productName']?.toString() ?? 'Unnamed product',
        brand: json['brand']?.toString(),
        imageUrl: json['imageUrl']?.toString(),
        score: json['score'] is num ? (json['score'] as num).toInt() : null,
        rating: json['rating']?.toString(),
        scannedAt:
            DateTime.tryParse(json['scannedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
