class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String description;
  final String thumbnail;
  final double rating;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.thumbnail,
    required this.rating,
  });

  // For Google Books API
  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] ?? {};
    return Book(
      id: json['id'] ?? '',
      title: volumeInfo['title'] ?? 'No Title',
      authors: (volumeInfo['authors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: volumeInfo['description'] ?? '',
      thumbnail: volumeInfo['imageLinks']?['thumbnail'] ?? '',
      rating: (volumeInfo['averageRating'] ?? 0).toDouble(),
    );
  }

  // For Firestore data
  factory Book.fromFirestore(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? 'No Title',
      authors: (json['authors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}