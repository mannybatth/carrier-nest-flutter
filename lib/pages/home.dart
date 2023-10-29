import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/pages/loads_view.dart';
import 'package:carrier_nest_flutter/pages/settings_view.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  // Widget for Loads view
  final Widget _loadsView = LoadsView();

  // Widget for Settings view
  final Widget _settingsView = SettingsView();

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrier Nest'),
      ),
      body: _currentIndex == 0 ? _loadsView : _settingsView,
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: [
          BottomNavigationBarItem(
            icon: new Icon(Icons.local_shipping),
            label: 'Loads',
          ),
          BottomNavigationBarItem(
            icon: new Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
