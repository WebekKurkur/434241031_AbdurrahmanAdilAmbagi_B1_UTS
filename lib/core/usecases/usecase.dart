// lib/core/usecases/usecase.dart

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

/// Convenience base for parameterless use cases (`Future<Type> call()`).
/// Concrete subclasses include `GetTicketsUseCase` and `LogoutUseCase`.
abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}
