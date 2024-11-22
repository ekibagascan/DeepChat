import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? fileUrl;
  final String? mimeType;
  final String? fileName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.fileUrl,
    this.mimeType,
    this.fileName,
  });

  Widget _buildFilePreview(BuildContext context) {
    if (mimeType == null || fileUrl == null) return const SizedBox();

    if (mimeType!.startsWith('image/')) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        margin: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            fileUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      );
    } else {
      // For other file types, show a file tile
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(_getFileIcon()),
          title: Text(
            fileName ?? 'File',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_formatFileType()),
          trailing: IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _handleFileAction(),
          ),
        ),
      );
    }
  }

  IconData _getFileIcon() {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType!.startsWith('image/')) return Icons.image;
    if (mimeType!.startsWith('application/pdf')) return Icons.picture_as_pdf;
    if (mimeType!.startsWith('application/msword') ||
        mimeType!.contains('wordprocessingml')) return Icons.description;
    if (mimeType!.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType!.contains('presentation')) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  String _formatFileType() {
    if (mimeType == null) return 'Unknown type';
    if (mimeType!.startsWith('application/pdf')) return 'PDF Document';
    if (mimeType!.startsWith('application/msword') ||
        mimeType!.contains('wordprocessingml')) return 'Word Document';
    if (mimeType!.contains('spreadsheet')) return 'Spreadsheet';
    if (mimeType!.contains('presentation')) return 'Presentation';
    return mimeType!.split('/').last.toUpperCase();
  }

  Future<void> _handleFileAction() async {
    if (fileUrl == null) return;

    try {
      if (mimeType?.startsWith('image/') ?? false) {
        // Open image in browser/viewer
        final uri = Uri.parse(fileUrl!);
        await launchUrl(uri);
      } else {
        // Download and open file
        await OpenFile.open(fileUrl!);
      }
    } catch (e) {
      debugPrint('Error handling file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fileUrl != null) _buildFilePreview(context),
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.blue[900] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 