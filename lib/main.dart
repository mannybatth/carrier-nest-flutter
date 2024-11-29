import 'package:app_links/app_links.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/globals.dart';
import 'dart:async';

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

class MyApp extends StatefulWidget {
  final Widget homePage;

  const MyApp({super.key, required this.homePage});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initUniLinks();
  }

  Future<void> _initUniLinks() async {
    final appLinks = AppLinks();
    _sub = appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri);
    });
  }

  void _handleUri(Uri uri) {
    // Example URI: https://carriernest.com/l/clzqij1vz000gguwks78yv44g?did=clzqimq7l001gguwkmtvhy7us
    if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'l') {
      String assignmentId = uri.pathSegments[1];

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AssignmentDetailsPage(assignmentId: assignmentId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrier Nest',
      navigatorKey: navigatorKey, // Use the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: widget.homePage,
    );
  }
}
