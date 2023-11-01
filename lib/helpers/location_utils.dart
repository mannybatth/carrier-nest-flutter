import 'package:geolocator/geolocator.dart';

class LocationUtils {
  static Future<Position?> getDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    print("Checking if location service is enabled...");
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location service is not enabled.");
      // Handle the case where the location service is not enabled
      return null;
    }

    print("Checking location permissions...");
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      print("Location permission denied. Requesting permission...");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission was denied by the user.");
        // Handle the case where the user denied permission
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permission is permanently denied.");
      // Handle the case where the permission is permanently denied
      return null;
    }

    print("Fetching location data...");
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    print("Location data obtained: ${position.toString()}");

    return position;
  }
}
