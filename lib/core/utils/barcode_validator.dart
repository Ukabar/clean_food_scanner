class BarcodeValidator {
  const BarcodeValidator._();

  static bool isValid(String value) {
    final trimmed = value.trim();
    return RegExp(r'^[0-9]{8,14}$').hasMatch(trimmed);
  }
}
