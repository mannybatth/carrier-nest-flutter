import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter bindings
  await DioClient().initDio(); // Initialize DioClient

  // Check for value in SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasToken = prefs.getString('jwtToken') != null;

  // Decide which page to display
  Widget homePage = hasToken ? const MyHomePage() : const DriverLoginPage();

  runApp(MyApp(homePage: homePage));
}

class MyApp extends StatelessWidget {
  final Widget homePage;

  const MyApp({super.key, required this.homePage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrier Nest',
      navigatorKey: navigatorKey, // Use the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: homePage,
    );
  }
}
