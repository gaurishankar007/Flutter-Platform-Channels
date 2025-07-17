import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show immutable;

part 'failure_state.dart';
part 'loading_state.dart';
part 'success_state.dart';

@immutable
sealed class DataState<T> extends Equatable {
  final T? data;
  final String? message;
  final ErrorType? errorType;
  final int? statusCode;
  final bool hasData;
  final bool hasError;

  const DataState({
    this.data,
    this.message,
    this.errorType,
    this.statusCode,
    this.hasData = false,
    this.hasError = false,
  });

  R when<R>({
    required R Function(T data) success,
    required R Function(String? message, ErrorType? errorType) failure,
    required R Function() loading,
  }) {
    if (this is SuccessState<T>) {
      return success((this as SuccessState<T>).data as T);
    } else if (this is FailureState<T>) {
      return failure(
        (this as FailureState<T>).message,
        (this as FailureState<T>).errorType,
      );
    } else if (this is LoadingState<T>) {
      return loading();
    } else {
      return loading(); //Default loading state.
    }
  }

  R map<R>({
    required R Function(SuccessState<T> value) success,
    required R Function(FailureState<T> value) failure,
    required R Function(LoadingState<T> value) loading,
  }) {
    if (this is SuccessState<T>) {
      return success(this as SuccessState<T>);
    } else if (this is FailureState<T>) {
      return failure(this as FailureState<T>);
    } else if (this is LoadingState<T>) {
      return loading(this as LoadingState<T>);
    } else {
      return loading(LoadingState<T>()); //Default loading state.
    }
  }

  @override
  List<Object?> get props => [
    data,
    message,
    errorType,
    statusCode,
    hasData,
    hasError,
  ];
}
