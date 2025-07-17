import 'dart:typed_data' show Uint8List;

import 'package:file_picker/file_picker.dart';

import '../data/errors/data_handler.dart';

class FilePickerUtil {
  const FilePickerUtil._();

  /// Make sure to use full file name with extension
  /// e.g. 'example.txt' or 'image.png'
  static Future<bool> saveFile({
    required Uint8List fileData,
    required String fileName,
    String dialogTitle = 'Save your file',
  }) async {
    try {
      // Let the user pick a save location and filename
      await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.any,
        bytes: fileData,
      );

      return true;
    } catch (e) {
      ErrorHandler.debugError(e);
      return false;
    }
  }

  static Future<String?> pickDirectory() async =>
      await FilePicker.platform.getDirectoryPath();
}
