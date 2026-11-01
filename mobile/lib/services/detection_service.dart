import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../localization/app_strings.dart';
import '../models/pest_model.dart';

/// Custom Exception thrown for detection API errors
class DetectionApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const DetectionApiException(
    this.message, {
    this.errorCode,
    this.statusCode,
  });

  @override
  String toString() => message;
}

/// Detection API Service
class DetectionService {
  static final DetectionService _instance = DetectionService._internal();
  factory DetectionService() => _instance;
  DetectionService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  /// Send captured image to backend YOLO endpoint
  Future<DetectionResult> detectPest({
    required File imageFile,
    required String cropType,
    String? userToken,
  }) async {
    final tr = AppStrings().tr;
    final fileName = imageFile.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      'crop_type': cropType,
    });

    final options = Options(
      headers: userToken != null ? {'Authorization': 'Bearer $userToken'} : null,
    );

    try {
      final response = await _dio.post(
        '/api/v1/detect',
        data: formData,
        options: options,
      );

      if (response.statusCode == 200 && response.data != null) {
        return DetectionResult.fromJson(
          response.data as Map<String, dynamic>,
          localImagePath: imageFile.path,
        );
      } else {
        throw DetectionApiException(
          'Server returned status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;

        // 1. Missing Model: HTTP 503 with MODEL_NOT_TRAINED
        if (statusCode == 503) {
          throw DetectionApiException(
            tr('modelNotTrainedError'),
            errorCode: 'MODEL_NOT_TRAINED',
            statusCode: 503,
          );
        }

        // 2. Client Validation errors: HTTP 400, 413, 415
        if (statusCode == 400 || statusCode == 413 || statusCode == 415) {
          String msg = tr('invalidImageError');
          if (data is Map && data.containsKey('detail')) {
            final detail = data['detail'];
            if (detail is String) {
              msg = detail;
            } else if (detail is Map && detail.containsKey('message')) {
              msg = detail['message'].toString();
            }
          }
          throw DetectionApiException(
            msg,
            errorCode: 'INVALID_IMAGE',
            statusCode: statusCode,
          );
        }

        // 3. Other server status codes
        throw DetectionApiException(
          'Server error ($statusCode). Please try again.',
          statusCode: statusCode,
        );
      }

      // 4. Connection failure (timeout, connection refused, offline)
      throw DetectionApiException(
        tr('serverConnectionError'),
        errorCode: 'CONNECTION_FAILED',
      );
    } catch (e) {
      if (e is DetectionApiException) rethrow;
      throw DetectionApiException(
        tr('serverConnectionError'),
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
}
