import 'package:flutter/material.dart';
import 'package:agrisync/Services/forum_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomPage extends StatefulWidget {
  final String topicId;
  const ChatRoomPage({super.key, required this.topicId});

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ForumService _service = ForumService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, String>? _replyTo;

  void _sendMessage({String? parentId}) async {
    if (_messageController.text.isNotEmpty) {
      await _service.sendComment(widget.topicId, _messageController.text, parentId: parentId);
      _messageController.clear();
      setState(() => _replyTo = null);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  List<Map<String, dynamic>> buildMessageTree(List<QueryDocumentSnapshot> messages, String? parentId, int depth) {
    List<Map<String, dynamic>> result = [];
    for (var message in messages) {
      var data = message.data() as Map<String, dynamic>;
      if (data['parentId'] == parentId) {
        result.add({'message': message, 'depth': depth});
        result.addAll(buildMessageTree(messages, message.id, depth + 1));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Chat Room', style: TextStyle(color: Colors.white)), backgroundColor: const Color.fromARGB(255, 39, 39, 39)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getComments(widget.topicId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;
                final messageTree = buildMessageTree(messages, null, 0);
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messageTree.length,
                  itemBuilder: (context, index) {
                    final item = messageTree[index];
                    final message = item['message'] as QueryDocumentSnapshot;
                    final depth = item['depth'] as int;
                    final data = message.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(left: 8.0 + depth * 16.0, right: 8.0, top: 4.0),
                      child: ListTile(
                        title: Text('${data['sender']} ${data['parentId'] != null ? '(reply)' : ''}', style: const TextStyle(color: Colors.white)),
                        subtitle: Text(data['message'], style: const TextStyle(color: Colors.grey)),
                        trailing: TextButton(
                          onPressed: () => setState(() => _replyTo = {'id': message.id, 'username': data['sender']}),
                          child: const Text('Reply', style: TextStyle(color: Color.fromARGB(255, 87, 189, 179))),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _replyTo != null ? 'Reply to ${_replyTo!['username']}' : 'Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 39, 39, 39),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_replyTo != null)
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _replyTo = null)),
                IconButton(icon: const Icon(Icons.send, color: Color.fromARGB(255, 87, 189, 179)), onPressed: () => _sendMessage(parentId: _replyTo?['id'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}