import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/rest/loads.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/pages/load_details.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoadsView extends StatefulWidget {
  const LoadsView({super.key});

  @override
  _LoadsViewState createState() => _LoadsViewState();
}

class _LoadsViewState extends State<LoadsView> {
  Future<Map<String, dynamic>>? _loadsFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLoads();
  }

  Future<void> _fetchLoads() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverLoginPage()),
        );
        return;
      }
      String? driverId = prefs.getString('driverId');

      _loadsFuture = Loads.getLoadsExpanded(
        expand: 'customer,shipper,receiver',
        sort: Sort(key: 'refNum', order: 'desc'),
        limit: 10,
        offset: 0,
        driverId: driverId,
        upcomingOnly: true,
      ).onError((error, stackTrace) {
        setState(() {
          _errorMessage = "$error";
        });
        return {'loads': [], 'metadata': {}};
      }).catchError((error) {
        setState(() {
          _errorMessage = "$error";
        });
        return {'loads': [], 'metadata': {}};
      });

      setState(() {});
    } catch (error) {
      // Handle errors here
      setState(() {
        _errorMessage = "$error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || _errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                  'Error fetching loads: ${_errorMessage ?? snapshot.error}'),
            ),
          );
        } else if (snapshot.hasData && snapshot.data!['loads'].isNotEmpty) {
          return _buildLoadsList(snapshot.data!['loads']);
        } else {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No loads found',
            ),
          ));
        }
      },
    );
  }

  Widget _buildLoadsList(List<ExpandedLoad> loads) {
    return ListView.builder(
      itemCount: loads.length,
      itemBuilder: (context, index) {
        ExpandedLoad load = loads[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoadDetailsPage(loadId: load.id),
              ),
            );
          },
          child: _buildLoadCard(load),
        );
      },
    );
  }

  Widget _buildLoadCard(ExpandedLoad load) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildLoadHeader(load.refNum),
            const SizedBox(height: 10),
            _buildCustomerName(load.customer.name),
            Divider(thickness: 1, color: Colors.grey[400]),
            const SizedBox(height: 10),
            _buildRowItem(
              icon: Icons.location_on,
              title: '${load.shipper.city}, ${load.shipper.state}',
              subtitle: '${load.receiver.city}, ${load.receiver.state}',
            ),
            const SizedBox(height: 10),
            _buildRowItem(
              icon: Icons.event,
              title: 'Pickup Date',
              subtitle: load.shipper.date.toString(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadHeader(String refNum) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          refNum,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildCustomerName(String name) {
    return Text(
      name,
      style: TextStyle(color: Colors.grey[600], fontSize: 16),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
