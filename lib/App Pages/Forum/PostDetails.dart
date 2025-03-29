import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/Services/forum_service.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({Key? key, required this.postId, required this.postData}) : super(key: key);

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, String>? _replyTo;

  Future<void> _addComment({String? parentId}) async {
    final user = _auth.currentUser;
    if (user == null || _commentController.text.isEmpty) return;
    try {
      await ForumService().sendComment(widget.postId, _commentController.text, parentId: parentId);
      _commentController.clear();
      setState(() => _replyTo = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _hasUserVoted(String commentId, String userId, String voteType) async {
    final voteDoc = await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .doc(commentId)
        .collection('comment_votes')
        .doc(userId)
        .get();
    return voteDoc.exists && voteDoc.data()![voteType] == true;
  }

  Future<void> _upvoteComment(String commentId, int currentUpvotes, String userId) async {
    if (await _hasUserVoted(commentId, userId, 'upvoted')) return;
    await _firestore.collection('posts').doc(widget.postId)
        .collection('comments').doc(commentId)
        .update({'upvotes': currentUpvotes + 1});
    await _firestore.collection('posts').doc(widget.postId)
        .collection('comments').doc(commentId)
        .collection('comment_votes').doc(userId)
        .set({'upvoted': true, 'downvoted': false}, SetOptions(merge: true));
  }

  Future<void> _downvoteComment(String commentId, int currentUpvotes, String userId) async {
    if (currentUpvotes <= 0 || await _hasUserVoted(commentId, userId, 'downvoted')) return;
    await _firestore.collection('posts').doc(widget.postId)
        .collection('comments').doc(commentId)
        .update({'upvotes': currentUpvotes - 1});
    await _firestore.collection('posts').doc(widget.postId)
        .collection('comments').doc(commentId)
        .collection('comment_votes').doc(userId)
        .set({'upvoted': false, 'downvoted': true}, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> buildCommentTree(List<QueryDocumentSnapshot> comments, String? parentId, int depth) {
    List<Map<String, dynamic>> result = [];
    for (var comment in comments) {
      var data = comment.data() as Map<String, dynamic>;
      if (data['parentId'] == parentId) {
        result.add({'comment': comment, 'depth': depth});
        result.addAll(buildCommentTree(comments, comment.id, depth + 1));
      }
    }
    return result;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 30) return '${diff.inDays}d';
    return '${(diff.inDays / 30).floor()}mo';
  }

  // Widget for individual comment bubble
  Widget _buildCommentBubble(Map<String, dynamic> commentData, int depth) {
    final data = commentData['comment'].data() as Map<String, dynamic>;
    final timeAgo = _formatTimeAgo((data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now());
    return Padding(
      padding: EdgeInsets.only(left: 16.0 + depth * 16.0, right: 16.0, top: 8.0, bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('u/${data['authorEmail']?.split('@')[0] ?? 'Anonymous'} • $timeAgo',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(data['content'], style: const TextStyle(color: Colors.black, fontSize: 14)),
            Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 16, color: Color.fromARGB(255, 66, 192, 201)),
                    onPressed: () {
                      final userId = _auth.currentUser?.uid ?? '';
                      _upvoteComment(commentData['comment'].id, data['upvotes'] ?? 0, userId);
                    }),
                Text('${data['upvotes'] ?? 0}', style: const TextStyle(color: Colors.black, fontSize: 12)),
                IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 16, color: Color.fromARGB(255, 66, 192, 201)),
                    onPressed: () {
                      final userId = _auth.currentUser?.uid ?? '';
                      _downvoteComment(commentData['comment'].id, data['upvotes'] ?? 0, userId);
                    }),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _replyTo = {'id': commentData['comment'].id, 'username': data['authorEmail']?.split('@')[0] ?? 'Anonymous'};
                    });
                  },
                  child: const Text('Reply', style: TextStyle(color: Color.fromARGB(255, 66, 192, 201))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';
    final postTime = _formatTimeAgo((widget.postData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now());
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Post Details', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          // Post Header Card
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 3,
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.postData['title'],
                        style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('u/${widget.postData['authorEmail']?.split('@')[0] ?? 'Anonymous'} • $postTime',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    if (widget.postData['content']?.isNotEmpty ?? false)
                      Text(widget.postData['content'],
                          style: const TextStyle(color: Colors.black, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.thumb_up, size: 16, color: const Color.fromARGB(255, 66, 192, 201)),
                        const SizedBox(width: 4),
                        Text('${widget.postData['upvotes'] ?? 0}', style: const TextStyle(color: Colors.black)),
                        const SizedBox(width: 16),
                        Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${widget.postData['comments'] ?? 0}', style: const TextStyle(color: Colors.black)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(color: Colors.grey),
          // Comments Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ForumService().getComments(widget.postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final comments = snapshot.data!.docs;
                final commentTree = buildCommentTree(comments, null, 0);
                return ListView.builder(
                  itemCount: commentTree.length,
                  itemBuilder: (context, index) {
                    final commentData = commentTree[index];
                    final depth = commentData['depth'] as int;
                    return _buildCommentBubble(commentData, depth);
                  },
                );
              },
            ),
          ),
          // Comment Input
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyTo != null ? 'Reply to u/${_replyTo!['username']}' : 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                if (_replyTo != null)
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _replyTo = null)),
                IconButton(icon: const Icon(Icons.send, color: Color.fromARGB(255, 66, 192, 201)), onPressed: () => _addComment(parentId: _replyTo?['id'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}