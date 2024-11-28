import 'package:carrier_nest_flutter/components/assignment_card.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssignedLoadsView extends StatefulWidget {
  const AssignedLoadsView({super.key});

  @override
  _AssignedLoadsViewState createState() => _AssignedLoadsViewState();
}

class _AssignedLoadsViewState extends State<AssignedLoadsView> with WidgetsBindingObserver {
  Future<Map<String, dynamic>>? _assignmentsFuture;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAssignments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAssignments();
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() {
      _assignmentsFuture = _getDriverAssignments();
    });
  }

  /// Helper function to fetch assignments and handle errors
  Future<Map<String, dynamic>> _getDriverAssignments() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DriverLoginPage()),
        );
        return Future.error('JWT token is missing. Redirecting to login...');
      }

      String? driverId = prefs.getString('driverId');

      final assignments = await Assignments.getDriverAssignments(
        limit: 10,
        offset: 0,
        driverId: driverId,
        assignedOnly: true,
        sort: Sort(
          key: 'assignedAt',
          order: 'desc',
        ),
      );

      return assignments;
    } on DioException catch (dioError) {
      final errorMessage = dioError.message ?? "An unknown error occurred.";
      if (dioError.type == DioExceptionType.connectionTimeout ||
          dioError.type == DioExceptionType.receiveTimeout ||
          dioError.type == DioExceptionType.sendTimeout) {
        return Future.error("Connection timeout. Please try again.");
      } else if (dioError.response?.statusCode == 500) {
        return Future.error("Server error. Please try again later.");
      } else {
        return Future.error(errorMessage);
      }
    } catch (error) {
      return Future.error("An unexpected error occurred: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchAssignments,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _assignmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingView();
          } else if (snapshot.hasError) {
            _errorMessage = snapshot.error.toString();
            return _buildErrorView();
          } else if (snapshot.hasData && snapshot.data!['assignments'].isNotEmpty) {
            return _buildLoadsList(snapshot.data!['assignments']);
          } else {
            return _buildEmptyState();
          }
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error fetching loads: ${_errorMessage ?? 'Unknown error'}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'No loads assigned',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
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
                builder: (context) => AssignmentDetailsPage(assignmentId: assignment.id),
              ),
            );
          },
          child: AssignmentCard(assignment: assignment),
        );
      },
    );
  }
}
