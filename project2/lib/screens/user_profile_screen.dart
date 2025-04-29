import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = 'CcTJKS2SbpXn0JvZQoE1';

  Future<void> _moveBookBetweenLists({
    required String fromList,
    required String toList,
    required String bookId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection(fromList)
          .doc(bookId)
          .get();

      if (!doc.exists) {
        throw Exception('Book not found in $fromList');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection(toList)
          .doc(bookId)
          .set(doc.data()!);

      await _firestore
          .collection('users')
          .doc(userId)
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

  void _showAddBookDialog(String listName) {
    final _titleController = TextEditingController();
    final _authorsController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _thumbnailController = TextEditingController();
    final _ratingController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Book to ${listName.replaceAll("_", " ")}'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _authorsController,
                  decoration: InputDecoration(labelText: 'Authors (comma separated)'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _thumbnailController,
                  decoration: InputDecoration(labelText: 'Thumbnail URL'),
                ),
                TextField(
                  controller: _ratingController,
                  decoration: InputDecoration(labelText: 'Rating'),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                final bookData = {
                  'title': _titleController.text,
                  'authors': _authorsController.text.split(',').map((e) => e.trim()).toList(),
                  'description': _descriptionController.text,
                  'thumbnail': _thumbnailController.text,
                  'rating': double.tryParse(_ratingController.text) ?? 0.0,
                  'id': _firestore.collection('users').doc(userId).collection(listName).doc().id,
                };

                await _firestore
                    .collection('users')
                    .doc(userId)
                    .collection(listName)
                    .doc(bookData['id'] as String?)
                    .set(bookData);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Book added to ${listName.replaceAll("_", " ")}')),
                );
              },
              child: Text('Add Book'),
            ),
          ],
        );
      },
    );
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
              stream: _firestore.collection('users').doc(userId).snapshots(),
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
                          ? NetworkImage(userData['photoUrl'] as String)
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
                          userData['username']?.toString() ?? 'No username',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Member since ${userData['joinDate']?.toDate().year.toString() ?? 'unknown'}',
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
                  .where('userId', isEqualTo: userId)
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
                      review['bookTitle']?.toString() ?? 'No title',
                      review['content']?.toString() ?? 'No content',
                      (review['rating'] as int?) ?? 0,
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
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showAddBookDialog(collectionName),
                ),
                if (collectionName == 'want_to_read')
                  IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      // Implement search functionality
                    },
                  ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No books in this list yet'),
              );
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final book = Book.fromFirestore({
                  ...data,
                  'id': doc.id,
                });
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.authors.isNotEmpty)
              Text(
                book.authors.join(', '),
                style: TextStyle(fontSize: 12),
              ),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 16),
                Text(' ${book.rating.toStringAsFixed(1)}'),
              ],
            ),
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
                    await _firestore.collection('reviews').doc(reviewId).delete();
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