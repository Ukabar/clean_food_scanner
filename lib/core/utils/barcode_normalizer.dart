class BarcodeNormalizer {
  const BarcodeNormalizer._();

  static String normalizeToGtin13(String barcode) {
    final cleaned = barcode.trim().replaceAll(RegExp(r'[\s-]+'), '');
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
      throw const FormatException('Barcode must contain digits only.');
    }
    return switch (cleaned.length) {
      13 => cleaned,
      12 => '0$cleaned',
      8 => cleaned.padLeft(13, '0'),
      _ => throw const FormatException(
        'Barcode must be EAN-13, UPC-A, or EAN-8.',
      ),
    };
  }
}

String normalizeToGtin13(String barcode) =>
    BarcodeNormalizer.normalizeToGtin13(barcode);
