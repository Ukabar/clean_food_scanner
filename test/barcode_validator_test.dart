import 'package:clean_food_scanner/core/utils/barcode_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts valid EAN-8 barcodes', () {
    expect(BarcodeValidator.isValid('96385074'), isTrue);
  });

  test('accepts valid EAN-13 barcodes', () {
    expect(BarcodeValidator.isValid('3017620422003'), isTrue);
  });

  test('accepts valid UPC-style numeric barcodes', () {
    expect(BarcodeValidator.isValid('036000291452'), isTrue);
  });

  test('rejects empty and whitespace-only input', () {
    expect(BarcodeValidator.isValid(''), isFalse);
    expect(BarcodeValidator.isValid('   '), isFalse);
  });

  test('rejects non-numeric and overly long input', () {
    expect(BarcodeValidator.isValid('30176ABC22003'), isFalse);
    expect(BarcodeValidator.isValid('123456789012345'), isFalse);
  });
}
