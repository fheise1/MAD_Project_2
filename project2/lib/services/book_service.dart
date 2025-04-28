import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book.dart';

class BookService {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  static Future<List<Book>> fetchBooks(String query) async {
    final url = Uri.parse('$_baseUrl?q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List items = data['items'] ?? [];
      return items.map((json) => Book.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load books');
    }
  }
}
