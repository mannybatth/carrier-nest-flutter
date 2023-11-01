import 'dart:io';
import 'package:carrier_nest_flutter/models.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static void openAddress(String address) async {
    String encodedAddress = Uri.encodeComponent(address);
    String googleMapsUrl;

    if (Platform.isIOS) {
      googleMapsUrl = 'comgooglemaps://?q=$encodedAddress';
    } else {
      googleMapsUrl = 'geo:0,0?q=$encodedAddress';
    }

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      // Fallback to web address
      String googleMapsWebUrl =
          'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
        await launchUrl(Uri.parse(googleMapsWebUrl));
      } else {
        // Handle error: Neither Google Maps app nor web browser can be opened
      }
    }
  }

  static void openRouteInGoogleMaps(ExpandedLoad load) async {
    // Origin is the load shipper address
    final String origin = '${load.shipper.latitude},${load.shipper.longitude}';
    // Destination is the load receiver address
    final String destination =
        '${load.receiver.latitude},${load.receiver.longitude}';
    // Waypoints are the load stops, separated by a pipe
    final String waypoints = load.stops.isNotEmpty
        ? load.stops
            .map((stop) => '${stop.latitude},${stop.longitude}')
            .join('|')
        : '';

    if (origin.isEmpty || destination.isEmpty) {
      // Handle error: Origin or destination is empty
      return;
    }

    String googleMapsUrl;

    if (Platform.isIOS) {
      // iOS URL Scheme
      googleMapsUrl =
          'comgooglemaps://?saddr=$origin&daddr=$destination&directionsmode=driving${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';
    } else {
      // Android URL Scheme
      googleMapsUrl =
          'google.navigation:q=$destination&mode=d${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}';
    }

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(Uri.parse(googleMapsUrl));
    } else {
      // Fallback to web route
      final Uri googleMapsWebUri = Uri.https(
        'www.google.com',
        '/maps/dir/',
        {
          'api': '1',
          'origin': origin,
          'destination': destination,
          if (waypoints.isNotEmpty) 'waypoints': waypoints,
          'travelmode': 'driving',
        },
      );
      if (await canLaunchUrl(googleMapsWebUri)) {
        await launchUrl(googleMapsWebUri);
      } else {
        // Handle error: Neither Google Maps app nor web browser can be opened
      }
    }
  }
}
