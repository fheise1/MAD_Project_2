import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  int _startIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = true; // important

  @override
  void initState() {
    super.initState();
    _loadMoreBooks();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreBooks();
      }
    });
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=fiction&startIndex=$_startIndex&maxResults=20',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final newBooksJson = data['items'] ?? [];
      final newBooks =
          newBooksJson.map<Book>((json) => Book.fromJson(json)).toList();

      setState(() {
        _startIndex += 20;
        _books.addAll(newBooks);
        _hasMore = newBooks.isNotEmpty;
        _isLoading = false;
        _isInitialLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _isInitialLoading = false;
      });
    }
  }

  Widget _buildBookItem(Book book) {
    return ListTile(
      leading:
          book.thumbnail.isNotEmpty
              ? Image.network(book.thumbnail, width: 50, fit: BoxFit.cover)
              : const Icon(Icons.book, size: 50),
      title: Text(book.title),
      subtitle: Text(book.authors.join(', ')),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        );
      },
    );
  }

  Widget _buildShimmerItem() {
    return ListTile(
      leading: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(width: 50, height: 70, color: Colors.white),
      ),
      title: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 15,
          width: double.infinity,
          color: Colors.white,
        ),
      ),
      subtitle: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(height: 10, width: 100, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(),
      appBar: AppBar(
        title: const Text('Popular Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            _isInitialLoading
                ? ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) => _buildShimmerItem(),
                )
                : ListView.builder(
                  controller: _scrollController,
                  itemCount: _books.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _books.length) {
                      return _buildBookItem(_books[index]);
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                ),
      ),
    );
  }
}
