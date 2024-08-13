import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:intl/intl.dart';

class AssignmentCard extends StatelessWidget {
  final DriverAssignment assignment;

  const AssignmentCard({Key? key, required this.assignment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ExpandedLoad load = assignment.load!;
    RouteLeg routeLeg = assignment.routeLeg!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 12.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(load.refNum, load.customer.name),
          const SizedBox(height: 12),
          _buildRouteInfo(routeLeg),
          const SizedBox(height: 12),
          _buildScheduleInfo(routeLeg),
        ],
      ),
    );
  }

  Widget _buildHeader(String refNum, String customerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          refNum,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          customerName,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(RouteLeg routeLeg) {
    return Row(
      children: [
        const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLocationText(
                title: 'From',
                location: _getLocationName(routeLeg.locations.first),
                city: _getLocationCity(routeLeg.locations.first),
                state: _getLocationState(routeLeg.locations.first),
              ),
              const SizedBox(height: 4),
              _buildLocationText(
                title: 'To',
                location: _getLocationName(routeLeg.locations.last),
                city: _getLocationCity(routeLeg.locations.last),
                state: _getLocationState(routeLeg.locations.last),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationText({
    required String title,
    required String location,
    required String city,
    required String state,
  }) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: '$location, $city, $state',
            style: const TextStyle(fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo(RouteLeg routeLeg) {
    return Row(
      children: [
        const Icon(Icons.access_time, color: Colors.orange, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scheduled',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatDate(routeLeg.scheduledDate!)} at ${routeLeg.scheduledTime}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  String _getLocationName(RouteLegLocation legLocation) {
    if (legLocation.loadStop != null) {
      return legLocation.loadStop!.name;
    } else if (legLocation.location != null) {
      return legLocation.location!.name;
    }
    return '';
  }

  String _getLocationCity(RouteLegLocation legLocation) {
    if (legLocation.loadStop != null) {
      return legLocation.loadStop!.city;
    } else if (legLocation.location != null) {
      return legLocation.location!.city;
    }
    return '';
  }

  String _getLocationState(RouteLegLocation legLocation) {
    if (legLocation.loadStop != null) {
      return legLocation.loadStop!.state;
    } else if (legLocation.location != null) {
      return legLocation.location!.state;
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy', 'en_US').format(date);
  }
}
