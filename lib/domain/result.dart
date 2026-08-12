/// A simple, dependency-free [Either] type for the domain boundary.
///
/// Repositories return [Result] so use cases compose without try/catch, and
/// the presentation layer gets a typed error ([Failure]) rather than an
/// exception. Keeping this in domain (not core/errors) means domain has zero
/// framework imports — [Failure] is imported from core, which is acceptable
/// because core/errors has no Flutter dependency either.
import '../core/errors/failures.dart';

sealed class Result<T> {
  const Result();

  /// Successful result carrying [value].
  factory Result.success(T value) = Success<T>;

  /// Failed result carrying a [Failure].
  factory Result.failure(Failure failure) = FailureResult<T>;

  /// Pattern-match on the two cases. Like Rust's `match`.
  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success<T>(:final value) => success(value),
      FailureResult<T>(:final failure) => failure(failure),
    };
  }

  /// Unwrap the value, or throw. Use in tests only.
  T unwrap() => switch (this) {
    Success<T>(:final value) => value,
    FailureResult<T>(:final failure) => throw StateError('unwrap on $failure'),
  };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);
  @override
  final Failure failure;
}
