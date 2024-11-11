import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/tab_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'akamAI bot',
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color.fromRGBO(0, 130, 222, 1), // Blue
        hintColor: const Color.fromRGBO(253, 40, 97, 1), // Pink
        scaffoldBackgroundColor: const Color(0xFF121212), // Dark background
        appBarTheme: const AppBarTheme(
          color: Color.fromRGBO(253, 40, 97, 1), // Blue
          foregroundColor: Colors.white,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Color.fromRGBO(255, 170, 51, 1), // Yellow
          textTheme: ButtonTextTheme.primary,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromRGBO(0, 202, 218, 1), // Teal
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const TabNavigation(),
    );
  }
}
