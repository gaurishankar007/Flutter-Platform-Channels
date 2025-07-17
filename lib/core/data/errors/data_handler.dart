import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kDebugMode;

import '../../utils/type_defs.dart';
import '../states/data_state.dart';

part 'error_handler.dart';
part 'error_types.dart';

/// Handles flutter, api, local database errors and returns suitable [DataState]
/// Checks for internet connection and returns suitable [DataState]
class DataHandler {
  DataHandler._();

  /// Executes [remoteCallback] if internet is available.
  /// If successful and [successCallback] is provided, it gets called with the result.
  /// If offline, executes [localCallback] if provided; otherwise returns [NoInternetState].
  static FutureData<T> fetchWithFallback<T>(
    bool isInternetConnected, {
    required FutureData<T> Function() remoteCallback,
    Function(T data)? successCallback,
    FutureData<T> Function()? localCallback,
  }) async {
    if (isInternetConnected) {
      final dataState = await remoteCallback();
      final data = dataState.data;

      if (data != null && successCallback != null) successCallback(data);
      return dataState;
    }

    return localCallback != null ? await localCallback() : NoInternetState();
  }
}
