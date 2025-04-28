import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Book> _books = [];
  String _query = '';
  int _startIndex = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !_isLoading &&
          _hasMore) {
        _loadMoreBooks();
      }
    });
  }

  Future<void> _searchBooks(String query) async {
    setState(() {
      _query = query;
      _startIndex = 0;
      _books = [];
      _hasMore = true;
      _isInitialLoading = true;
    });
    await _loadMoreBooks();
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoading || !_hasMore || _query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=$_query&startIndex=$_startIndex&maxResults=20',
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
      throw Exception('Failed to load books');
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Books')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search books...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _searchBooks(_controller.text),
                ),
              ),
              onSubmitted: (value) => _searchBooks(value),
            ),
            const SizedBox(height: 16),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}
