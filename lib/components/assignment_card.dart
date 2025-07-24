import 'package:carrier_nest_flutter/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class AssignmentCard extends StatelessWidget {
  final DriverAssignment assignment;

  const AssignmentCard({Key? key, required this.assignment}) : super(key: key);

  // Get platform-specific elegant font family
  String get _fontFamily {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'SF Pro Display';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Roboto';
    }
    return 'system-ui'; // Fallback for web/other platforms
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final isTablet = screenWidth >= 768;

    ExpandedLoad load = assignment.load!;
    RouteLeg routeLeg = assignment.routeLeg!;

    // Apple Design Guidelines spacing - 8pt base unit system
    final horizontalPadding = isTablet ? 20.0 : 16.0; // Standard Apple content margins
    final cardPadding = isTablet ? 24.0 : 16.0; // 16pt/24pt based on Apple guidelines
    final borderRadius = isTablet ? 16.0 : (isCompact ? 12.0 : 14.0);
    final verticalSpacing = isCompact ? 8.0 : 12.0; // 8pt base unit progression

    return Container(
      margin: EdgeInsets.symmetric(
          vertical: verticalSpacing / 2, // 4pt/6pt for card separation
          horizontal: horizontalPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[50], // Monochromatic light background
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.grey[300]!, // Monochromatic border
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15), // Monochromatic shadow
                  offset: const Offset(0, 4),
                  blurRadius: 20.0,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern header section with status badge
                  _buildModernHeader(load, routeLeg, isCompact, isTablet, verticalSpacing),

                  SizedBox(height: verticalSpacing), // Apple 8pt base unit

                  // Route flow section
                  _buildRouteFlow(routeLeg, isCompact, isTablet),

                  SizedBox(height: verticalSpacing), // Apple 8pt base unit

                  // Schedule section
                  _buildScheduleSection(routeLeg, isCompact, isTablet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(ExpandedLoad load, RouteLeg routeLeg, bool isCompact, bool isTablet, double verticalSpacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with order number and status badges
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER# ${load.refNum}',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : (isTablet ? 26 : 24), // Larger, more readable for drivers
                      fontWeight: FontWeight.w700, // Strong weight for primary info
                      fontFamily: _fontFamily,
                      color: Colors.black,
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.3 : 0.0,
                      height: 1.2, // Better line height for readability
                    ),
                  ),
                ],
              ),
            ),
            // Status badges column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Route leg status badge - only show this for completed assignments
                _buildRouteLegStatusBadge(routeLeg.status, isCompact),
                // Remove the DELIVERED badge - only show COMPLETED status
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRouteLegStatusBadge(RouteLegStatus status, bool isCompact) {
    Color statusColor;
    Color backgroundStartColor;
    Color backgroundEndColor;
    Color borderColor;
    Color textColor;
    String statusText;

    switch (status) {
      case RouteLegStatus.ASSIGNED:
        statusColor = const Color(0xFF3B82F6); // Subtle blue for assigned
        backgroundStartColor = statusColor.withOpacity(0.12);
        backgroundEndColor = statusColor.withOpacity(0.06);
        borderColor = statusColor.withOpacity(0.25);
        textColor = statusColor.withOpacity(0.85);
        statusText = 'ASSIGNED';
        break;
      case RouteLegStatus.IN_PROGRESS:
        statusColor = const Color(0xFF10B981); // Subtle green for in progress
        backgroundStartColor = statusColor.withOpacity(0.12);
        backgroundEndColor = statusColor.withOpacity(0.06);
        borderColor = statusColor.withOpacity(0.25);
        textColor = statusColor.withOpacity(0.85);
        statusText = 'IN PROGRESS';
        break;
      case RouteLegStatus.COMPLETED:
        statusColor = const Color(0xFF6B7280); // Subtle grey for completed
        backgroundStartColor = statusColor.withOpacity(0.15);
        backgroundEndColor = statusColor.withOpacity(0.08);
        borderColor = statusColor.withOpacity(0.3);
        textColor = statusColor.withOpacity(0.9);
        statusText = 'COMPLETED';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12, // Apple 8pt/12pt base units
        vertical: 4, // Apple 4pt base unit
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundStartColor,
            backgroundEndColor,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: isCompact ? 11 : 12, // Bigger for better readability
          fontWeight: FontWeight.w700,
          fontFamily: _fontFamily,
          color: textColor, // Color-coded text
          letterSpacing: 0.8, // More spacing for caps
        ),
      ),
    );
  }

  Widget _buildRouteFlow(RouteLeg routeLeg, bool isCompact, bool isTablet) {
    final locations = routeLeg.locations;
    final stopCount = locations.length - 2;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16), // Apple 12pt/16pt base units
      decoration: BoxDecoration(
        color: Colors.grey[100], // Monochromatic background
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        border: Border.all(
          color: Colors.grey[300]!, // Monochromatic border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route header with stats
          Row(
            children: [
              Text(
                'ROUTE',
                style: TextStyle(
                  fontSize: 11, // Consistent section header size
                  fontWeight: FontWeight.w700,
                  fontFamily: _fontFamily,
                  color: Colors.black.withOpacity(0.6), // Better contrast
                  letterSpacing: 1.2, // Good spacing for section headers
                ),
              ),
              SizedBox(width: 8),
              // Minimal distance and duration
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200]!.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${routeLeg.distanceMiles.toStringAsFixed(0)} mi • ${hoursToReadable(routeLeg.durationHours)}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Spacer(),
              if (stopCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, // Apple 8pt base unit
                      vertical: 4 // Apple 4pt base unit
                      ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200]!.withOpacity(0.5), // Monochromatic background
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey[400]!.withOpacity(0.5), // Monochromatic border
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$stopCount ${stopCount == 1 ? 'STOP' : 'STOPS'}',
                    style: TextStyle(
                      fontSize: 10, // Consistent badge size
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: Colors.grey[700]!, // Monochromatic text
                      letterSpacing: 0.6, // Good spacing for badges
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: 12), // Apple 12pt base unit

          // Route flow with visual sequencing
          _buildVisualRouteFlow(locations, stopCount, isCompact),
        ],
      ),
    );
  }

  Widget _buildVisualRouteFlow(List<RouteLegLocation> locations, int stopCount, bool isCompact) {
    return Column(
      children: [
        // Pickup location
        _buildSequentialLocationStop(
          location: locations.first,
          type: 'PICKUP',
          color: Colors.grey[700]!, // Dark monochromatic for pickup
          isCompact: isCompact,
          isFirst: true,
          isLast: false,
        ),

        // Intermediate stops (if any)
        if (stopCount > 0) ...[
          for (int i = 1; i < locations.length - 1; i++)
            _buildSequentialLocationStop(
              location: locations[i],
              type: 'STOP ${i}',
              color: Colors.grey[600]!, // Medium monochromatic for stops
              isCompact: isCompact,
              isFirst: false,
              isLast: false,
            ),
        ],

        // Delivery location
        _buildSequentialLocationStop(
          location: locations.last,
          type: 'DELIVERY',
          color: Colors.grey[800]!, // Darkest monochromatic for delivery
          isCompact: isCompact,
          isFirst: false,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildSequentialLocationStop({
    required RouteLegLocation location,
    required String type,
    required Color color,
    required bool isCompact,
    required bool isFirst,
    required bool isLast,
  }) {
    final locationName = _getLocationName(location);
    final locationCity = _getLocationCity(location);
    final locationState = _getLocationState(location);

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection line and map icon column
            Container(
              width: 32,
              child: Column(
                children: [
                  // Top connecting line (except for first stop)
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[400]!,
                            color.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),

                  // Map icon with colored background
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.place,
                      size: 16,
                      color: color,
                    ),
                  ),

                  // Bottom connecting line (except for last stop)
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.3),
                            Colors.grey[400]!,
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Location information
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type label
                    Row(
                      children: [
                        Text(
                          type,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: _fontFamily,
                            color: color,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Spacer(),
                        // Route direction indicator
                        if (!isLast)
                          Icon(
                            Icons.arrow_downward,
                            size: 12,
                            color: color.withOpacity(0.6),
                          ),
                      ],
                    ),

                    SizedBox(height: 4),

                    // Location name
                    Text(
                      locationName.toUpperCase(),
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: _fontFamily,
                        color: Colors.black.withOpacity(0.85),
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // City and state
                    if (locationCity.isNotEmpty && locationState.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '$locationCity, $locationState',
                          style: TextStyle(
                            fontSize: isCompact ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: Colors.black.withOpacity(0.7),
                            letterSpacing: -0.1,
                            height: 1.1,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Add spacing between stops (except after last stop)
        if (!isLast) SizedBox(height: 8),
      ],
    );
  }

  Widget _buildScheduleSection(RouteLeg routeLeg, bool isCompact, bool isTablet) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16), // Apple 12pt/16pt base units
      decoration: BoxDecoration(
        color: Colors.grey[200]!.withOpacity(0.5), // Light monochromatic background
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        border: Border.all(
          color: Colors.grey[400]!, // Monochromatic border
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'START TIME',
                style: TextStyle(
                  fontSize: 11, // Consistent section header size
                  fontWeight: FontWeight.w700,
                  fontFamily: _fontFamily,
                  color: Colors.grey[700]!, // Monochromatic text color
                  letterSpacing: 1.2, // Good spacing for section headers
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(routeLeg.scheduledDate!),
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18, // Larger for important date info
                  fontWeight: FontWeight.w700, // Strong but not too heavy
                  fontFamily: _fontFamily,
                  color: Colors.black,
                  letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.2 : 0.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat("h:mm a").format(DateFormat("HH:mm").parse(routeLeg.scheduledTime)),
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18, // Match date size
                  fontWeight: FontWeight.w600, // Slightly lighter than date
                  fontFamily: _fontFamily,
                  color: Colors.black.withOpacity(0.8), // Better contrast for time
                  letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
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
