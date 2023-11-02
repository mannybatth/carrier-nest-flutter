import 'dart:io';
import 'package:carrier_nest_flutter/models.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static const _googleMapsScheme = 'comgooglemapsurl://';
  static const _appleMapsUrl = 'https://maps.apple.com/';

  static Future<bool> _launchUrl(String url) async {
    return await _launchUri(Uri.parse(url));
  }

  static Future<bool> _launchUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return true;
    }
    print('Failed to launch URL: ${uri.toString()}');
    return false;
  }

  static void openAddress(String address) async {
    final encodedAddress = Uri.encodeComponent(address);

    final googleMapsWebUri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': address,
      },
    );

    if (Platform.isIOS) {
      final schemeUrl = googleMapsWebUri
          .toString()
          .replaceFirst('https://', _googleMapsScheme);
      if (await _launchUrl(schemeUrl)) return;
      if (await _launchUrl('$_appleMapsUrl?q=$encodedAddress')) return;
    }

    // Fallback to web address
    await _launchUri(googleMapsWebUri);
  }

  static void openRoute(ExpandedLoad load) async {
    final origin = '${load.shipper.latitude},${load.shipper.longitude}';
    final destination = '${load.receiver.latitude},${load.receiver.longitude}';
    final waypoints = load.stops.isNotEmpty
        ? load.stops
            .map((stop) => '${stop.latitude},${stop.longitude}')
            .join('/')
        : '';

    if (origin.isEmpty || destination.isEmpty) {
      print('Origin or destination is empty.');
      return;
    }

    final googleMapsWebUri = Uri.https(
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

    if (Platform.isIOS) {
      final schemeUrl = googleMapsWebUri
          .toString()
          .replaceFirst('https://', _googleMapsScheme);
      if (await _launchUrl(schemeUrl)) {
        return;
      }
    }

    // Fallback to web route
    await _launchUri(googleMapsWebUri);
  }
}
