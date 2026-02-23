import 'package:nae_mo/core/errors/failure.dart';

typedef Result<T> = ({T? data, Failure? failure});

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => failure == null && data != null;
  bool get isFailure => failure != null;

  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    if (isSuccess) return onSuccess(data as T);
    return onFailure(failure!);
  }
}

Result<T> success<T>(T data) => (data: data, failure: null);
Result<T> fail<T>(Failure failure) => (data: null, failure: failure);
