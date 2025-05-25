import 'package:flutter/material.dart';
import '../../engine/conversation.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  //final BuildContext context;

  const MessageBubble({super.key, required this.message});

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

          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    fromUser
                        ? [
                          Colors.blueGrey.shade700.withAlpha((0.6*255).toInt()),
                          Colors.blueGrey.shade800.withAlpha((0.8*255).toInt()),
                        ]
                        : [
                          Colors.grey.shade700.withAlpha((0.6*255).toInt()),
                          Colors.grey.shade700.withAlpha((0.8*255).toInt()),
                        ],
                //[Colors.grey.shade700, Colors.grey.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: fromUser ? Radius.circular(12) : Radius.zero,
                bottomRight: fromUser ? Radius.zero : Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Text(
              message.filteredText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ),
        /*
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
        ),*/
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
    super.key,
    required this.controller,
    required this.scrollController,
    required this.isSending,
    required this.onSendPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              scrollController: scrollController,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enabled: !isSending,
              style: TextStyle(color: isSending ? Colors.black26 : Colors.black87,),
              decoration: InputDecoration(
                hintText: "Nachricht schreiben...",
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          AnimatedSendButton(
            isDisabled: isSending,
            onPressed: onSendPressed,
          ),
/*
          IconButton(
            icon: Icon(Icons.send),
            color: isSending ? Colors.grey : Colors.blueGrey.shade700,
            onPressed: isSending ? null : onSendPressed,
            tooltip: 'Senden',
          ),
*/
        ],
      ),
    );

    /*
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
*/
  }
}

class SendingOverlay extends StatelessWidget {
  const SendingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.surface.withAlpha((0.6 * 255).toInt()),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class AnimatedSendButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isDisabled;

  const AnimatedSendButton({
    super.key,
    required this.onPressed,
    required this.isDisabled,
  });

  @override
  State<AnimatedSendButton> createState() => _AnimatedSendButtonState();
}

class _AnimatedSendButtonState extends State<AnimatedSendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);
  }

  void _onPressed() {
    if (!widget.isDisabled) {
      _controller.forward().then((_) => _controller.reverse());
      widget.onPressed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(Icons.send),
        color: widget.isDisabled ? Colors.grey : Colors.blueGrey.shade700,
        onPressed: widget.isDisabled ? null : _onPressed,
        tooltip: 'Senden',
      ),
    );
  }
}
