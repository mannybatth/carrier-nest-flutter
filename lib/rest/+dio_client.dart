import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:carrier_nest_flutter/pages/driver_login.dart';
import 'package:carrier_nest_flutter/globals.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() {
    return _instance;
  }

  late Dio dio;
  late PersistCookieJar cookieJar;

  DioClient._internal() {
    initDio();
  }

  Future<void> initDio() async {
    // Get a directory to store cookies
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDocPath = appDocDir.path;

    dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15)));

    cookieJar = PersistCookieJar(storage: FileStorage("$appDocPath/.cookies"));
    dio.interceptors.add(CookieManager(cookieJar));

    // Add an interceptor to handle 401 responses
    dio.interceptors.add(InterceptorsWrapper(
      onRequest:
          (RequestOptions options, RequestInterceptorHandler handler) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? jwtToken = prefs.getString("jwtToken");
        if (jwtToken != null) {
          options.headers[HttpHeaders.authorizationHeader] = "Bearer $jwtToken";
        }
        return handler.next(options);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          // Redirect to the driver login page
          navigateToDriverLoginPage();
          return handler.next(error);
        }
        return handler.reject(error); // Continue with error handling
      },
    ));
  }

  // Method to navigate to the driver login page
  void navigateToDriverLoginPage() {
    clearCookies().then((value) => clearPreferences()).then((value) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DriverLoginPage()),
        (Route<dynamic> route) =>
            false, // This removes all the routes until it gets to the login page
      );
    });
  }

  Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }

  // clear preferences
  Future<void> clearPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<void> printCookies(Uri uri) async {
    List<Cookie> cookies = await cookieJar.loadForRequest(uri);
    for (var cookie in cookies) {
      print('${cookie.name}: ${cookie.toString()}');
    }
  }
}
