// lib/core/errors/failure.dart

class Failure {
  final String message;
  final String? code;

  const Failure({
    required this.message,
    this.code,
  });
}
