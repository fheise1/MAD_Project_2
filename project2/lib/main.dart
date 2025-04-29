import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:project2/models/book.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/user_profile_screen.dart';
import 'screens/discussion_board_screen.dart';
import 'screens/book_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Books App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/search': (context) => SearchScreen(),
        '/profile': (context) => UserProfileScreen(),
        '/discussion': (context) => DiscussionBoardScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/book') {
          final Book book = settings.arguments as Book;
          return MaterialPageRoute(
            builder: (context) => BookDetailScreen(book: book),
          );
        }
        return null;
      },
    );
  }
}