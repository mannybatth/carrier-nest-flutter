import 'package:carrier_nest_flutter/pages/load_details.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/globals.dart';
import 'package:uni_links/uni_links.dart';
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
    // Handle link when app is in background or killed
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (err) {
      print('Error: $err');
    });

    // Handle link when app is opened via a link
    final initialUri = await getInitialUri();
    if (initialUri != null) {
      _handleUri(initialUri);
    }
  }

  void _handleUri(Uri uri) {
    // Handle the deep link here
    print('Received URI: $uri');

    // Extract the loadId directly from the path
    // Example URI: https://carriernest.com/l/clzqij1vz000gguwks78yv44g?did=clzqimq7l001gguwkmtvhy7us
    if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'l') {
      String loadId = uri.pathSegments[1];

      // Navigate to LoadDetailsPage with the loadId
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => LoadDetailsPage(loadId: loadId),
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
