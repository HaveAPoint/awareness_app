import 'package:flutter/material.dart';
import 'data/database/database.dart';
import 'ui/screens/dashboard/dashboard_page.dart';

// Global database instance
late AppDatabase db; //late

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Database
  db = AppDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '觉知系统',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
