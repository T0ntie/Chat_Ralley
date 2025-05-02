import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:hello_world/app_resources.dart';
import 'package:hello_world/engine/conversation.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final BuildContext context;

  const MessageBubble({required this.message, required this.context});

  @override
  Widget build(BuildContext context) {
    final bool fromUser = message.fromUser;

    return Column(
      crossAxisAlignment:
      fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fromUser
                ? ResourceColors.userChatBubble(context)
                : ResourceColors.assistantChatBubble(context),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: fromUser ? Radius.circular(12) : Radius.zero,
              bottomRight: fromUser ? Radius.zero : Radius.circular(12),
            ),
          ),
          child: Text(message.filteredText),
        ),
      ],
    );
  }
}

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool isSending;
  final VoidCallback onSendPressed;

  const InputBar({
    required this.controller,
    required this.scrollController,
    required this.isSending,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      color: ResourceColors.messageFieldBackground(context),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Scrollbar(
                  child: TextField(
                    controller: controller,
                    scrollController: scrollController,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: "Nachricht schreiben...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send),
                color: ResourceColors.messageSendButton(context),
                onPressed: isSending ? null : onSendPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class SendingOverlay extends StatelessWidget {
  const SendingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: ResourceColors.messageDialogBackground(context).withAlpha((0.6 * 255).toInt()),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}


