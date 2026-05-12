import 'package:flutter/material.dart';
import 'routes.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/search_screen.dart';
import '../presentation/screens/player_screen.dart';
import '../presentation/screens/history_screen.dart';
import '../presentation/screens/video_player_screen.dart';

class AppaTubeApp extends StatelessWidget {
  const AppaTubeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppaTube',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE40000),
          secondary: const Color(0xFFFF4444),
          surface: const Color(0xFF111111),
          background: const Color(0xFF0A0A0A),
          onPrimary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFE40000),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF0F0F0F),
          selectedItemColor: Color(0xFFE40000),
          unselectedItemColor: Color(0xFF555555),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161616),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: Color(0xFF555555)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Color(0xFFAAAAAA)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (context) => const SplashScreen(),
        Routes.home: (context) => const HomeScreen(),
        Routes.search: (context) => const SearchScreen(),
        Routes.player: (context) => const PlayerScreen(),
        Routes.history: (context) => const HistoryScreen(),
        Routes.videoPlayer: (context) => const VideoPlayerScreen(),
      },
    );
  }
}
