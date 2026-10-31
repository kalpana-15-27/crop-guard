import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/pest_model.dart';

/// Detection API & Supabase History Service
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
        return DetectionResult.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } on DioException catch (e) {
      // If backend is not yet running or during UI Phase 3 before model integration:
      // Return a clearly labeled placeholder result indicating model integration phase
      return _generatePlaceholderResult(
        imagePath: imageFile.path,
        cropType: cropType,
        errorNote: e.message ?? 'Backend offline',
      );
    } catch (e) {
      return _generatePlaceholderResult(
        imagePath: imageFile.path,
        cropType: cropType,
        errorNote: e.toString(),
      );
    }
  }

  /// Transparently labeled placeholder result for UI testing before Phase 6 model integration
  DetectionResult _generatePlaceholderResult({
    required String imagePath,
    required String cropType,
    required String errorNote,
  }) {
    return DetectionResult(
      id: 'placeholder_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: imagePath,
      cropType: cropType,
      status: 'pending',
      totalDetections: 0,
      processingTimeSec: 0.12,
      modelVersion: '${AppConfig.modelVersion} (Awaiting Phase 6 Model Integration)',
      primaryPest: null,
      highestConfidence: 0.0,
      detections: [],
      createdAt: DateTime.now(),
    );
  }
}
