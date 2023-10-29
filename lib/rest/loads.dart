import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';

class Loads {
  static Future<Map<String, dynamic>> getLoadsExpanded({
    Sort? sort,
    String? customerId,
    String? driverId,
    int? limit,
    int? offset,
    bool? currentOnly,
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
      if (currentOnly != null) 'currentOnly': currentOnly ? '1' : '0',
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

      print('Loads: $loads');
      return {'loads': loads, 'metadata': metadata};
    } else {
      throw Exception('Failed to load data');
    }
  }

  static Future<ExpandedLoad> getLoadById(String id,
      {String? driverId, bool expandCarrier = false}) async {
    String expand = 'customer,shipper,receiver,stops,invoice,driver,documents';
    if (expandCarrier) {
      expand += ',carrier';
    }

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
}
