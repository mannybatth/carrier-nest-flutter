import 'package:carrier_nest_flutter/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Initialize Flutter bindings
  await DioClient().initDio(); // Initialize DioClient
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrier Nest',
      navigatorKey: navigatorKey, // Use the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
