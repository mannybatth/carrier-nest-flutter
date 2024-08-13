import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LoadsView extends StatefulWidget {
  const LoadsView({super.key});

  @override
  _LoadsViewState createState() => _LoadsViewState();
}

class _LoadsViewState extends State<LoadsView> {
  Future<Map<String, dynamic>>? _assignmentsFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
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

      _assignmentsFuture = Assignments.getDriverAssignments(
        limit: 10,
        offset: 0,
        driverId: driverId,
        upcomingOnly: true,
      );

      setState(() {});
    } catch (error) {
      // Handle errors here
      setState(() {
        _errorMessage = "$error";
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy', 'en_US').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _assignmentsFuture,
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
        } else if (snapshot.hasData &&
            snapshot.data!['assignments'].isNotEmpty) {
          return _buildLoadsList(snapshot.data!['assignments']);
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

  Widget _buildLoadsList(List<DriverAssignment> assignments) {
    return ListView.builder(
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        DriverAssignment assignment = assignments[index];
        ExpandedLoad load = assignment.load as ExpandedLoad;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AssignmentDetailsPage(assignmentId: assignment.id),
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
            _buildLocationRowItem(
              fromCity: load.shipper.city,
              fromState: load.shipper.state,
              toCity: load.receiver.city,
              toState: load.receiver.state,
            ),
            const SizedBox(height: 10),
            _buildRowItem(
              icon: Icons.event,
              title: 'Pickup Date',
              subtitle: _formatDate(load.shipper.date),
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
      style: TextStyle(color: Colors.grey[800], fontSize: 16),
    );
  }

  Widget _buildLocationRowItem({
    required String fromCity,
    required String fromState,
    required String toCity,
    required String toState,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.location_on, color: Colors.blue[700]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'From: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: '$fromCity, $fromState',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'To: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    TextSpan(
                      text: '$toCity, $toState',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
                style: TextStyle(color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
