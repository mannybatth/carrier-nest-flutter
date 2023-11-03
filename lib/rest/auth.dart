import 'package:carrier_nest_flutter/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';

class DriverAuth {
  String? _csrfToken;

  Future<void> fetchCsrfToken() async {
    var response =
        await DioClient().dio.get<Map<String, dynamic>>('$apiUrl/auth/csrf');
    if (response.statusCode == 200) {
      final data = response.data;
      _csrfToken = data?['csrfToken'];
    } else {
      // TODO: Handle error
    }
  }

  Future<Response> requestPin(
      {required String phoneNumber, required String carrierCode}) async {
    var response =
        await DioClient().dio.post('$apiUrl/auth/callback/driver_auth',
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

  Future<dynamic> verifyPin(
      {required String phoneNumber,
      required String carrierCode,
      required String code}) async {
    var response =
        await DioClient().dio.post('$apiUrl/auth/callback/driver_auth',
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
        final jwtToken =
            _extractSessionToken(response.headers.value('set-cookie')!);
        await prefs.setString("jwtToken", jwtToken);
      }

      var tokenResponse = await DioClient()
          .dio
          .get<Map<String, dynamic>>('$apiUrl/auth/get-token');

      if (tokenResponse.data != null) {
        final tokenData = tokenResponse.data?["token"];

        if (tokenData != null) {
          await prefs.setString("driverId", tokenData["driverId"]);
          await prefs.setString("phoneNumber", tokenData["phoneNumber"]);
          await prefs.setString("carrierId", tokenData["carrierId"]);
          await prefs.setString("carrierCode", carrierCode);
          await prefs.setInt("exp", tokenData["exp"]);

          return tokenData;
        }
      }
    } else {
      // TODO: Handle error
    }

    return null;
  }

  String _extractSessionToken(String cookieString) {
    RegExp regExp = RegExp(r'next-auth\.session-token=([^;]+)');
    var match = regExp.firstMatch(cookieString);
    return match?.group(1) ?? '';
  }
}
