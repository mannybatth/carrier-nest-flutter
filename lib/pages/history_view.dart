import 'package:carrier_nest_flutter/components/compact_assignment_card.dart';
import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/pages/assignment_details.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/rest/assignments.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  _HistoryViewState createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with WidgetsBindingObserver {
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
        completedOnly: true,
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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _fetchAssignments,
          ),
          SliverFillRemaining(
            child: _buildContent(),
          ),
        ],
      );
    } else {
      return RefreshIndicator(
        onRefresh: _fetchAssignments,
        child: _buildContent(),
      );
    }
  }

  Widget _buildContent() {
    return FutureBuilder<Map<String, dynamic>>(
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
    );
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
              'Loading history...',
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
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
              border: Border.all(
                color: AppThemes.getBorderColor(context),
                width: 1,
              ),
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
                  'Unable to Load History',
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
                    color: AppThemes.getSecondaryTextColor(context).withOpacity(0.8),
                    letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
              border: Border.all(
                color: AppThemes.getBorderColor(context),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.clock : Icons.history,
                  size: isCompact ? 56 : 64,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
                SizedBox(height: isCompact ? 20 : 24),
                Text(
                  'No History Available',
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
                  'No loads completed in the last 30 days',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: _fontFamily,
                    color: AppThemes.getSecondaryTextColor(context).withOpacity(0.8),
                    letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.1 : 0.0,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadsList(List<DriverAssignment> assignments) {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppThemes.getPrimaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: ListView.builder(
        physics: defaultTargetPlatform == TargetPlatform.iOS ? const BouncingScrollPhysics() : const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          vertical: 12, // Apple 12pt base unit for top/bottom spacing
        ),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          DriverAssignment assignment = assignments[index];

          return GestureDetector(
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
          );
        },
      ),
    );
  }
}
