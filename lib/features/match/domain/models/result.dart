import 'package:stroke_wars/features/match/domain/models/match_failure.dart';

/// Sealed representation of a functional result that can either be a [Success]
/// wrapping a value, or a [Failure] wrapping a [MatchFailure].
sealed class Result<T> {
  const Result();

  /// Executes [onSuccess] if success, or [onFailure] if failure.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(MatchFailure failure) onFailure,
  }) => switch (this) {
    Success<T>(:final value) => onSuccess(value),
    Failure<T>(:final error) => onFailure(error),
  };

  /// Returns true if this represents a success.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this represents a failure.
  bool get isFailure => this is Failure<T>;

  /// Returns the successful value or throws if a failure.
  T get valueOrThrow => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => throw StateError(
      'Cannot retrieve value from a Failure result.',
    ),
  };

  /// Returns the failure error or throws if a success.
  MatchFailure get errorOrThrow => switch (this) {
    Success<T>() => throw StateError(
      'Cannot retrieve error from a Success result.',
    ),
    Failure<T>(:final error) => error,
  };
}

/// A successful [Result] containing a value.
class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

/// A failed [Result] containing a [MatchFailure].
class Failure<T> extends Result<T> {
  const Failure(this.error);
  final MatchFailure error;
}
