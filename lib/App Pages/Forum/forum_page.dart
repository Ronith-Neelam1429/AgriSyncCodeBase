import 'package:agrisync/Services/forum_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/App%20Pages/Forum/PostDetails.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';
  String _sortBy = 'new';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in and provide a title')),
      );
      return;
    }
    try {
      await ForumService()
          .createPost(_titleController.text, _contentController.text);
      _titleController.clear();
      _contentController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _hasUserVoted(
      String postId, String userId, String voteType) async {
    final voteDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('post_votes')
        .doc(userId)
        .get();
    return voteDoc.exists && voteDoc.data()![voteType] == true;
  }

  Future<void> _upvotePost(
      String postId, int currentUpvotes, String userId) async {
    if (await _hasUserVoted(postId, userId, 'upvoted')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already upvoted this post')),
      );
      return;
    }
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({'upvotes': currentUpvotes + 1});
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('post_votes')
        .doc(userId)
        .set({'upvoted': true, 'downvoted': false}, SetOptions(merge: true));
  }

  Future<void> _downvotePost(
      String postId, int currentUpvotes, String userId) async {
    if (currentUpvotes <= 0 ||
        await _hasUserVoted(postId, userId, 'downvoted')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already downvoted this post')),
      );
      return;
    }
    await _firestore
        .collection('posts')
        .doc(postId)
        .update({'upvotes': currentUpvotes - 1});
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('post_votes')
        .doc(userId)
        .set({'upvoted': false, 'downvoted': true}, SetOptions(merge: true));
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 244, 244, 244),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: 16.0 + MediaQuery.of(context).viewInsets.bottom,
          left: 16.0,
          right: 16.0,
          top: 16.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create a Post',
                style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Title'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              decoration: _inputDecoration('Content (optional)'),
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createPost,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 87, 189, 179)),
              child: const Text('Post', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 108, 108, 108)),
        filled: true,
        fillColor: const Color.fromARGB(255, 237, 237, 237),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text('AgriSync Forum',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          DropdownButton<String>(
            value: _sortBy,
            items: ['new', 'hot', 'top']
                .map((String value) => DropdownMenuItem(
                    value: value,
                    child: Text(value.capitalize(),
                        style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0)))))
                .toList(),
            onChanged: (value) => setState(() => _sortBy = value!),
            dropdownColor: const Color.fromARGB(255, 222, 222, 222),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: _inputDecoration('Search posts...').copyWith(
                  prefixIcon: const Icon(Icons.search,
                      color: Color.fromARGB(255, 87, 189, 179))),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: _sortBy == 'new'
                    ? _firestore
                        .collection('posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots()
                    : _sortBy == 'hot'
                        ? _firestore
                            .collection('posts')
                            .orderBy('comments', descending: true)
                            .snapshots()
                        : _firestore
                            .collection('posts')
                            .orderBy('upvotes', descending: true)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final posts = snapshot.data!.docs
                      .where((post) => (post['title'] as String)
                          .toLowerCase()
                          .contains(_searchQuery))
                      .toList();
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        final data = post.data() as Map<String, dynamic>;
                        final timeAgo = _formatTimeAgo(
                            (data['timestamp'] as Timestamp?)?.toDate() ??
                                DateTime.now());
                        // Updated ListTile implementation
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          minVerticalPadding: 0,
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color.fromARGB(255, 87, 189, 179),
                            child: Text(
                              data['authorEmail']
                                      ?.split('@')[0][0]
                                      .toUpperCase() ??
                                  'A',
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 12),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'],
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Row(
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.arrow_upward,
                                            size: 16,
                                            color: Color.fromARGB(
                                                255, 87, 189, 179)),
                                        onPressed: () => _upvotePost(post.id,
                                            data['upvotes'] ?? 0, userId)),
                                    Text('${data['upvotes'] ?? 0}',
                                        style: const TextStyle(
                                            color: Colors.black)),
                                    IconButton(
                                        icon: const Icon(Icons.arrow_downward,
                                            size: 16,
                                            color: Color.fromARGB(
                                                255, 87, 189, 179)),
                                        onPressed: () => _downvotePost(post.id,
                                            data['upvotes'] ?? 0, userId)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                  'u/${data['authorEmail']?.split('@')[0] ?? 'Anonymous'} • $timeAgo',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.chat_bubble_outline,
                                  color: Colors.grey, size: 16),
                              Text(' ${data['comments'] ?? 0}',
                                  style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PostDetailsPage(
                                      postId: post.id, postData: data))),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton(
          onPressed: _showCreatePostModal,
          backgroundColor: const Color.fromARGB(255, 87, 189, 179),
          child: const Icon(Icons.add, color: Colors.white),
        ),
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

extension StringExtension on String {
  String capitalize() => this[0].toUpperCase() + substring(1);
}
