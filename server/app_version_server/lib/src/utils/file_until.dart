import 'dart:developer';
import 'dart:io';

class UntilFile {
  String getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'apk':
        return 'application/vnd.android.package-archive';
      case 'ipa':
        return 'application/octet-stream';
      case 'zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}

mixin FileUntil {
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      log('Error deleting file: $e');
      return false;
    }
  }

  String getFilePathFromUrl(String url) {
    if (url.startsWith('/')) {
      return url.substring(1);
    }
    return url;
  }

  String? extractFilename(String contentDisposition) {
    try {
      return RegExp(
        r'filename="([^"]+)"',
      ).firstMatch(contentDisposition)?.group(1);
    } catch (e) {
      return null;
    }
  }

  String getBoundary(String contentType) {
    try {
      return contentType.split('boundary=')[1].split(';')[0].trim();
    } catch (e) {
      return '';
    }
  }
}
