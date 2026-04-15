import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/note_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final noteProvider = NoteProvider();
  await noteProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: noteProvider),
      ],
      child: const NoteNestApp(),
    ),
  );
}

class NoteNestApp extends StatelessWidget {
  const NoteNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C), // Teal-ish as per the UI
          primary: const Color(0xFF00695C),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardTheme: CardThemeData( // Fixed: Changed CardTheme to CardThemeData
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
