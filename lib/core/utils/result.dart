import '../errors/failures.dart';

/// A generic Result class representing either a Success or Failure.
class Result<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;

  const Result.success(this.data)
      : failure = null,
        isSuccess = true;

  const Result.error(this.failure)
      : data = null,
        isSuccess = false;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    if (isSuccess) {
      return success(data as T);
    } else {
      return error(failure!);
    }
  }
}
