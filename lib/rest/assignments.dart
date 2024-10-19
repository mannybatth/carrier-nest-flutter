import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';

class Assignments {
  static Future<Map<String, dynamic>> getDriverAssignments({
    Sort? sort,
    String? driverId,
    int? limit,
    int? offset,
    bool? upcomingOnly,
  }) async {
    final Map<String, String> params = {
      if (sort?.key != null) 'sortBy': sort!.key!,
      if (sort?.order != null) 'sortDir': sort!.order!,
      if (driverId != null) 'driverId': driverId,
      if (limit != null) 'limit': limit.toString(),
      if (offset != null) 'offset': offset.toString(),
      if (upcomingOnly != null) 'upcomingOnly': upcomingOnly ? '1' : '0',
    };

    final response = await DioClient().dio.get<Map<String, dynamic>>(
        '$apiUrl/assignment/for-driver',
        queryParameters: params);

    if (response.statusCode == 200) {
      final List<dynamic> errors =
          response.data?['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final List<DriverAssignment> assignments =
          (response.data?['data']['assignments'] as List)
              .map((item) => DriverAssignment.fromJson(item))
              .toList();

      final PaginationMetadata metadata =
          PaginationMetadata.fromJson(response.data?['data']['metadata']);

      return {'assignments': assignments, 'metadata': metadata};
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<DriverAssignment> getAssignmentById({
    required String assignmentId,
  }) async {
    final response = await DioClient().dio.get<Map<String, dynamic>>(
          '$apiUrl/assignment/$assignmentId',
        );

    if (response.statusCode == 200) {
      final List<dynamic> errors =
          response.data?['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      return DriverAssignment.fromJson(response.data?['data']);
    } else {
      throw Exception('Failed to load assignment');
    }
  }

  static Future<void> updateRouteLegStatus({
    required String routeLegId,
    required RouteLegStatus routeLegStatus,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    double? activityLatitude,
    double? activityLongitude,
  }) async {
    final Map<String, dynamic> data = {
      'routeLegStatus': routeLegStatus
          .toString()
          .split('.')
          .last, // Getting the enum value as a string,
      if (startLatitude != null) 'startLatitude': startLatitude,
      if (startLongitude != null) 'startLongitude': startLongitude,
      if (endLatitude != null) 'endLatitude': endLatitude,
      if (endLongitude != null) 'endLongitude': endLongitude,
      if (activityLatitude != null) 'latitude': activityLatitude,
      if (activityLongitude != null) 'longitude': activityLongitude,
    };

    final response = await DioClient().dio.patch<Map<String, dynamic>>(
          '$apiUrl/route-leg/$routeLegId',
          data: data,
        );

    if (response.statusCode != 200) {
      final List<dynamic> errors =
          response.data?['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      throw Exception('Failed to update route leg status');
    }
  }
}
