import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static Future<Position?> getDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle the case where the location service is not enabled
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Handle the case where the user denied permission
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Handle the case where the permission is permanently denied
      return null;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    return position;
  }
}
