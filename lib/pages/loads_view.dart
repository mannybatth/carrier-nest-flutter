import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/pages/load_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadsView extends StatefulWidget {
  @override
  _LoadsViewState createState() => _LoadsViewState();
}

class _LoadsViewState extends State<LoadsView> {
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
    return FutureBuilder<Map<String, dynamic>>(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              load.refNum,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          load.customer.name,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                        Divider(thickness: 1, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        RowItem(
                          icon: Icons.location_on,
                          title: '${load.shipper.city}, ${load.shipper.state}',
                          subtitle:
                              '${load.receiver.city}, ${load.receiver.state}',
                        ),
                        const SizedBox(height: 10),
                        RowItem(
                          icon: Icons.event,
                          title: 'Pickup Date',
                          subtitle: '${load.shipper.date.toString()}',
                        ),
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
    );
  }
}

class RowItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  RowItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: Colors.blue[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
