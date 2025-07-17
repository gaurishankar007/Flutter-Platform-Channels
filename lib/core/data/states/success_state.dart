part of 'data_state.dart';

/// A success data state when there is no any error and data is available
class SuccessState<T> extends DataState<T> {
  const SuccessState({required super.data, super.message, super.statusCode})
    : super(hasData: true);
}

/// A success data state when there is no any error and data is null
class SuccessNullState extends DataState<Null> {
  const SuccessNullState({super.message, super.statusCode})
    : super(data: null, hasData: true);
}
