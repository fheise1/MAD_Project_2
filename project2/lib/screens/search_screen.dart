import 'package:flutter/material.dart';
import '../services/book_service.dart';
import '../models/book.dart';
import 'book_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Book> _books = [];
  bool _loading = false;

  void _search() async {
    if (_controller.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final books = await BookService.fetchBooks(_controller.text);
      setState(() {
        _books = books;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching books')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter book title...',
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                IconButton(icon: Icon(Icons.search), onPressed: _search),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _books.length,
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: book.thumbnail,
                            placeholder:
                                (context, url) => CircularProgressIndicator(),
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(book.title),
                          subtitle: Text(book.authors.join(', ')),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookDetailScreen(book: book),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
