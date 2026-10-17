import '../errors/failures.dart';

/// Representasi fungsional Result (Success atau Failure) untuk Clean Architecture
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is ErrorResult<T>;

  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        ErrorResult<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        ErrorResult<T>(failure: final f) => f,
      };

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      Success<T>(data: final d) => onSuccess(d),
      ErrorResult<T>(failure: final f) => onFailure(f),
    };
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class ErrorResult<T> extends Result<T> {
  final Failure failure;
  const ErrorResult(this.failure);
}
