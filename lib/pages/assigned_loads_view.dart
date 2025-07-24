import 'package:carrier_nest_flutter/components/compact_assignment_card.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AssignedLoadsView extends StatefulWidget {
  const AssignedLoadsView({super.key});

  @override
  _AssignedLoadsViewState createState() => _AssignedLoadsViewState();
}

class _AssignedLoadsViewState extends State<AssignedLoadsView> with WidgetsBindingObserver {
  Future<Map<String, dynamic>>? _assignmentsFuture;
  String? _errorMessage;

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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _fetchAssignments,
          ),
          SliverFillRemaining(
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
          ),
        ],
      );
    } else {
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
  }

  Widget _buildLoadingView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppThemes.getSecondaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: ListView(
        physics: defaultTargetPlatform == TargetPlatform.iOS
            ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
            : const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (defaultTargetPlatform == TargetPlatform.iOS)
                    CupertinoActivityIndicator(
                      radius: 16,
                      color: AppThemes.getSecondaryTextColor(context),
                    )
                  else
                    CircularProgressIndicator(
                      color: AppThemes.getSecondaryTextColor(context),
                      strokeWidth: 2.5,
                    ),
                  SizedBox(height: isCompact ? 12 : 16),
                  Text(
                    'Loading assignments...',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: AppThemes.getSecondaryTextColor(context),
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return DefaultTextStyle(
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppThemes.getSecondaryTextColor(context),
          decoration: TextDecoration.none,
        ),
        child: ListView(
          physics: defaultTargetPlatform == TargetPlatform.iOS
              ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
              : const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              margin: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: isCompact ? 20 : 32,
              ),
              padding: EdgeInsets.all(isCompact ? 20 : 24),
              decoration: BoxDecoration(
                // Theme-aware neumorphic background
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                // Theme-aware neumorphic shadows
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline,
                    size: isCompact ? 48 : 56,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                  SizedBox(height: isCompact ? 16 : 20),
                  Text(
                    'Unable to Load Assignments',
                    style: TextStyle(
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: defaultTargetPlatform == TargetPlatform.iOS ? FontWeight.w700 : FontWeight.w600,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.3 : 0.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 8 : 12),
                  Text(
                    _errorMessage ?? 'Unknown error occurred',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: AppThemes.getSecondaryTextColor(context),
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 20 : 24),
                  if (defaultTargetPlatform == TargetPlatform.iOS)
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemes.getNeumorphicBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
                      ),
                      child: CupertinoButton(
                        onPressed: _fetchAssignments,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 24,
                          vertical: isCompact ? 8 : 10,
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemes.getNeumorphicBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppThemes.getNeumorphicBadgeShadows(context),
                      ),
                      child: CupertinoButton(
                        onPressed: _fetchAssignments,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 20 : 24,
                          vertical: isCompact ? 12 : 14,
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: const Color(0xFF2563EB),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        )); // Close DefaultTextStyle and method
  } // Close _buildErrorView

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return DefaultTextStyle(
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppThemes.getSecondaryTextColor(context),
          decoration: TextDecoration.none,
        ),
        child: ListView(
          physics: defaultTargetPlatform == TargetPlatform.iOS
              ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
              : const AlwaysScrollableScrollPhysics(),
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              margin: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 24,
                vertical: isCompact ? 20 : 32,
              ),
              padding: EdgeInsets.all(isCompact ? 20 : 24),
              decoration: BoxDecoration(
                // Theme-aware neumorphic background
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                // Theme-aware neumorphic shadows
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.tray : Icons.inbox_outlined,
                    size: isCompact ? 56 : 64,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                  SizedBox(height: isCompact ? 20 : 24),
                  Text(
                    'No Assignments Available',
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 24,
                      fontWeight: defaultTargetPlatform == TargetPlatform.iOS ? FontWeight.w800 : FontWeight.w700,
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.5 : -0.3,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 12 : 16),
                  Text(
                    defaultTargetPlatform == TargetPlatform.iOS
                        ? 'Pull down to refresh and check for new loads'
                        : 'Pull down to refresh and check for new loads',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: AppThemes.getSecondaryTextColor(context),
                      letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isCompact ? 24 : 32),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 20,
                      vertical: isCompact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppThemes.getSecondaryTextColor(context).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppThemes.getSecondaryTextColor(context).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.refresh : Icons.refresh,
                          size: isCompact ? 16 : 18,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Pull to refresh',
                          style: TextStyle(
                            fontSize: isCompact ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: _fontFamily,
                            color: AppThemes.getSecondaryTextColor(context),
                            letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? 0.1 : 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )); // Close DefaultTextStyle and ListView
  } // Close _buildEmptyState

  Widget _buildLoadsList(List<DriverAssignment> assignments) {
    // Sort assignments by scheduled date and time (oldest first - July 19 before July 20)
    assignments.sort((a, b) {
      final aRouteLeg = a.routeLeg;
      final bRouteLeg = b.routeLeg;

      if (aRouteLeg == null && bRouteLeg == null) return 0;
      if (aRouteLeg == null) return 1;
      if (bRouteLeg == null) return -1;

      final aScheduledDate = aRouteLeg.scheduledDate;
      final bScheduledDate = bRouteLeg.scheduledDate;

      if (aScheduledDate == null && bScheduledDate == null) return 0;
      if (aScheduledDate == null) return 1;
      if (bScheduledDate == null) return -1;

      // First compare by date (ascending order - older dates first)
      int dateComparison = aScheduledDate.compareTo(bScheduledDate);
      if (dateComparison != 0) return dateComparison;

      // If dates are the same, compare by time (ascending order)
      final aTime = aRouteLeg.scheduledTime;
      final bTime = bRouteLeg.scheduledTime;
      return aTime.compareTo(bTime);
    });

    // Group assignments by date
    Map<String, List<DriverAssignment>> groupedAssignments = {};
    for (var assignment in assignments) {
      final routeLeg = assignment.routeLeg;
      if (routeLeg?.scheduledDate != null) {
        final dateKey = _formatDateHeader(routeLeg!.scheduledDate!);
        if (!groupedAssignments.containsKey(dateKey)) {
          groupedAssignments[dateKey] = [];
        }
        groupedAssignments[dateKey]!.add(assignment);
      }
    }

    // Create a flat list with date headers and assignments
    List<Widget> widgets = [];
    groupedAssignments.forEach((dateHeader, assignmentsForDate) {
      // Add date header
      widgets.add(_buildDateHeader(dateHeader));

      // Add assignments for this date
      for (var assignment in assignmentsForDate) {
        widgets.add(
          GestureDetector(
            onTap: () {
              if (defaultTargetPlatform == TargetPlatform.iOS) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => AssignmentDetailsPage(assignmentId: assignment.id),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssignmentDetailsPage(assignmentId: assignment.id),
                  ),
                );
              }
            },
            child: CompactAssignmentCard(assignment: assignment),
          ),
        );
      }
    });

    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppThemes.getPrimaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: ListView(
        physics: defaultTargetPlatform == TargetPlatform.iOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          vertical: 12, // Apple 12pt base unit for top/bottom spacing
        ),
        children: widgets,
      ),
    );
  }

  Widget _buildDateHeader(String dateText) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    // Determine accent color based on date text (keep iOS blue/green for visual hierarchy)
    Color accentColor;
    if (dateText == 'Today') {
      accentColor = const Color(0xFF007AFF); // iOS blue for today
    } else if (dateText == 'Tomorrow') {
      accentColor = const Color(0xFF34C759); // iOS green for tomorrow
    } else {
      accentColor = AppThemes.getSecondaryTextColor(context); // Theme-aware gray for other dates
    }

    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          // Subtle colored line
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          // Calendar icon with subtle styling
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.calendar : Icons.calendar_today,
              size: 14,
              color: accentColor,
            ),
          ),
          SizedBox(width: 8),
          // Date text with accent color
          Text(
            dateText,
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: accentColor,
              letterSpacing: -0.1,
            ),
          ),
          // Subtle divider line
          Expanded(
            child: Container(
              margin: EdgeInsets.only(left: 12),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accentColor.withValues(alpha: 0.3),
                    accentColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      // Format as "Mon, Jul 23" for other dates
      return DateFormat('EEE, MMM d').format(date);
    }
  }
}
