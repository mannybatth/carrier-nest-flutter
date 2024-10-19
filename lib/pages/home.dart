import 'package:carrier_nest_flutter/pages/history_view.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/pages/assigned_loads_view.dart';
import 'package:carrier_nest_flutter/pages/settings_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _getCurrentView() {
    switch (_currentIndex) {
      case 0:
        return const AssignedLoadsView();
      case 1:
        return const HistoryView();
      case 2:
        return const SettingsView();
      default:
        return const AssignedLoadsView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0
            ? 'Assigned Loads'
            : _currentIndex == 1
                ? 'History'
                : 'Settings'),
      ),
      body: _getCurrentView(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Assigned',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
