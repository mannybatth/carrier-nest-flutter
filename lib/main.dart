import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Map<String, dynamic>> _loadsFuture;

  @override
  void initState() {
    super.initState();
    _loadsFuture = Loads.getLoadsExpanded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<ExpandedLoad> loads = snapshot.data!['loads'];
            return ListView.builder(
              itemCount: loads.length,
              itemBuilder: (context, index) {
                ExpandedLoad load = loads[index];
                return ListTile(
                  title: Text(load.refNum),
                  subtitle: Text(load.status.toString()),
                );
              },
            );
          }
        },
      ),
    );
  }
}
