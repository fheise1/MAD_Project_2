import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  late Future<DocumentSnapshot> _userData;
  late Future<QuerySnapshot> _wantToReadBooks;
  late Future<QuerySnapshot> _currentlyReadingBooks;
  late Future<QuerySnapshot> _finishedBooks;
  late Future<QuerySnapshot> _userReviews;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _loadData();
  }

  void _loadData() {
    _userData = _firestore.collection('users').doc(_user.uid).get();
    _wantToReadBooks = _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('want_to_read')
        .get();
    _currentlyReadingBooks = _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('currently_reading')
        .get();
    _finishedBooks = _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('finished')
        .get();
    _userReviews = _firestore
        .collection('reviews')
        .where('userId', isEqualTo: _user.uid)
        .get();
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
            // User Info Section
            FutureBuilder<DocumentSnapshot>(
              future: _userData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Text('No user data found');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
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
                        Text('Member since ${userData['joinDate'] ?? 'unknown'}'),
                      ],
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),

            // Reading Lists
            _buildReadingListSection('Want to Read', _wantToReadBooks),
            _buildReadingListSection('Currently Reading', _currentlyReadingBooks),
            _buildReadingListSection('Finished', _finishedBooks),

            // Your Reviews Section
            Text(
              'Your Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            FutureBuilder<QuerySnapshot>(
              future: _userReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No reviews yet');
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var review = doc.data() as Map<String, dynamic>;
                    return _buildReviewItem(
                      review['bookTitle'],
                      review['content'],
                      review['rating'],
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

  Widget _buildReadingListSection(String title, Future<QuerySnapshot> futureBooks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        FutureBuilder<QuerySnapshot>(
          future: futureBooks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No books in this list yet');
            }
            return Column(
              children: snapshot.data!.docs.map((doc) {
                var book = Book.fromJson(doc.data() as Map<String, dynamic>);
                return _buildBookListItem(book);
              }).toList(),
            );
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBookListItem(Book book) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: book.thumbnail.isNotEmpty
            ? Image.network(
                book.thumbnail,
                width: 50,
                height: 70,
                fit: BoxFit.cover,
              )
            : Container(
                width: 50,
                height: 70,
                color: Colors.grey,
                child: Icon(Icons.book),
              ),
        title: Text(book.title),
        subtitle: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            Text(' ${book.rating}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(book: book),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(String bookTitle, String review, int rating) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
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