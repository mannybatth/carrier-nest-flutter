import 'package:carrier_nest_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';

class DriverAuth {
  String? _csrfToken;

  Future<void> fetchCsrfToken() async {
    final dio = await DioClient().getDio();
    var response = await dio.get<Map<String, dynamic>>('$apiUrl/auth/csrf');
    if (response.statusCode == 200) {
      final data = response.data;
      _csrfToken = data?['csrfToken'];
    } else {
      // TODO: Handle error
    }
  }

  Future<Response> requestPin({required String phoneNumber, required String carrierCode}) async {
    final dio = await DioClient().getDio();
    var response = await dio.post('$apiUrl/auth/callback/driver_auth',
        data: {
          "phoneNumber": phoneNumber,
          "carrierCode": carrierCode,
          "csrfToken": _csrfToken!,
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 2,
          validateStatus: (status) {
            return status! < 500;
          },
        ));
    return response;
  }

  Future<dynamic> verifyPin({required String phoneNumber, required String carrierCode, required String code}) async {
    final dio = await DioClient().getDio();
    var response = await dio.post('$apiUrl/auth/callback/driver_auth',
        data: {
          "phoneNumber": phoneNumber,
          "carrierCode": carrierCode,
          "code": code,
          "csrfToken": _csrfToken!,
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 2,
          validateStatus: (status) {
            return status! < 500;
          },
        ));

    if (response.statusCode == 200 || response.statusCode == 302) {
      // Store the necessary data using SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Extract JWT token from Set-Cookie header
      if (response.headers.value('set-cookie') != null) {
        final jwtToken = _extractSessionToken(response.headers.value('set-cookie')!);
        await prefs.setString("jwtToken", jwtToken);
      }

      final dio = await DioClient().getDio();
      var sessionResponse = await dio.get<Map<String, dynamic>>('$apiUrl/auth/session');

      if (sessionResponse.data != null) {
        final sessionData = sessionResponse.data?["user"];

        if (sessionData != null) {
          await prefs.setString("driverId", sessionData["driverId"]);
          await prefs.setString("phoneNumber", sessionData["phoneNumber"]);
          await prefs.setString("carrierId", sessionData["carrierId"]);
          await prefs.setString("carrierCode", carrierCode);

          return sessionData;
        }
      }
    } else {
      // TODO: Handle error
    }

    return null;
  }

  String _extractSessionToken(String cookieString) {
    RegExp regExp = RegExp(r'\.session-token=([^;]+)');
    var match = regExp.firstMatch(cookieString);
    return match?.group(1) ?? '';
  }
}
