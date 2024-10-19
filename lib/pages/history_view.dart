import 'package:carrier_nest_flutter/components/assignment_card.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
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
        completedOnly: true,
        sort: Sort(
          key: 'assignedAt',
          order: 'desc',
        ),
      );

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
              'No loads completed in the last 30 days',
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
          child: AssignmentCard(assignment: assignment),
        );
      },
    );
  }
}
