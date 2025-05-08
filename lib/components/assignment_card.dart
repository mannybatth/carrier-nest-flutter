import 'package:carrier_nest_flutter/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';

class AssignmentCard extends StatelessWidget {
  final DriverAssignment assignment;

  const AssignmentCard({Key? key, required this.assignment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ExpandedLoad load = assignment.load!;
    RouteLeg routeLeg = assignment.routeLeg!;
    // check load status
    bool completed = routeLeg.status == RouteLegStatus.COMPLETED;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      padding: const EdgeInsets.all(0.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: completed ? Colors.grey.shade200 : Colors.white,
          width: 2.0,
        ),
        boxShadow: completed
            ? null
            : const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 4),
                  blurRadius: 8.0,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildHeader(load.refNum, load.customer.name),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 4), child: _buildRouteInfo(routeLeg)),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: _buildScheduleInfo(routeLeg)),
          completed
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: const Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ]),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildHeader(String refNum, String customerName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 0),
          child: Text(
            'ORDER# $refNum',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              const HeroIcon(HeroIcons.truck, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                assignment.routeLeg?.distanceMiles != null ? '${assignment.routeLeg!.distanceMiles.toStringAsFixed(2)} miles' : '0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.timelapse_outlined, color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                //_routeLeg?.durationHours != null ? hoursToReadable(_routeLeg!.durationHours) : '0'
                assignment.routeLeg?.durationHours != null ? '${hoursToReadable(assignment.routeLeg?.durationHours ?? 0)} ' : '0',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  // check to see if routeleg loctions has more than 2 locations
  // if so, build array of _buildLocationText and return it as array of widgets
  // else, build _buildLocationText with the first and last location

  Widget _buildStops(RouteLeg routeLeg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < routeLeg.locations.length; i++)
          _buildLocationTextInColumn(
            title: i == 0
                ? 'From'
                : i == routeLeg.locations.length - 1
                    ? 'To'
                    : 'Stop',
            location: _getLocationName(routeLeg.locations[i]).toLowerCase(),
            city: _getLocationCity(routeLeg.locations[i]).toLowerCase(),
            state: _getLocationState(routeLeg.locations[i]).toLowerCase(),
            index: i,
            length: routeLeg.locations.length,
          ),
      ],
    );
  }

  Widget _buildRouteInfo(RouteLeg routeLeg) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildStops(routeLeg)],
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

  // Eumm to hold stop type "From", "To", "Stop"
  Widget _getIconBasedOnLocationType(int index, int length) {
    if (index == 0) {
      return Icon(Icons.location_on, color: Colors.blueAccent.shade200, size: 20);
    } else if (index == length - 1) {
      return Icon(Icons.location_on, color: Colors.red.shade400, size: 20);
    } else {
      return Icon(Icons.circle, color: Colors.grey.shade400, size: 20);
    }
  }

  Widget _buildLocationTextInColumn(
      {required String title,
      required String location,
      required String city,
      required String state,
      required int index,
      required int length}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getIconBasedOnLocationType(index, length),
        const SizedBox(width: 2),
        SizedBox(
          width: 60,
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Colors.grey,
                  width: 3.0,
                ),
              ),
              color: Color.fromARGB(255, 245, 245, 245),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  location.toUpperCase(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 0),
                // Capitalize first letter of city and uppercase state
                Text(
                  '${city[0].toUpperCase()}${city.substring(1)}, ${state.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 76, 76, 76),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        )
      ],
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
              'Scheduled At',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatDate(routeLeg.scheduledDate!)} at ${DateFormat("hh:mm a").format(DateFormat("HH:mm").parse(routeLeg.scheduledTime))}',
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
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
