import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

// Web-compatible file upload helper
class WebFileUploadHelper {
  static Future<String?> uploadProfileImage({
    required String userId,
    required String imagePath,
    required Function(String, Uint8List) uploadFunction,
  }) async {
    try {
      // Preserve parameter usage to avoid unused parameter warnings
      final _ = imagePath;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('Failed to read selected file bytes');
        }

        final ext = (file.extension != null && file.extension!.isNotEmpty)
            ? file.extension!
            : 'jpg';
        final fileName =
            'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        return await uploadFunction(fileName, bytes);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('File upload error: $e');
      }
      return null;
    }
  }
}
