enum AppErrorType {
  noInternet,
  productNotFound,
  timeout,
  invalidBarcode,
  cameraPermissionDenied,
  cameraUnavailable,
  invalidApiResponse,
  productDataIncomplete,
  unknown,
}

class AppException implements Exception {
  const AppException(this.type, this.message);

  final AppErrorType type;
  final String message;

  @override
  String toString() => message;
}
