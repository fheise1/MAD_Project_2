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
    if (query.trim().isEmpty) return;
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
    }
  }

  Widget _buildBookCard(Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    book.thumbnail.isNotEmpty
                        ? Image.network(
                          book.thumbnail,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                        : Container(
                          width: 80,
                          height: 120,
                          color: Colors.grey,
                          child: Icon(Icons.book, size: 40),
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      book.description.isNotEmpty
                          ? (book.description.length > 100
                              ? '${book.description.substring(0, 100)}...'
                              : book.description)
                          : 'No description',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 20),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              Icons.star,
                              size: 20,
                              color:
                                  index < book.rating.round()
                                      ? Colors.amber
                                      : Colors.grey,
                            ),
                          ),
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
  }

  Widget _buildShimmerCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 80, height: 120, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 20,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 14,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(
                      5,
                      (index) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Icon(Icons.star, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                        itemCount: 8,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        itemCount: _books.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _books.length) {
                            return _buildBookCard(_books[index]);
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
