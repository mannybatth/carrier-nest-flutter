import 'package:carrier_nest_flutter/constants.dart';
import 'package:carrier_nest_flutter/rest/+dio_client.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class UploadResponse {
  final String? gcsInputUri;
  final String? uniqueFileName;
  final String? originalFileName;

  UploadResponse({
    this.gcsInputUri,
    this.uniqueFileName,
    this.originalFileName,
  });

  factory UploadResponse.fromJson(Map<String, dynamic> json) {
    return UploadResponse(
      gcsInputUri: json['gcsInputUri'],
      uniqueFileName: json['uniqueFileName'],
      originalFileName: json['originalFileName'],
    );
  }
}

class PodUpload {
  static Future<UploadResponse> uploadFileToGCS(PlatformFile file) async {
    if (file.path == null) {
      throw Exception('File path is null');
    }

    Dio dio = await DioClient().getDio();
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path!),
    });

    Response response = await dio.post(
      '$apiUrl/upload-gcs',
      data: formData,
    );

    return UploadResponse.fromJson(response.data);
  }
}
