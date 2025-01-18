double metersToMiles(double meters) {
  return meters * 0.000621371;
}

String secondsToReadable(double seconds) {
  if (seconds < 60) {
    return "$seconds sec";
  }

  if (seconds < 60 * 60) {
    return "${(seconds / 60).toStringAsFixed(1)} min";
  }

  return "${(seconds / 60 / 60).toStringAsFixed(1)} hrs";
}

String hoursToReadable(double hours) {
  if (hours < 1) {
    return "${(hours * 60).toStringAsFixed(1)} min";
  }

  return "${hours.toStringAsFixed(2)} hrs";
}
