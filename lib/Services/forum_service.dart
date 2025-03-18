import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get a stream of forum posts, sorted by timestamp (newest first)
  Stream<QuerySnapshot> getForumPosts() {
    return _firestore
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Create a new post
  Future<void> createPost(String title, String? content) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('posts').add({
        'title': title,
        'content': content ?? '',
        'authorId': user.uid,
        'authorEmail': user.email,
        'upvotes': 0,
        'comments': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }

  // Get comments for a specific post, including nested comments
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a comment (supports nested replies via parentId)
  Future<void> sendComment(String postId, String content, {String? parentId}) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'content': content,
        'authorId': user.uid,
        'authorEmail': user.email,
        'upvotes': 0,
        'timestamp': FieldValue.serverTimestamp(),
        'parentId': parentId,
      });
      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.increment(1),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }
}