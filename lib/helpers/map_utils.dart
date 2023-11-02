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

  static void openRoute(ExpandedLoad load) async {
    final origin = '${load.shipper.latitude},${load.shipper.longitude}';
    final destination = '${load.receiver.latitude},${load.receiver.longitude}';
    final waypoints = load.stops.isNotEmpty
        ? load.stops
            .map((stop) => '${stop.latitude},${stop.longitude}')
            .join('/')
        : '';

    if (origin.isEmpty || destination.isEmpty) {
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
