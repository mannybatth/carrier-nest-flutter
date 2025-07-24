import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';

class CompactAssignmentCard extends StatelessWidget {
  final DriverAssignment assignment;

  const CompactAssignmentCard({Key? key, required this.assignment}) : super(key: key);

  // Get platform-specific font family
  String get _fontFamily {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'SF Pro Display';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return 'Roboto';
    }
    return 'system-ui';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    ExpandedLoad load = assignment.load!;
    RouteLeg routeLeg = assignment.routeLeg!;
    final locations = routeLeg.locations;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _buildIOSCard(context, load, routeLeg, locations, isCompact);
    } else {
      return _buildMaterialCard(context, load, routeLeg, locations, isCompact);
    }
  }

  Widget _buildIOSCard(BuildContext context, ExpandedLoad load, RouteLeg routeLeg, List<RouteLegLocation> locations, bool isCompact) {
    final backgroundColor = AppThemes.getNeumorphicBackgroundColor(context);
    final shadows = AppThemes.getNeumorphicShadows(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Theme-aware neumorphic background
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        // Theme-aware neumorphic shadows
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'ORDER #${load.refNum}',
                  style: TextStyle(
                    fontSize: isCompact ? 17 : 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
              ),
              _buildIOSStatusBadge(routeLeg.status, isCompact),
            ],
          ),

          SizedBox(height: 4),

          // Route flow
          _buildIOSRouteFlow(context, locations, isCompact),

          SizedBox(height: 4),

          // Scheduled date and time
          _buildIOSDateTimeRow(routeLeg, isCompact),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(BuildContext context, ExpandedLoad load, RouteLeg routeLeg, List<RouteLegLocation> locations, bool isCompact) {
    final backgroundColor = AppThemes.getNeumorphicBackgroundColor(context);
    final shadows = AppThemes.getNeumorphicShadows(context);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Theme-aware neumorphic background
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        // Theme-aware neumorphic shadows
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with order number and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'ORDER #${load.refNum}',
                  style: TextStyle(
                    fontSize: isCompact ? 17 : 19,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
              ),
              _buildMaterialStatusBadge(routeLeg.status, isCompact),
            ],
          ),

          SizedBox(height: 4),

          // Route flow
          _buildMaterialRouteFlow(context, locations, isCompact),

          SizedBox(height: 4),

          // Scheduled date and time
          _buildMaterialDateTimeRow(routeLeg, isCompact),
        ],
      ),
    );
  }

  Widget _buildIOSStatusBadge(RouteLegStatus status, bool isCompact) {
    Color statusColor;
    String statusText;

    switch (status) {
      case RouteLegStatus.ASSIGNED:
        statusColor = CupertinoColors.systemBlue;
        statusText = 'ASSIGNED';
        break;
      case RouteLegStatus.IN_PROGRESS:
        statusColor = CupertinoColors.systemGreen;
        statusText = 'IN PROGRESS';
        break;
      case RouteLegStatus.COMPLETED:
        statusColor = CupertinoColors.systemGreen;
        statusText = 'COMPLETED';
        break;
    }

    return Builder(
      builder: (context) {
        final badgeColors = AppThemes.getNeumorphicBadgeColors(context);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            // Theme-aware neumorphic badge background with gradient for inset effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: badgeColors,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            // Theme-aware subtle outer shadows for neumorphic definition
            boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialStatusBadge(RouteLegStatus status, bool isCompact) {
    Color statusColor;
    String statusText;

    switch (status) {
      case RouteLegStatus.ASSIGNED:
        statusColor = const Color(0xFF1976D2);
        statusText = 'ASSIGNED';
        break;
      case RouteLegStatus.IN_PROGRESS:
        statusColor = const Color(0xFF388E3C);
        statusText = 'IN PROGRESS';
        break;
      case RouteLegStatus.COMPLETED:
        statusColor = const Color(0xFF388E3C);
        statusText = 'COMPLETED';
        break;
    }

    return Builder(
      builder: (context) {
        final badgeColors = AppThemes.getNeumorphicBadgeColors(context);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            // Theme-aware neumorphic badge background with gradient for inset effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: badgeColors,
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
            // Theme-aware subtle outer shadows for neumorphic definition
            boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        );
      },
    );
  }

  Widget _buildIOSRouteFlow(BuildContext context, List<RouteLegLocation> locations, bool isCompact) {
    if (locations.length < 2) return SizedBox.shrink();

    final pickup = locations.first;
    final delivery = locations.last;
    final intermediateStops = locations.length > 2 ? locations.sublist(1, locations.length - 1) : <RouteLegLocation>[];

    return Row(
      children: [
        // Pickup indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            // Enhanced neumorphic pickup indicator
            gradient: RadialGradient(
              colors: [
                CupertinoColors.systemGreen.withValues(alpha: 0.8),
                CupertinoColors.systemGreen,
              ],
              stops: [0.3, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              // Enhanced shadow for better neumorphic effect
              BoxShadow(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.6),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.8)
                    : const Color(0xFF404040).withValues(alpha: 0.3),
                offset: const Offset(-1, -1),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),

        SizedBox(width: 8),

        // Pickup city/state
        Expanded(
          flex: 1,
          child: Text(
            _getCityState(pickup),
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w500,
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
              letterSpacing: -0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Arrow and intermediate stops indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (intermediateStops.isNotEmpty) ...[
              Icon(
                CupertinoIcons.arrow_right,
                size: 12,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  // Theme-aware small neumorphic indicator
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppThemes.getNeumorphicBadgeColors(context).take(2).toList(),
                    stops: [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
                ),
                child: Text(
                  '${intermediateStops.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                  ),
                ),
              ),
              SizedBox(width: 4),
            ],
            Icon(
              CupertinoIcons.arrow_right,
              size: 12,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ],
        ),

        SizedBox(width: 8),

        // Delivery city/state
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getCityState(delivery),
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(width: 8),
              // Delivery indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  // Enhanced neumorphic delivery indicator
                  gradient: RadialGradient(
                    colors: [
                      CupertinoColors.systemRed.withValues(alpha: 0.8),
                      CupertinoColors.systemRed,
                    ],
                    stops: [0.3, 1.0],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Enhanced shadow for better neumorphic effect
                    BoxShadow(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.6),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFFFFFFF).withValues(alpha: 0.8)
                          : const Color(0xFF404040).withValues(alpha: 0.3),
                      offset: const Offset(-1, -1),
                      blurRadius: 2,
                      spreadRadius: 0,
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

  Widget _buildMaterialRouteFlow(BuildContext context, List<RouteLegLocation> locations, bool isCompact) {
    if (locations.length < 2) return SizedBox.shrink();

    final pickup = locations.first;
    final delivery = locations.last;
    final intermediateStops = locations.length > 2 ? locations.sublist(1, locations.length - 1) : <RouteLegLocation>[];

    return Row(
      children: [
        // Pickup indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            // Enhanced neumorphic pickup indicator for Material
            gradient: RadialGradient(
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: 0.8),
                const Color(0xFF4CAF50),
              ],
              stops: [0.3, 1.0],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              // Enhanced shadow for better neumorphic effect
              BoxShadow(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                offset: const Offset(2, 2),
                blurRadius: 4,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                    : const Color(0xFF404040).withValues(alpha: 0.3),
                offset: const Offset(-1, -1),
                blurRadius: 2,
                spreadRadius: 0,
              ),
            ],
          ),
        ),

        SizedBox(width: 8),

        // Pickup city/state
        Expanded(
          flex: 1,
          child: Text(
            _getCityState(pickup),
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w500,
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
              letterSpacing: -0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Arrow and intermediate stops indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (intermediateStops.isNotEmpty) ...[
              Icon(
                Icons.arrow_forward,
                size: 12,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  // Theme-aware small neumorphic indicator for Material
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppThemes.getNeumorphicBadgeColors(context).take(2).toList(),
                    stops: [0.0, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
                ),
                child: Text(
                  '${intermediateStops.length}',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                  ),
                ),
              ),
              SizedBox(width: 4),
            ],
            Icon(
              Icons.arrow_forward,
              size: 12,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ],
        ),

        SizedBox(width: 8),

        // Delivery city/state
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _getCityState(delivery),
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily,
                    color: AppThemes.getPrimaryTextColor(context),
                    letterSpacing: -0.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(width: 8),
              // Delivery indicator
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  // Enhanced neumorphic delivery indicator for Material
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF44336).withValues(alpha: 0.8),
                      const Color(0xFFF44336),
                    ],
                    stops: [0.3, 1.0],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Enhanced shadow for better neumorphic effect
                    BoxShadow(
                      color: const Color(0xFFF44336).withValues(alpha: 0.6),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFFFFFFF).withValues(alpha: 0.7)
                          : const Color(0xFF404040).withValues(alpha: 0.3),
                      offset: const Offset(-1, -1),
                      blurRadius: 2,
                      spreadRadius: 0,
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

  Widget _buildIOSDateTimeRow(RouteLeg routeLeg, bool isCompact) {
    return Builder(
      builder: (context) {
        final badgeColors = AppThemes.getNeumorphicBadgeColors(context);
        final badgeShadows = AppThemes.getNeumorphicBadgeShadows(context);
        final secondaryTextColor = AppThemes.getSecondaryTextColor(context);

        return Row(
          children: [
            // Date badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Theme-aware neumorphic date badge background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeColors,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: badgeShadows
                    .map((shadow) => BoxShadow(
                          color: shadow.color,
                          offset: shadow.offset * 3, // Scale up for larger badge
                          blurRadius: shadow.blurRadius * 2,
                          spreadRadius: shadow.spreadRadius,
                        ))
                    .toList(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 12,
                    color: secondaryTextColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(routeLeg.scheduledDate),
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: secondaryTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Time badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Theme-aware neumorphic time badge background
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeColors,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: badgeShadows
                    .map((shadow) => BoxShadow(
                          color: shadow.color,
                          offset: shadow.offset * 3, // Scale up for larger badge
                          blurRadius: shadow.blurRadius * 2,
                          spreadRadius: shadow.spreadRadius,
                        ))
                    .toList(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.time,
                    size: 12,
                    color: secondaryTextColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(routeLeg.scheduledTime),
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: secondaryTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialDateTimeRow(RouteLeg routeLeg, bool isCompact) {
    return Builder(
      builder: (context) {
        final badgeColors = AppThemes.getNeumorphicBadgeColors(context);
        final badgeShadows = AppThemes.getNeumorphicBadgeShadows(context);
        final secondaryTextColor = AppThemes.getSecondaryTextColor(context);

        return Row(
          children: [
            // Date badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Theme-aware neumorphic date badge background for Material
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeColors,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: badgeShadows
                    .map((shadow) => BoxShadow(
                          color: shadow.color,
                          offset: shadow.offset * 3, // Scale up for larger badge
                          blurRadius: shadow.blurRadius * 2,
                          spreadRadius: shadow.spreadRadius,
                        ))
                    .toList(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: secondaryTextColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatDate(routeLeg.scheduledDate),
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: secondaryTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            // Time badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                // Theme-aware neumorphic time badge background for Material
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: badgeColors,
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: badgeShadows
                    .map((shadow) => BoxShadow(
                          color: shadow.color,
                          offset: shadow.offset * 3, // Scale up for larger badge
                          blurRadius: shadow.blurRadius * 2,
                          spreadRadius: shadow.spreadRadius,
                        ))
                    .toList(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 12,
                    color: secondaryTextColor,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(routeLeg.scheduledTime),
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: secondaryTextColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCityState(RouteLegLocation location) {
    String city = '';
    String state = '';

    if (location.loadStop != null) {
      city = location.loadStop!.city;
      state = location.loadStop!.state;
    } else if (location.location != null) {
      city = location.location!.city;
      state = location.location!.state;
    }

    if (city.isNotEmpty && state.isNotEmpty) {
      return '${city.toUpperCase()}, ${state.toUpperCase()}';
    } else if (city.isNotEmpty) {
      return city.toUpperCase();
    } else if (state.isNotEmpty) {
      return state.toUpperCase();
    }

    return 'UNKNOWN';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final yesterday = today.subtract(Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as MMM dd (e.g., "Jul 19")
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _formatTime(String timeString) {
    try {
      // Parse the time string (assuming it's in HH:mm format)
      final timeParts = timeString.split(':');
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final time = TimeOfDay(hour: hour, minute: minute);

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          // iOS typically uses 12-hour format
          final period = time.hour >= 12 ? 'PM' : 'AM';
          final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
          final displayMinute = time.minute.toString().padLeft(2, '0');
          return '$displayHour:$displayMinute $period';
        } else {
          // Android can use either, but let's use 12-hour for consistency
          final period = time.hour >= 12 ? 'PM' : 'AM';
          final displayHour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
          final displayMinute = time.minute.toString().padLeft(2, '0');
          return '$displayHour:$displayMinute $period';
        }
      }
    } catch (e) {
      // If parsing fails, return the original string
    }

    return timeString;
  }
}
