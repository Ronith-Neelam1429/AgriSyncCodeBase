import 'package:agrisync/App%20Pages/Pages/Forum/PostDetails.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrisync/Components/CustomNavBar.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _searchQuery = '';

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to create a post')),
      );
      return;
    }

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post title cannot be empty')),
      );
      return;
    }

    try {
      await _firestore.collection('posts').add({
        'title': _titleController.text,
        'authorId': user.uid,
        'authorEmail': user.email,
        'upvotes': 0,
        'comments': 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  Future<bool> _hasUserVoted(String postId, String userId, String voteType) async {
    final voteDoc = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('post_votes')
        .doc(userId)
        .get();
    if (voteDoc.exists) {
      return voteDoc.data()![voteType] == true;
    }
    return false;
  }

  Future<void> _upvotePost(String postId, int currentUpvotes, String userId) async {
    if (await _hasUserVoted(postId, userId, 'upvoted')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already upvoted this post')),
      );
      return;
    }

    try {
      await _firestore.collection('posts').doc(postId).update({
        'upvotes': currentUpvotes + 1,
      });
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('post_votes')
          .doc(userId)
          .set({
        'upvoted': true,
        'downvoted': false,
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error upvoting post: $e')),
      );
    }
  }

  Future<void> _downvotePost(String postId, int currentUpvotes, String userId) async {
    if (currentUpvotes <= 0) return;
    if (await _hasUserVoted(postId, userId, 'downvoted')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have already downvoted this post')),
      );
      return;
    }

    try {
      await _firestore.collection('posts').doc(postId).update({
        'upvotes': currentUpvotes - 1,
      });
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('post_votes')
          .doc(userId)
          .set({
        'upvoted': false,
        'downvoted': true,
      }, SetOptions(merge: true));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downvoting post: $e')),
      );
    }
  }

  void _showCreatePostModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 39, 39, 39),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a Post',
                style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: "What's on your mind?",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 27, 94, 32).withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 87, 189, 179),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Post', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final userId = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 0, 0)),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CustomNavBar()),
            );
          },
        ),
        title: const Text(
          'AgriSync Forum',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar under the app bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color.fromARGB(255, 87, 189, 179)),
                filled: true,
                fillColor: const Color.fromARGB(255, 226, 226, 226),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // Forum content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('posts').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No posts yet. Be the first to share!',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final posts = snapshot.data!.docs;
                  // Filter posts based on search query
                  final filteredPosts = _searchQuery.isEmpty
                      ? posts
                      : posts.where((post) {
                          final data = post.data() as Map<String, dynamic>;
                          final title = (data['title'] as String? ?? '').toLowerCase();
                          final author = (data['authorEmail'] as String? ?? '').toLowerCase();
                          return title.contains(_searchQuery) || author.contains(_searchQuery);
                        }).toList();

                  if (filteredPosts.isEmpty) {
                    return const Center(
                      child: Text(
                        'No posts match your search',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      final data = post.data() as Map<String, dynamic>;
                      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                      final timeAgo = timestamp != null
                          ? _formatTimeAgo(timestamp)
                          : 'Just now';

                      return Card(
                        color: const Color.fromARGB(255, 39, 39, 39),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        elevation: 5,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostDetailsPage(postId: post.id, postData: data),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_upward, color: Color.fromARGB(255, 87, 189, 179)),
                                      onPressed: () => _upvotePost(post.id, data['upvotes'] ?? 0, userId),
                                    ),
                                    Text(
                                      '${data['upvotes'] ?? 0}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_downward, color: Color.fromARGB(255, 87, 189, 179)),
                                      onPressed: () => _downvotePost(post.id, data['upvotes'] ?? 0, userId),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['title'] ?? 'Untitled',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Text(
                                            'u/${data['authorEmail']?.split('@')[0] ?? 'Anonymous'}',
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            timeAgo,
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${data['comments'] ?? 0} comments',
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        backgroundColor: const Color.fromARGB(255, 87, 189, 179),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) return '${difference.inSeconds}s ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 30) return '${difference.inDays}d ago';
    return '${(difference.inDays / 30).floor()}mo ago';
  }
}