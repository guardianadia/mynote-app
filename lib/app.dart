import 'package:flutter/material.dart';
import 'auth/splash_screen.dart';

class MyNoteApp extends StatelessWidget {
  const MyNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF2EAFE);
    const primary = Color(0xFF5B2C83);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyNote',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: Colors.black,
          centerTitle: false,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
