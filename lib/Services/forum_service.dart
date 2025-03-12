import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getForumTopics() {
    return _firestore
        .collection('forum_topics')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createTopic(String title, String description) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('forum_topics').add({
        'title': title,
        'description': description,
        'creator': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }

  Stream<QuerySnapshot> getMessages(String topicId) {
    return _firestore
        .collection('forum_topics')
        .doc(topicId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(String topicId, String message) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore
          .collection('forum_topics')
          .doc(topicId)
          .collection('messages')
          .add({
        'message': message,
        'sender': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }
}