import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';

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

      // Get public URL using the helper method
      final fileUrl = await getFileUrl(bucketName, filePath);

      return FileUploadResult(
        url: fileUrl,
        mimeType: mimeType,
        fileName: path.basename(file.path),
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      // Extract path and bucket from URL
      final uri = Uri.parse(fileUrl);
      final path = uri.path;
      
      // Get file type from the URL to determine bucket
      String bucketName;
      if (path.contains('.jpg') || path.contains('.jpeg') || path.contains('.png')) {
        bucketName = 'chat_images';
      } else if (path.contains('.pdf')) {
        bucketName = 'chat_pdfs';
      } else if (path.contains('.doc') || path.contains('.docx')) {
        bucketName = 'chat_documents';
      } else {
        bucketName = 'chat_others';
      }

      // Extract the actual file path (everything after the bucket name in the URL)
      final filePath = path.split('/').last;
      debugPrint('Deleting file from bucket: $bucketName, path: $filePath');
      
      await _supabase.storage
        .from(bucketName)
        .remove([filePath]);
        
      debugPrint('Successfully deleted file: $filePath from bucket: $bucketName');
    } catch (e) {
      debugPrint('Error deleting file: $e');
      rethrow;
    }
  }

  // Helper method to get a signed URL that works for all file types
  Future<String> getFileUrl(String bucketName, String filePath) async {
    try {
      // First try to get a signed URL that will work even if the bucket is not public
      final signedUrl = await _supabase.storage.from(bucketName).createSignedUrl(
        filePath,
        60 * 60, // 1 hour expiry
      );
      debugPrint('Generated signed URL: $signedUrl');
      return signedUrl;
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      // Fallback to public URL if signed URL fails
      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(filePath);
      debugPrint('Fallback to public URL: $publicUrl');
      return publicUrl;
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