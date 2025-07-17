part of 'data_handler.dart';

class ErrorHandler {
  ErrorHandler._();

  /// Catches exceptions and logs the error.
  static Future<void> catchException(Function() callBack) async {
    try {
      await callBack();
    } catch (error, stackTrace) {
      debugError(error, stackTrace);
    }
  }

  /// Handles exceptions and returns appropriate failure states.
  static FutureData<T> handleException<T>(
    FutureData<T> Function() callBack,
  ) async {
    try {
      return await callBack();
    } on ServerResponseError {
      debugError("Invalid response from the server.");
      return BadResponseState<T>();
    } on TypeError catch (error, stackTrace) {
      debugError(error, stackTrace);
      return FailureState.typeError();
    } on FormatException catch (exception, stackTrace) {
      debugError(exception, stackTrace);
      return FailureState.formatError();
    } catch (error, stackTrace) {
      debugError(error, stackTrace);
      return FailureState<T>(message: error.toString());
    }
  }

  static void debugError(Object? error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      log(
        "<--------- Caught Exception ---------->",
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
