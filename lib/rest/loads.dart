import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/models.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

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

    final Uri uri = Uri.parse('$apiUrl/loads').replace(queryParameters: params);
    final http.Response response = await http.get(uri);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> errors =
          jsonResponse['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final List<ExpandedLoad> loads = (jsonResponse['data']['loads'] as List)
          .map((item) => ExpandedLoad.fromJson(item))
          .toList();

      final PaginationMetadata metadata =
          PaginationMetadata.fromJson(jsonResponse['data']['metadata']);

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

    final Uri uri =
        Uri.parse('$apiUrl/loads/$id').replace(queryParameters: params);
    final http.Response response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      final List<dynamic> errors =
          jsonResponse['errors'] ?? []; // Assuming errors are a list

      if (errors.isNotEmpty) {
        throw Exception(errors.map((e) => e.toString()).join(', '));
      }

      final ExpandedLoad load =
          ExpandedLoad.fromJson(jsonResponse['data']['load']);
      return load;
    } else {
      throw Exception('Failed to load data');
    }
  }
}
