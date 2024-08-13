import 'dart:io';
import 'package:carrier_nest_flutter/models.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static const _googleMapsScheme = 'comgooglemapsurl';

  static Future<bool> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri);
        return true;
      } catch (e) {
        return true;
      }
    }
    return false;
  }

  static void openAddress(String address) async {
    final googleMapsWebUri =
        Uri.https('www.google.com', '/maps/search/$address');

    if (Platform.isIOS) {
      final schemeUri = Uri(
        scheme: _googleMapsScheme,
        host: googleMapsWebUri.host,
        path: googleMapsWebUri.path,
      );
      if (await _launchUri(schemeUri)) return;

      final appleUri = Uri.https('maps.apple.com', '/', {'q': address});
      if (await _launchUri(appleUri)) return;
    }

    // Fallback to web address
    await _launchUri(googleMapsWebUri);
  }

  static void openRouteFromLoad(ExpandedLoad load) async {
    // Check if load.route is null, routeLegs is empty, or first routeLeg has fewer than two locations
    if (load.route == null ||
        load.route!.routeLegs.isEmpty ||
        load.route!.routeLegs.first.locations.length < 2) {
      // If any of these checks fail, exit the method
      return;
    }

    // Get the first route leg
    final RouteLeg firstLeg = load.route!.routeLegs.first;
    openRoute(firstLeg);
  }

  static void openRoute(RouteLeg routeLeg) async {
    // Get all RouteLegLocations from the firstLeg
    final List<RouteLegLocation> firstLegLocations = routeLeg.locations;

    // Extract origin from the first RouteLeg's first location
    final RouteLegLocation originLegLocation = firstLegLocations.first;
    final originLatitude = originLegLocation.loadStop?.latitude ??
        originLegLocation.location?.latitude;
    final originLongitude = originLegLocation.loadStop?.longitude ??
        originLegLocation.location?.longitude;
    final origin = '$originLatitude,$originLongitude';

    // Extract destination from the firstLeg's last location
    final RouteLegLocation destinationLegLocation = firstLegLocations.last;
    final destinationLatitude = destinationLegLocation.loadStop?.latitude ??
        destinationLegLocation.location?.latitude;
    final destinationLongitude = destinationLegLocation.loadStop?.longitude ??
        destinationLegLocation.location?.longitude;
    final destination = '$destinationLatitude,$destinationLongitude';

    // Extract waypoints from the intermediate RouteLegLocations in the firstLeg, skipping the first and last locations
    final waypoints = firstLegLocations
        .skip(1)
        .take(firstLegLocations.length - 2)
        .map((location) {
      final lat = location.loadStop?.latitude ?? location.location?.latitude;
      final long = location.loadStop?.longitude ?? location.location?.longitude;
      return '$lat,$long';
    }).join('|'); // Use '|' as the separator for waypoints

    // Ensure origin and destination are not empty
    if (origin.isEmpty || destination.isEmpty) {
      return;
    }

    // Build the Google Maps URL using query parameters
    final searchParams = {
      'api': '1',
      'origin': origin,
      'destination': destination,
      if (waypoints.isNotEmpty) 'waypoints': waypoints,
      'travelmode': 'driving',
    };

    final googleMapsWebUri =
        Uri.https('www.google.com', '/maps/dir/', searchParams);

    // Handle iOS-specific Google Maps URL scheme
    if (Platform.isIOS) {
      final schemeUri = Uri(
        scheme: _googleMapsScheme,
        host: googleMapsWebUri.host,
        path: googleMapsWebUri.path,
        queryParameters: googleMapsWebUri.queryParameters,
      );
      if (await _launchUri(schemeUri)) {
        return;
      }
    }

    // Fallback to web route if iOS scheme fails
    await _launchUri(googleMapsWebUri);
  }
}
