import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Loads {
  static Future<Map<String, dynamic>> getLoadsExpanded({
    Sort? sort,
    String? customerId,
    String? driverId,
    int? limit,
    int? offset,
    bool? upcomingOnly,
    String? expand,
  }) async {
    final Map<String, String> params = {
      'expand': expand ?? 'customer,shipper,receiver',
      if (sort?.key != null) 'sortBy': sort!.key!,
      if (sort?.order != null) 'sortDir': sort!.order!,
      if (customerId != null) 'customerId': customerId,
      if (driverId != null) 'driverId': driverId,
      if (limit != null) 'limit': limit.toString(),
      if (offset != null) 'offset': offset.toString(),
      if (upcomingOnly != null) 'upcomingOnly': upcomingOnly ? '1' : '0',
    };

    final response = await DioClient()
        .dio
        .get<Map<String, dynamic>>('$apiUrl/loads', queryParameters: params);

    if (response.statusCode == 200) {
      final List<dynamic> errors =
          response.data?['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final List<ExpandedLoad> loads = (response.data?['data']['loads'] as List)
          .map((item) => ExpandedLoad.fromJson(item))
          .toList();

      final PaginationMetadata metadata =
          PaginationMetadata.fromJson(response.data?['data']['metadata']);

      return {'loads': loads, 'metadata': metadata};
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<ExpandedLoad> getLoadById(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? driverId = prefs.getString("driverId");

    String expand =
        'customer,shipper,receiver,stops,invoice,driver,documents,carrier';

    final Map<String, String> params = {
      'expand': expand,
      if (driverId != null) 'driverId': driverId,
    };

    final response = await DioClient().dio.get<Map<String, dynamic>>(
        '$apiUrl/loads/$id',
        queryParameters: params);

    if (response.statusCode == 200) {
      final List<dynamic> errors =
          response.data?['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final ExpandedLoad load =
          ExpandedLoad.fromJson(response.data?['data']['load']);
      return load;
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<Load> updateLoadStatus({
    required String loadId,
    required LoadStatus status,
    String? driverId,
    double? longitude,
    double? latitude,
  }) async {
    final Map<String, dynamic> body = {
      'status': status
          .toString()
          .split('.')
          .last, // Getting the enum value as a string
      if (driverId != null) 'driverId': driverId,
      if (longitude != null) 'longitude': longitude,
      if (latitude != null) 'latitude': latitude,
    };

    final response = await DioClient().dio.patch<Map<String, dynamic>>(
          '$apiUrl/loads/$loadId/status',
          data: body,
        );

    if (response.statusCode == 200) {
      final List<dynamic> errors = response.data?['errors'] ?? [];

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final Load load = Load.fromJson(response.data?['data']['load']);
      return load;
    } else {
      throw Exception('Failed to update load status');
    }
  }
}
