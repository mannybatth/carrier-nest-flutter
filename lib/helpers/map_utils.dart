import 'dart:io';
import 'package:carrier_nest_flutter/models.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static const _googleMapsScheme = 'comgooglemapsurl';
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

    final googleMapsWebUri =
        Uri.https('www.google.com', '/maps/search/$address');

    if (Platform.isIOS) {
      final schemeUri = Uri(
        scheme: _googleMapsScheme,
        host: googleMapsWebUri.host,
        path: googleMapsWebUri.path,
      );
      if (await _launchUri(schemeUri)) return;
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
      '/maps/dir/$origin/$waypoints/$destination',
      {
        'travelmode': 'driving',
      },
    );

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

    // Fallback to web route
    await _launchUri(googleMapsWebUri);
  }
}
