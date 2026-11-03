import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'bypass-tunnel-reminder': 'true',
      },
    ),
  );

  /// Synchronizes and normalizes the active backend base URL
  void _syncBaseUrl() {
    String cleanUrl = AppConfig.backendBaseUrl.trim();
    while (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (_dio.options.baseUrl != cleanUrl) {
      _dio.options.baseUrl = cleanUrl;
    }
  }

  /// Updates backend base URL dynamically (e.g. switching from emulator to physical device LAN IP)
  void updateBaseUrl(String newUrl) {
    AppConfig.backendBaseUrl = newUrl.trim();
    _syncBaseUrl();
    debugPrint('[DetectionService] Backend URL updated to: ${_dio.options.baseUrl}');
  }

  /// Send captured image to backend YOLO endpoint (universal for Web and Mobile)
  Future<DetectionResult> detectPest({
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
    required String cropType,
    String? userToken,
  }) async {
    final tr = AppStrings().tr;
    _syncBaseUrl();

    MultipartFile multipartFile;
    final uploadFileName = fileName ?? 'crop_pest.jpg';

    if (imageBytes != null) {
      multipartFile = MultipartFile.fromBytes(imageBytes, filename: uploadFileName);
    } else if (imageFile != null && !kIsWeb) {
      if (!imageFile.existsSync()) {
        throw const DetectionApiException(
          'Selected image file does not exist on device storage.',
          errorCode: 'FILE_NOT_FOUND',
        );
      }
      final name = imageFile.path.split(Platform.pathSeparator).last;
      multipartFile = await MultipartFile.fromFile(imageFile.path, filename: name);
    } else {
      throw const DetectionApiException(
        'No valid image data provided for analysis.',
        errorCode: 'NO_IMAGE',
      );
    }

    final targetEndpoint = '${_dio.options.baseUrl}/api/v1/detect';
    debugPrint('[DetectionService] Sending detection request to: $targetEndpoint (crop: $cropType, file: $uploadFileName)');

    final formData = FormData.fromMap({
      'file': multipartFile,
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

      debugPrint('[DetectionService] Response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        return DetectionResult.fromJson(
          response.data as Map<String, dynamic>,
          localImagePath: !kIsWeb && imageFile != null ? imageFile.path : null,
        );
      } else {
        throw DetectionApiException(
          'Server returned status ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('[DetectionService] DioException: type=${e.type}, message=${e.message}, error=${e.error}');
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

      // 4. Connection failure: Timeout, Connection Refused, or Network Unreachable
      String detailedMessage = tr('serverConnectionError');
      String errCode = 'CONNECTION_FAILED';

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        detailedMessage = 'Cloud server was waking up from sleep or network timed out. Please tap "Analyze" once more to retry.';
        errCode = 'TIMEOUT';
      } else if (e.type == DioExceptionType.connectionError) {
        detailedMessage = 'Cannot connect to server at ${_dio.options.baseUrl}. Please check internet connection.';
        errCode = 'CONNECTION_FAILED';
      }

      throw DetectionApiException(
        detailedMessage,
        errorCode: errCode,
      );
    } catch (e) {
      if (e is DetectionApiException) rethrow;
      debugPrint('[DetectionService] Unexpected exception: $e');
      throw DetectionApiException(
        'Unexpected detection error: $e',
        errorCode: 'UNEXPECTED_ERROR',
      );
    }
  }
}
