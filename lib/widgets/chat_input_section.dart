import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

// Import the color constants
const kPlaceholderGray = Color(0xFFC4C4C4);
const kDarkGray = Color(0xFF505050);
const kIndigo = Color(0xFF6366F1);
const kLightIndigo = Color(0xFFEEF4FF);

class ChatInputSection extends StatelessWidget {
  final TextEditingController messageController;
  final bool isNewChat;
  final bool isSendEnabled;
  final VoidCallback onNewChat;
  final VoidCallback onSendMessage;
  final VoidCallback onFileSelection;
  final VoidCallback? onCameraCapture;
  final VoidCallback? onFilePicker;
  final Function(ChatProvider) clearCurrentChat;
  final FileUploadState? uploadedFile;
  final bool isAIResponding;
  final VoidCallback? onStopResponse;

  const ChatInputSection({
    super.key,
    required this.messageController,
    required this.isNewChat,
    required this.isSendEnabled,
    required this.onNewChat,
    required this.onSendMessage,
    required this.onFileSelection,
    this.onCameraCapture,
    this.onFilePicker,
    required this.clearCurrentChat,
    this.uploadedFile,
    this.isAIResponding = false,
    this.onStopResponse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Remove New Chat Button section and start with file preview
          if (uploadedFile != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // File icon or image preview
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: uploadedFile?.previewUrl == null
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.insert_drive_file, color: kDarkGray),
                              const CircularProgressIndicator(strokeWidth: 2),
                            ],
                          )
                        : uploadedFile?.mimeType?.startsWith('image/') == true
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  uploadedFile!.previewUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.insert_drive_file, color: kDarkGray),
                                ),
                              )
                            : const Icon(Icons.insert_drive_file, color: kDarkGray),
                  ),
                  const SizedBox(width: 12),
                  // File details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          uploadedFile?.fileName ?? 'Unknown file',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${((uploadedFile?.fileSize ?? 0) / 1024).toStringAsFixed(1)}KB',
                          style: TextStyle(
                            fontSize: 12,
                            color: kDarkGray.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: uploadedFile?.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Input Container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Message Input
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(
                    hintText: 'Message DeepSeek',
                    hintStyle: TextStyle(color: kPlaceholderGray),
                    border: InputBorder.none,
                    filled: false,
                  ),
                  style: TextStyle(color: kDarkGray),
                  onSubmitted: (_) => onSendMessage(),
                ),

                const SizedBox(height: 4),
                const SizedBox(height: 4),

                // Bottom Row with Deep Think and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Deep Think Toggle and Label
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: false,
                            onChanged: null,
                            activeColor: Colors.grey,
                            activeTrackColor: Colors.grey.withOpacity(0.5),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[300],
                          ),
                        ),
                        Text(
                          'Deep Think',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Action Buttons
                    Row(
                      children: [
                        // Disabled attachment icon
                        IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.grey[400], size: 20),
                          onPressed: null,
                          padding: const EdgeInsets.all(8),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: kLightIndigo,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(
                              isAIResponding ? Icons.stop : Icons.arrow_upward,
                              color: (isSendEnabled || uploadedFile != null || isAIResponding) ? kIndigo : Colors.white,
                              size: 20,
                            ),
                            onPressed: isAIResponding 
                              ? onStopResponse 
                              : ((isSendEnabled || uploadedFile != null) ? onSendMessage : null),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer Text
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              'AI-generated, for reference only.',
              style: TextStyle(
                color: kPlaceholderGray,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add this class to handle file upload state
class FileUploadState {
  final String fileName;
  final int fileSize;
  final String? previewUrl;
  final VoidCallback onRemove;
  final String mimeType;

  FileUploadState({
    required this.fileName,
    required this.fileSize,
    this.previewUrl,
    required this.onRemove,
    required this.mimeType,
  });
} 