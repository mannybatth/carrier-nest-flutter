import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/pages/load_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<Map<String, dynamic>>? _loadsFuture;

  @override
  void initState() {
    super.initState();
    _fetchLoads();
  }

  Future<void> _fetchLoads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jwtToken = prefs.getString('jwtToken');
    if (jwtToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DriverLoginPage()),
      );
      return;
    }
    String? driverId = prefs.getString('driverId');

    _loadsFuture = Loads.getLoadsExpanded(
            expand: 'customer,shipper,receiver',
            sort: Sort(key: 'refNum', order: 'desc'),
            limit: 10,
            offset: 0,
            driverId: driverId)
        .catchError((error) {
      // Handle errors here
      print("Error fetching loads: $error");
    });

    // Call setState if needed
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Loads"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!['loads'].isNotEmpty) {
            List<ExpandedLoad> loads = snapshot.data!['loads'];
            return ListView.builder(
              itemCount: loads.length,
              itemBuilder: (context, index) {
                ExpandedLoad load = loads[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoadDetailsPage(
                          loadId: load.id,
                        ),
                      ),
                    );
                  },
                  child: Card(
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
                          Text('Pickup Date: ${load.shipper.date.toString()}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No loads found'));
          }
        },
      ),
    );
  }
}
