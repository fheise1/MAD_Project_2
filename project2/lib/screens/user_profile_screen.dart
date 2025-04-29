import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
  }

  Future<void> _moveBookBetweenLists({
    required String fromList,
    required String toList,
    required String bookId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection(fromList)
          .doc(bookId)
          .get();

      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection(toList)
          .doc(bookId)
          .set(doc.data()!);

      await _firestore
          .collection('users')
          .doc(_currentUser.uid)
          .collection(fromList)
          .doc(bookId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Book moved to $toList')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving book: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: userData['photoUrl'] != null 
                          ? NetworkImage(userData['photoUrl']) 
                          : null,
                      child: userData['photoUrl'] == null 
                          ? Icon(Icons.person, size: 40) 
                          : null,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['username'] ?? 'No username',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Member since ${userData['joinDate']?.toDate().year ?? 'unknown'}',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),

            _buildReadingListSection('Want to Read', 'want_to_read'),
            _buildReadingListSection('Currently Reading', 'currently_reading'),
            _buildReadingListSection('Finished', 'finished'),

            Text(
              'Your Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reviews')
                  .where('userId', isEqualTo: _currentUser.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final review = doc.data() as Map<String, dynamic>;
                    return _buildReviewItem(
                      review['bookTitle'],
                      review['content'],
                      review['rating'],
                      doc.id,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingListSection(String title, String collectionName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (collectionName == 'want_to_read')
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  // TODO: Implement book search to add to list
                },
              ),
          ],
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_currentUser.uid)
              .collection(collectionName)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Text('No books in this list yet');
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final book = Book.fromJson(doc.data() as Map<String, dynamic>);
                return _buildBookListItem(book, collectionName);
              }).toList(),
            );
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBookListItem(Book book, String currentList) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: book.thumbnail.isNotEmpty
            ? Image.network(
                book.thumbnail,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.book),
              )
            : Container(
                width: 50,
                height: 70,
                color: Colors.grey[200],
                child: Icon(Icons.book),
              ),
        title: Text(book.title),
        subtitle: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            Text(' ${book.rating}'),
          ],
        ),
        trailing: _buildListActions(book, currentList),
        onTap: () {
          // TODO: Navigate to book details
        },
      ),
    );
  }

  Widget _buildListActions(Book book, String currentList) {
    if (currentList == 'want_to_read') {
      return IconButton(
        icon: Icon(Icons.playlist_add),
        onPressed: () => _moveBookBetweenLists(
          fromList: 'want_to_read',
          toList: 'currently_reading',
          bookId: book.id,
        ),
      );
    } else if (currentList == 'currently_reading') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () => _moveBookBetweenLists(
              fromList: 'currently_reading',
              toList: 'finished',
              bookId: book.id,
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => _moveBookBetweenLists(
              fromList: 'currently_reading',
              toList: 'want_to_read',
              bookId: book.id,
            ),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  Widget _buildReviewItem(String bookTitle, String review, int rating, String reviewId) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bookTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () async {
                    await _firestore
                        .collection('reviews')
                        .doc(reviewId)
                        .delete();
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  Icons.star,
                  size: 16,
                  color: index < rating ? Colors.amber : Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(review),
          ],
        ),
      ),
    );
  }
}