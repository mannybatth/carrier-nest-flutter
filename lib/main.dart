import 'package:app_links/app_links.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Add for debug properties
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/globals.dart';
import 'package:carrier_nest_flutter/services/theme_service.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable all debug visualizations
  debugPaintSizeEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;

  // Initialize theme service
  await themeService.init();

  // Initialize DioClient to prevent late initialization errors
  await DioClient().initDio();

  // Check if user is already logged in
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jwtToken = prefs.getString('jwtToken');

  Widget homePage = jwtToken != null ? const MyHomePage() : const DriverLoginPage();

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
    return DefaultTextStyle(
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
        decoration: TextDecoration.none,
        fontFamily: 'system-ui',
      ),
      child: AnimatedBuilder(
        animation: themeService,
        builder: (context, child) {
          return MaterialApp(
            title: 'Carrier Nest',
            navigatorKey: navigatorKey, // Use the global navigator key
            debugShowCheckedModeBanner: false, // Disable debug banner and debug indicators

            // Theme configuration
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeService.materialThemeMode,

            home: widget.homePage,
          );
        },
      ),
    );
  }
}
