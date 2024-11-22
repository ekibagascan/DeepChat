import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class StorageService {
  final _supabase = Supabase.instance.client;

  // Get bucket name based on file type
  String _getBucketName(String mimeType) {
    if (mimeType.startsWith('image/')) {
      return 'chat_images';
    } else if (mimeType.startsWith('application/pdf')) {
      return 'chat_pdfs';
    } else if (mimeType.startsWith('application/')) {
      return 'chat_documents';
    } else {
      return 'chat_others';
    }
  }

  Future<FileUploadResult> uploadFile(File file, String userId) async {
    try {
      final fileExt = path.extension(file.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final filePath = '$userId/$fileName';
      
      // Detect file type
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final bucketName = _getBucketName(mimeType);

      // Upload to Supabase Storage
      await _supabase
          .storage
          .from(bucketName)
          .upload(filePath, file);

      // Get public URL
      final fileUrl = _supabase
          .storage
          .from(bucketName)
          .getPublicUrl(filePath);

      return FileUploadResult(
        url: fileUrl,
        mimeType: mimeType,
        fileName: path.basename(file.path),
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl, String mimeType) async {
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final filePath = pathSegments.sublist(2).join('/');
      final bucketName = _getBucketName(mimeType);

      await _supabase
          .storage
          .from(bucketName)
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }
}

class FileUploadResult {
  final String url;
  final String mimeType;
  final String fileName;

  FileUploadResult({
    required this.url,
    required this.mimeType,
    required this.fileName,
  });
} 