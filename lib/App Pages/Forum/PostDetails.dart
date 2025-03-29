import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/Services/forum_service.dart';

class PostDetailsPage extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const PostDetailsPage({super.key, required this.postId, required this.postData});

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _hasUserVoted(String commentId, String userId, String voteType) async {
    final voteDoc = await _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId).collection('comment_votes').doc(userId).get();
    return voteDoc.exists && voteDoc.data()![voteType] == true;
  }

  Future<void> _upvoteComment(String commentId, int currentUpvotes, String userId) async {
    if (await _hasUserVoted(commentId, userId, 'upvoted')) return;
    await _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId).update({'upvotes': currentUpvotes + 1});
    await _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId).collection('comment_votes').doc(userId).set({'upvoted': true, 'downvoted': false}, SetOptions(merge: true));
  }

  Future<void> _downvoteComment(String commentId, int currentUpvotes, String userId) async {
    if (currentUpvotes <= 0 || await _hasUserVoted(commentId, userId, 'downvoted')) return;
    await _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId).update({'upvotes': currentUpvotes - 1});
    await _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId).collection('comment_votes').doc(userId).set({'upvoted': false, 'downvoted': true}, SetOptions(merge: true));
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

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';
    final timeAgo = _formatTimeAgo((widget.postData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Post', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 39, 39, 39),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(widget.postData['title'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('u/${widget.postData['authorEmail']?.split('@')[0] ?? 'Anonymous'} • $timeAgo', style: const TextStyle(color: Colors.grey)),
                  if (widget.postData['content']?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Text(widget.postData['content'], style: const TextStyle(color: Colors.white)),
                  ],
                  const SizedBox(height: 8),
                  Text('${widget.postData['upvotes'] ?? 0} upvotes • ${widget.postData['comments'] ?? 0} comments', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.grey),
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
                    final item = commentTree[index];
                    final comment = item['comment'] as QueryDocumentSnapshot;
                    final depth = item['depth'] as int;
                    final data = comment.data() as Map<String, dynamic>;
                    final timeAgo = _formatTimeAgo((data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now());
                    return Padding(
                      padding: EdgeInsets.only(left: 8.0 + depth * 16.0, right: 8.0, top: 4.0, bottom: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              IconButton(icon: const Icon(Icons.arrow_upward, color: Color.fromARGB(255, 87, 189, 179), size: 16), onPressed: () => _upvoteComment(comment.id, data['upvotes'] ?? 0, userId)),
                              Text('${data['upvotes'] ?? 0}', style: const TextStyle(color: Colors.white)),
                              IconButton(icon: const Icon(Icons.arrow_downward, color: Color.fromARGB(255, 87, 189, 179), size: 16), onPressed: () => _downvoteComment(comment.id, data['upvotes'] ?? 0, userId)),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('u/${data['authorEmail']?.split('@')[0] ?? 'Anonymous'} • $timeAgo', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(data['content'], style: const TextStyle(color: Colors.white)),
                                TextButton(
                                  onPressed: () => setState(() => _replyTo = {'id': comment.id, 'username': data['authorEmail']?.split('@')[0] ?? 'Anonymous'}),
                                  child: const Text('Reply', style: TextStyle(color: Color.fromARGB(255, 87, 189, 179))),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: _replyTo != null ? 'Reply to u/${_replyTo!['username']}' : 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 39, 39, 39),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_replyTo != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color.fromARGB(255, 87, 189, 179)),
                  onPressed: () => _addComment(parentId: _replyTo?['id']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds}s';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 30) return '${difference.inDays}d';
    return '${(difference.inDays / 30).floor()}mo';
  }
}