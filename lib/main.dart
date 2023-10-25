import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/constants.dart';
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
      home: const MyHomePage(title: 'Carrier Nest'),
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
    _loadsFuture = Loads.getLoadsExpanded(
      expand: 'customer,shipper,receiver',
      sort: Sort(key: 'refNum', order: 'desc'),
      limit: 10,
      offset: 0,
      driverId: 'clkrhqiuk0000guvk5iku093f',
    );
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
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(load.customer.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8.0),
                        Text('Load/Order #: ${load.refNum}',
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                                '${load.shipper.city}, ${load.shipper.state} to ${load.receiver.city}, ${load.receiver.state}'),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                            'Pickup Date: ${load.shipper.date.toString()}'), // Assuming there's a pickupDate attribute
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
