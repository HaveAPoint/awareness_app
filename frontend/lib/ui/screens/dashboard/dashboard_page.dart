import 'package:flutter/material.dart';
import '../journal/journal_page.dart';
import '../focus/focus_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const FocusPage(),
    const JournalPage(),
    const Center(child: Text("Goals (Coming Soon)")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer),
            label: '专注',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_edu),
            label: '日记',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag),
            label: '目标',
          ),
        ],
      ),
    );
  }
}
