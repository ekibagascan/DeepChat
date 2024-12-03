import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'dart:math' show sin, pi;

class _BouncingDot extends StatefulWidget {
  final int index;
  
  const _BouncingDot({required this.index});
  
  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.translate(
            offset: Offset(0, _animation.value + (widget.index - 1) * 1.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class FeedbackDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const FeedbackDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('What could be improved?'),
      content: TextField(
        controller: _feedbackController,
        decoration: const InputDecoration(
          hintText: 'Please provide your feedback...',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final feedback = _feedbackController.text.trim();
            if (feedback.isNotEmpty) {
              widget.onSubmit(feedback);
            }
            Navigator.pop(context);
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class ResponseActions extends StatelessWidget {
  final String messageContent;
  final VoidCallback onRegenerate;
  final VoidCallback onLike;
  final Function(String?) onDislike;

  const ResponseActions({
    super.key,
    required this.messageContent,
    required this.onRegenerate,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: messageContent));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Response copied to clipboard')),
            );
          },
          color: Colors.grey[600],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.refresh, size: 16),
          onPressed: onRegenerate,
          color: Colors.grey[600],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.thumb_up_outlined, size: 16),
          onPressed: onLike,
          color: Colors.grey[600],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.thumb_down_outlined, size: 16),
          onPressed: () async {
            showDialog(
              context: context,
              builder: (context) => FeedbackDialog(
                onSubmit: onDislike,
              ),
            );
          },
          color: Colors.grey[600],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
      ],
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String? fileUrl;
  final String? mimeType;
  final String? fileName;
  final String? userEmail;
  final bool isAssistant;
  final bool isTyping;
  final String? messageId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.fileUrl,
    this.mimeType,
    this.fileName,
    this.userEmail,
    required this.isAssistant,
    this.isTyping = false,
    this.messageId,
  });

  Widget _buildDot(int index) {
    return _BouncingDot(index: index);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  backgroundImage: const AssetImage('assets/ai_avatar.png'),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (fileUrl != null && mimeType?.startsWith('image/') == true)
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      maxHeight: 200,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        fileUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading image: $error');
                          return Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (message.isNotEmpty || isTyping)
                  Container(
                    margin: EdgeInsets.only(top: fileUrl != null ? 8 : 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFEFF6FF) : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: isTyping && message.isEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDot(0),
                              _buildDot(1),
                              _buildDot(2),
                            ],
                          )
                        : Text(
                            message,
                            style: TextStyle(
                              color: isUser ? const Color(0xFF6366F1) : Colors.black,
                              height: 1.4,
                            ),
                          ),
                  ),
                if (isAssistant && !isTyping) ...[
                  const SizedBox(height: 4),
                  ResponseActions(
                    messageContent: message,
                    onRegenerate: () {
                      final messages = context.read<ChatProvider>().messages;
                      final index = messages.indexOf(messages.firstWhere((m) => m['content'] == message));
                      if (index > 0) {
                        final previousUserMessage = messages[index - 1]['content'] as String;
                        context.read<ChatProvider>().regenerateResponse(previousUserMessage);
                      }
                    },
                    onLike: () {
                      if (messageId != null) {
                        context.read<ChatProvider>().handleFeedback(messageId!, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thanks for your feedback!')),
                        );
                      }
                    },
                    onDislike: (feedbackMessage) {
                      if (messageId != null) {
                        context.read<ChatProvider>().handleFeedback(messageId!, false, feedbackMessage);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thanks for your feedback!')),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
} 