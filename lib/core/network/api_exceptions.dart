// lib/core/network/api_exceptions.dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException({required this.message, this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'Internet aloqasi yo\'q'})
      : super(statusCode: null);
}

class TimeoutException extends ApiException {
  const TimeoutException({super.message = 'So\'rov vaqti tugadi'})
      : super(statusCode: 408);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Avtorizatsiya xatosi'})
      : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Ma\'lumot topilmadi'})
      : super(statusCode: 404);
}

class ServerErrorException extends ApiException {
  const ServerErrorException({super.message = 'Server xatosi'})
      : super(statusCode: 500);
}
