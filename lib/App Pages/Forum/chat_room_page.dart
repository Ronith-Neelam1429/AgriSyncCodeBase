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
  final ForumService _service = ForumService(); // Our helper for forum stuff
  final TextEditingController _messageController = TextEditingController(); // Controls the text box for typing messages
  final ScrollController _scrollController = ScrollController(); // Keeps the chat scrolled where we want it
  Map<String, String>? _replyTo; // Tracks who we’re replying to, if anyone

  // Sends a message, either a new one or a reply
  void _sendMessage({String? parentId}) async {
    if (_messageController.text.isNotEmpty) { // Only send if there’s something typed
      await _service.sendComment(widget.topicId, _messageController.text, parentId: parentId); // Ship it off to the service
      _messageController.clear(); // Wipe the text box clean
      setState(() => _replyTo = null); // Clear the reply thing after sending
      _scrollToBottom(); // Jump to the latest message
    }
  }

  // Scrolls the chat down to the newest message
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) { // Wait a sec til the UI’s ready
      if (_scrollController.hasClients) { // Make sure the scroll thing is hooked up
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); // Smooth scroll to the bottom
      }
    });
  }

  // Builds a tree of messages so replies nest under their parents
  List<Map<String, dynamic>> buildMessageTree(List<QueryDocumentSnapshot> messages, String? parentId, int depth) {
    List<Map<String, dynamic>> result = [];
    for (var message in messages) {
      var data = message.data() as Map<String, dynamic>;
      if (data['parentId'] == parentId) { // If this message belongs to the parent we’re looking at
        result.add({'message': message, 'depth': depth}); // Add it with how deep it’s nested
        result.addAll(buildMessageTree(messages, message.id, depth + 1)); // Recursively grab its replies
      }
    }
    return result; // Hand back the full list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark vibe for the chat
      appBar: AppBar(title: const Text('Chat Room', style: TextStyle(color: Colors.white)), backgroundColor: const Color.fromARGB(255, 39, 39, 39)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getComments(widget.topicId), // Live feed of comments for this topic
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator()); // Show a spinner if we’re still loading
                final messages = snapshot.data!.docs; // Grab all the chat messages
                final messageTree = buildMessageTree(messages, null, 0); // Turn them into a nested tree
                return ListView.builder(
                  controller: _scrollController, // Tie in our scroll control
                  itemCount: messageTree.length, // How many messages we’ve got
                  itemBuilder: (context, index) {
                    final item = messageTree[index];
                    final message = item['message'] as QueryDocumentSnapshot;
                    final depth = item['depth'] as int; // How nested this message is
                    final data = message.data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(left: 8.0 + depth * 16.0, right: 8.0, top: 4.0), // Indent replies based on depth
                      child: ListTile(
                        title: Text('${data['sender']} ${data['parentId'] != null ? '(reply)' : ''}', style: const TextStyle(color: Colors.white)), // Show sender and mark replies
                        subtitle: Text(data['message'], style: const TextStyle(color: Colors.grey)), // The actual message text
                        trailing: TextButton(
                          onPressed: () => setState(() => _replyTo = {'id': message.id, 'username': data['sender']}), // Set up to reply to this message
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
                    controller: _messageController, // Where you type your message
                    decoration: InputDecoration(
                      hintText: _replyTo != null ? 'Reply to ${_replyTo!['username']}' : 'Type a message...', // Hint changes if replying
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 39, 39, 39),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_replyTo != null)
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _replyTo = null)), // Cancel reply mode
                IconButton(icon: const Icon(Icons.send, color: Color.fromARGB(255, 87, 189, 179)), onPressed: () => _sendMessage(parentId: _replyTo?['id'])), // Send the message
              ],
            ),
          ),
        ],
      ),
    );
  }
}