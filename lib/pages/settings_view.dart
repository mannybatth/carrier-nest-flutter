import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/services/theme_service.dart';
import 'package:carrier_nest_flutter/themes/app_themes.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  @override
  void initState() {
    super.initState();
    // Listen to theme changes
    themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    // Remove theme listener
    themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when theme changes
      });
    }
  }

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

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(isCompact);
        } else if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString(), isCompact);
        } else if (snapshot.hasData) {
          return _buildSettingsList(snapshot.data!, isCompact);
        } else {
          return _buildNoDataView(isCompact);
        }
      },
    );
  }

  Widget _buildLoadingView(bool isCompact) {
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
              'Loading settings...',
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

  Widget _buildErrorView(String error, bool isCompact) {
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
            Icon(
              defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.exclamationmark_circle : Icons.error_outline,
              size: isCompact ? 48 : 56,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            Text(
              'Error loading settings',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: defaultTargetPlatform == TargetPlatform.iOS ? FontWeight.w700 : FontWeight.w600,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
                letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.3 : 0.0,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              error,
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
    );
  }

  Widget _buildNoDataView(bool isCompact) {
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
            Icon(
              defaultTargetPlatform == TargetPlatform.iOS ? CupertinoIcons.question_circle : Icons.help_outline,
              size: isCompact ? 48 : 56,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            SizedBox(height: isCompact ? 16 : 20),
            Text(
              'No settings data found',
              style: TextStyle(
                fontSize: isCompact ? 18 : 20,
                fontWeight: defaultTargetPlatform == TargetPlatform.iOS ? FontWeight.w700 : FontWeight.w600,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
                letterSpacing: defaultTargetPlatform == TargetPlatform.iOS ? -0.3 : 0.0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(SharedPreferences prefs, bool isCompact) {
    return Builder(
      builder: (context) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return _buildCupertinoSettingsList(prefs, isCompact, context);
        } else {
          return _buildMaterialSettingsList(prefs, isCompact, context);
        }
      },
    );
  }

  Widget _buildCupertinoSettingsList(SharedPreferences prefs, bool isCompact, BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppThemes.getPrimaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: CupertinoScrollbar(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 20,
            vertical: isCompact ? 16 : 20,
          ),
          children: [
            // Account Information Section
            Container(
              margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
              child: Text(
                'ACCOUNT INFORMATION',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: Column(
                children: [
                  _buildCupertinoListTile(
                    icon: CupertinoIcons.phone,
                    title: 'Phone Number',
                    subtitle: prefs.getString('phoneNumber') ?? 'Not available',
                    isCompact: isCompact,
                    isFirst: true,
                    isLast: false,
                    showTrailing: false,
                    onTap: () {},
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 44),
                    color: AppThemes.getBorderColor(context).withOpacity(0.5),
                  ),
                  _buildCupertinoListTile(
                    icon: CupertinoIcons.building_2_fill,
                    title: 'Carrier Code',
                    subtitle: prefs.getString('carrierCode') ?? 'Not available',
                    isCompact: isCompact,
                    isFirst: false,
                    isLast: true,
                    showTrailing: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: isCompact ? 32 : 40),

            // Appearance Section
            Container(
              margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
              child: Text(
                'APPEARANCE',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: _buildCupertinoListTile(
                icon: CupertinoIcons.sun_max,
                title: 'Theme',
                subtitle: themeService.currentThemeModeDisplayName,
                isCompact: isCompact,
                isFirst: true,
                isLast: true,
                showTrailing: true,
                onTap: () => _showThemeOptions(context),
              ),
            ),

            SizedBox(height: isCompact ? 32 : 40),

            // Actions Section
            Container(
              margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
              child: Text(
                'ACTIONS',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: _buildCupertinoListTile(
                icon: CupertinoIcons.square_arrow_left,
                title: 'Logout',
                subtitle: null,
                isCompact: isCompact,
                isFirst: true,
                isLast: true,
                isDestructive: true,
                onTap: () => _handleLogout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialSettingsList(SharedPreferences prefs, bool isCompact, BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppThemes.getPrimaryTextColor(context),
        decoration: TextDecoration.none,
      ),
      child: Scrollbar(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 8 : 12,
          ),
          children: [
            // Account Information Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 24,
                vertical: isCompact ? 12 : 16,
              ),
              child: Text(
                'Account Information',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            // Account information card with neumorphic design
            Container(
              margin: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: Column(
                children: [
                  _buildMaterialListTile(
                    icon: Icons.phone,
                    title: 'Phone Number',
                    subtitle: prefs.getString('phoneNumber') ?? 'Not available',
                    isCompact: isCompact,
                    showTrailing: false,
                    onTap: () {},
                  ),
                  Container(
                    height: 0.5,
                    margin: const EdgeInsets.only(left: 60),
                    color: AppThemes.getBorderColor(context).withOpacity(0.5),
                  ),
                  _buildMaterialListTile(
                    icon: Icons.business,
                    title: 'Carrier Code',
                    subtitle: prefs.getString('carrierCode') ?? 'Not available',
                    isCompact: isCompact,
                    showTrailing: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            SizedBox(height: isCompact ? 32 : 40),

            // Appearance Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 24,
                vertical: isCompact ? 12 : 16,
              ),
              child: Text(
                'Appearance',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: _buildMaterialListTile(
                icon: Icons.brightness_6,
                title: 'Theme',
                subtitle: themeService.currentThemeModeDisplayName,
                isCompact: isCompact,
                showTrailing: true,
                onTap: () => _showThemeOptions(context),
              ),
            ),

            SizedBox(height: isCompact ? 32 : 40),

            // Actions Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 24,
                vertical: isCompact ? 12 : 16,
              ),
              child: Text(
                'Actions',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.1,
                ),
              ),
            ),

            SizedBox(height: isCompact ? 32 : 40),

            // Actions Section
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 24,
                vertical: isCompact ? 12 : 16,
              ),
              child: Text(
                'Actions',
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.1,
                ),
              ),
            ),
            // Logout button with neumorphic design
            Container(
              margin: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
              decoration: BoxDecoration(
                color: AppThemes.getNeumorphicBackgroundColor(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppThemes.getNeumorphicShadows(context),
              ),
              child: Builder(
                builder: (context) => _buildMaterialListTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  subtitle: null,
                  isCompact: isCompact,
                  isDestructive: true,
                  onTap: () => _handleLogout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCupertinoListTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required bool isCompact,
    required bool isFirst,
    required bool isLast,
    bool isDestructive = false,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      onPressed: onTap,
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 10 : 12,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(8),
                // Subtle inner shadow for neumorphic icon containers
                boxShadow: [
                  BoxShadow(
                    color: isDestructive ? const Color(0xFFCC2E26).withValues(alpha: 0.3) : const Color(0xFF0056CC).withValues(alpha: 0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 16,
                color: Colors.white,
              ),
            ),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 17,
                      fontWeight: FontWeight.w500,
                      fontFamily: _fontFamily,
                      color: isDestructive ? const Color(0xFFFF3B30) : AppThemes.getPrimaryTextColor(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 15,
                        fontWeight: FontWeight.w400,
                        fontFamily: _fontFamily,
                        color: AppThemes.getSecondaryTextColor(context),
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isDestructive && showTrailing)
              Icon(
                CupertinoIcons.forward,
                size: 16,
                color: AppThemes.getSecondaryTextColor(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialListTile({
    required IconData icon,
    required String title,
    required String? subtitle,
    required bool isCompact,
    bool isDestructive = false,
    bool showTrailing = true,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFF3B30) : const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(10),
          // Subtle inner shadow for neumorphic icon containers
          boxShadow: [
            BoxShadow(
              color: isDestructive ? const Color(0xFFCC2E26).withValues(alpha: 0.3) : const Color(0xFF0056CC).withValues(alpha: 0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.white,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: isCompact ? 16 : 17,
          fontWeight: FontWeight.w500,
          fontFamily: _fontFamily,
          color: isDestructive ? const Color(0xFFFF3B30) : AppThemes.getPrimaryTextColor(context),
          letterSpacing: 0.1,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: isCompact ? 14 : 15,
                fontWeight: FontWeight.w400,
                fontFamily: _fontFamily,
                color: AppThemes.getSecondaryTextColor(context),
                letterSpacing: 0.1,
              ),
            )
          : null,
      trailing: !isDestructive && showTrailing
          ? Icon(
              Icons.chevron_right,
              size: 20,
              color: AppThemes.getSecondaryTextColor(context),
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 20,
        vertical: isCompact ? 4 : 8,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Show Cupertino dialog
      final result = await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontFamily: _fontFamily,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        await _performLogout(context);
      }
    } else {
      // Show Material dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppThemes.getCardColor(context),
          title: Text(
            'Logout',
            style: TextStyle(
              fontFamily: _fontFamily,
              color: AppThemes.getPrimaryTextColor(context),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontFamily: _fontFamily,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        await _performLogout(context);
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      await DioClient().clearCookies();
      await DioClient().clearPreferences();

      if (context.mounted) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => const DriverLoginPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DriverLoginPage()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(
                'Error',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
              ),
              content: Text(
                'Failed to logout: $e',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppThemes.getCardColor(context),
              title: Text(
                'Error',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getPrimaryTextColor(context),
                ),
              ),
              content: Text(
                'Failed to logout: $e',
                style: TextStyle(
                  fontFamily: _fontFamily,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontFamily: _fontFamily,
                      color: AppThemes.getPrimaryTextColor(context),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  /// Show theme selection options
  Future<void> _showThemeOptions(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _showCupertinoThemeOptions(context);
    } else {
      return _showMaterialThemeOptions(context);
    }
  }

  /// Show Cupertino theme selection
  Future<void> _showCupertinoThemeOptions(BuildContext context) async {
    return showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Choose Theme',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily,
            color: AppThemes.getPrimaryTextColor(context),
          ),
        ),
        message: Text(
          'Select how you want the app to appear',
          style: TextStyle(
            fontSize: 13,
            fontFamily: _fontFamily,
            color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
        actions: [
          _buildCupertinoThemeAction(
            title: 'Automatic',
            subtitle: 'Follow system setting',
            icon: CupertinoIcons.device_phone_portrait,
            themeMode: AppThemeMode.system,
            context: context,
          ),
          _buildCupertinoThemeAction(
            title: 'Light',
            subtitle: 'Always use light theme',
            icon: CupertinoIcons.sun_max,
            themeMode: AppThemeMode.light,
            context: context,
          ),
          _buildCupertinoThemeAction(
            title: 'Dark',
            subtitle: 'Always use dark theme',
            icon: CupertinoIcons.moon,
            themeMode: AppThemeMode.dark,
            context: context,
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily,
              color: CupertinoColors.systemRed,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Cupertino theme action
  Widget _buildCupertinoThemeAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemeMode themeMode,
    required BuildContext context,
  }) {
    final isSelected = themeService.themeMode == themeMode;

    return CupertinoActionSheetAction(
      onPressed: () async {
        Navigator.of(context).pop();
        await themeService.setThemeMode(themeMode);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? CupertinoColors.activeBlue : AppThemes.getSecondaryTextColor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: _fontFamily,
                    color: isSelected ? CupertinoColors.activeBlue : AppThemes.getPrimaryTextColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: _fontFamily,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
              color: CupertinoColors.activeBlue,
            ),
          ],
        ],
      ),
    );
  }

  /// Show Material theme selection
  Future<void> _showMaterialThemeOptions(BuildContext context) async {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: _fontFamily,
                          color: AppThemes.getPrimaryTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select how you want the app to appear',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: _fontFamily,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Theme options
                _buildMaterialThemeOption(
                  title: 'Automatic',
                  subtitle: 'Follow system setting',
                  icon: Icons.phone_android,
                  themeMode: AppThemeMode.system,
                  context: context,
                ),
                _buildMaterialThemeOption(
                  title: 'Light',
                  subtitle: 'Always use light theme',
                  icon: Icons.wb_sunny,
                  themeMode: AppThemeMode.light,
                  context: context,
                ),
                _buildMaterialThemeOption(
                  title: 'Dark',
                  subtitle: 'Always use dark theme',
                  icon: Icons.nights_stay,
                  themeMode: AppThemeMode.dark,
                  context: context,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build Material theme option
  Widget _buildMaterialThemeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required AppThemeMode themeMode,
    required BuildContext context,
  }) {
    final isSelected = themeService.themeMode == themeMode;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : AppThemes.getNeumorphicBackgroundColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppThemes.getBorderColor(context),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : AppThemes.getSecondaryTextColor(context),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontFamily: _fontFamily,
          color: isSelected ? const Color(0xFF007AFF) : AppThemes.getPrimaryTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          fontFamily: _fontFamily,
          color: AppThemes.getSecondaryTextColor(context),
        ),
      ),
      trailing: isSelected
          ? const Icon(
              Icons.check_circle,
              color: Color(0xFF007AFF),
              size: 24,
            )
          : null,
      onTap: () async {
        Navigator.of(context).pop();
        await themeService.setThemeMode(themeMode);
      },
    );
  }
}
