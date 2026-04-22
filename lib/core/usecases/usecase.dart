// lib/core/usecases/usecase.dart

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

abstract class NoParamsUseCase<Type> {
  Future<Type> call();
}

class NoParams {
  const NoParams();
}
