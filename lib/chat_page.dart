import 'package:flutter/material.dart';
import 'package:hello_world/engine/game_engine.dart';
import 'engine/npc.dart';
import 'engine/conversation.dart';
import 'gui/snack_bar_service.dart';

class ChatPage extends StatefulWidget {
  ChatPage({super.key, required this.npc,});
  final Npc npc;
  final GameEngine gameEngine = GameEngine.instance;


  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  late  Conversation _conversation;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _conversation = widget.npc.currentConversation;
  }

  bool _isSending = false;

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _conversation.addUserMessage(text);
      _isSending = true;
    });
    try {
      String response = await _conversation.processConversation();

      setState(() {
        _conversation.addAssistantMessage(response);
      });
    } catch (e) {
      SnackBarService.showErrorSnackBar(context, '❌ Kommunikation mit Chat GPT fehlgeschlagen.');
    } finally {
      setState(() {
        _isSending = false;
      });
      _controller.clear();
    }
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final alignment = msg.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = msg.fromUser ? Colors.green[200] : Colors.grey[300];
    final radius = msg.fromUser
        ? BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: Radius.circular(12),
    )
        : BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
          ),
          child: Text(msg.filteredText),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _conversation.getVisibleMessages();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.npc.displayName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final reversedIndex = messages.length - 1 - index;
                return _buildMessageBubble(messages[reversedIndex]);
              },
            ),
          ),
          Divider(height: 1),

          Container(
            padding: EdgeInsets.all(8),
            color: Colors.white,
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
                          controller: _controller,
                          scrollController: _scrollController,
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
                      color: Colors.green,
                      onPressed: _isSending ?null : () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

}
