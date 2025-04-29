import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionBoardScreen extends StatefulWidget {
  @override
  _DiscussionBoardScreenState createState() => _DiscussionBoardScreenState();
}

class _DiscussionBoardScreenState extends State<DiscussionBoardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _postController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _addPost() async {
    if (_titleController.text.isEmpty || _postController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill both title and content')),
      );
      return;
    }

    try {
      final user = _auth.currentUser!;
      await _firestore.collection('discussion_posts').add({
        'title': _titleController.text,
        'content': _postController.text,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Anonymous',
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
        'likedBy': [],
      });

      _titleController.clear();
      _postController.clear();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleLike(String postId, List<dynamic> likedBy) async {
    final userId = _auth.currentUser!.uid;
    final isLiked = likedBy.contains(userId);

    await _firestore.collection('discussion_posts').doc(postId).update({
      'likes': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
      'likedBy': isLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('New Discussion Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                maxLength: 100,
              ),
              SizedBox(height: 12),
              TextField(
                controller: _postController,
                decoration: InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                maxLength: 1000,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addPost,
            child: Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Discussion Board'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddPostDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('discussion_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No discussions yet.\nStart the conversation!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final post = snapshot.data!.docs[index];
              final postData = post.data() as Map<String, dynamic>;
              return _buildPostCard(post.id, postData);
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(String postId, Map<String, dynamic> post) {
    final userId = _auth.currentUser?.uid;
    final isLiked = (post['likedBy'] as List<dynamic>?)?.contains(userId) ?? false;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  post['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (post['authorId'] == userId)
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await _firestore
                          .collection('discussion_posts')
                          .doc(postId)
                          .delete();
                    },
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Posted by ${post['authorName']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 12),
            Text(post['content']),
            SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: isLiked ? Colors.blue : null,
                  ),
                  onPressed: () => _toggleLike(postId, post['likedBy'] ?? []),
                ),
                Text(post['likes'].toString()),
                SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.comment_outlined),
                  onPressed: () {
                    // TODO: Implement comment functionality
                  },
                ),
                Text(post['comments'].toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}