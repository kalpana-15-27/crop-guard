import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pest_model.dart';
import '../services/detection_service.dart';

/// Detection Provider managing image selection, scan history, and active detection state
class DetectionProvider with ChangeNotifier {
  final DetectionService _detectionService = DetectionService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  String _selectedCrop = 'Paddy/Rice';
  bool _isAnalyzing = false;
  DetectionResult? _currentResult;
  String? _errorMessage;

  // Scan History in-memory cache
  final List<DetectionResult> _historyList = [];

  File? get selectedImage => _selectedImage;
  String get selectedCrop => _selectedCrop;
  bool get isAnalyzing => _isAnalyzing;
  DetectionResult? get currentResult => _currentResult;
  String? get errorMessage => _errorMessage;
  List<DetectionResult> get historyList => List.unmodifiable(_historyList);

  int get totalScans => _historyList.length;
  int get pestsDetectedCount => _historyList.where((d) => d.isPestDetected).length;
  int get cleanScansCount => _historyList.where((d) => !d.isPestDetected).length;

  void setSelectedCrop(String crop) {
    _selectedCrop = crop;
    notifyListeners();
  }

  /// Pick image using device Camera
  Future<bool> pickImageFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null) {
        _selectedImage = File(file.path);
        _currentResult = null;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to capture image: $e';
      notifyListeners();
    }
    return false;
  }

  /// Pick image from Gallery
  Future<bool> pickImageFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (file != null) {
        _selectedImage = File(file.path);
        _currentResult = null;
        _errorMessage = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Failed to pick image from gallery: $e';
      notifyListeners();
    }
    return false;
  }

  void clearSelectedImage() {
    _selectedImage = null;
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Run Detection on selected image
  Future<bool> analyzeSelectedImage({String? userToken}) async {
    if (_selectedImage == null) {
      _errorMessage = 'Please select or capture an image first';
      notifyListeners();
      return false;
    }

    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _detectionService.detectPest(
        imageFile: _selectedImage!,
        cropType: _selectedCrop,
        userToken: userToken,
      );

      _currentResult = result;
      _historyList.insert(0, result);
      _isAnalyzing = false;
      notifyListeners();
      return true;
    } on DetectionApiException catch (e) {
      _errorMessage = e.message;
      _isAnalyzing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isAnalyzing = false;
      notifyListeners();
      return false;
    }
  }

  void removeHistoryItem(String id) {
    _historyList.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearHistory() {
    _historyList.clear();
    notifyListeners();
  }
}
