import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/snackbar_message.dart';

exceptionHandler(Function callback, [BuildContext? context]) async {
  try {
    await callback();
  } on PlatformException catch (error) {
    if (context != null && context.mounted) {
      showSnackBar(
        context,
        message: "Platform Exception: ${error.message}",
        color: Colors.red,
      );
    }
  } catch (error) {
    if (context != null && context.mounted) {
      showSnackBar(
        context,
        message: error.toString(),
        color: Colors.red,
      );
    }
  }
}
