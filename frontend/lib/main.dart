import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/database/database.dart';
import 'logic/focus_session_state.dart';
import 'ui/screens/dashboard/dashboard_page.dart';

// Global database instance
late AppDatabase db;

// Global focus session state
late FocusSessionState focusSessionState;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database
  db = AppDatabase();

  // Initialize Focus Session State
  focusSessionState = FocusSessionState();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '觉知系统',
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [
        Locale('zh', 'CN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
