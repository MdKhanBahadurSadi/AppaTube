import 'package:flutter/material.dart';
import 'routes.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/player_screen.dart';
import '../presentation/screens/history_screen.dart';

class AppaTubeApp extends StatelessWidget {
  const AppaTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppaTube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF0000),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF0000),
          secondary: Color(0xFFFF0000),
          surface: Color(0xFF0F0F0F),
        ),
      ),
      initialRoute: Routes.home,
      routes: {
        Routes.home: (context) => const HomeScreen(),
        Routes.search: (context) => const SearchScreen(),
        Routes.player: (context) => const PlayerScreen(),
        Routes.history: (context) => const HistoryScreen(),
      },
    );
  }
}
