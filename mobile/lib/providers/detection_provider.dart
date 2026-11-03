import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pest_model.dart';
import '../services/detection_service.dart';

/// Detection Provider managing image selection, scan history, and active detection state
class DetectionProvider with ChangeNotifier {
  final DetectionService _detectionService = DetectionService();
  final ImagePicker _picker = ImagePicker();

  static const String _historyKey = 'cropguard_scan_history_records';

  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  XFile? _selectedXFile;
  String _selectedCrop = 'Paddy/Rice';
  bool _isAnalyzing = false;
  DetectionResult? _currentResult;
  String? _errorMessage;

  // Scan History in-memory & persistent cache
  final List<DetectionResult> _historyList = [];

  DetectionProvider() {
    _loadHistoryFromDisk();
  }

  Future<void> _loadHistoryFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _historyList.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _historyList.add(DetectionResult.fromJson(item));
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DetectionProvider] Error loading persisted history: $e');
    }
  }

  Future<void> _saveHistoryToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[DetectionProvider] Error persisting history: $e');
    }
  }

  File? get selectedImage => _selectedImage;
  Uint8List? get selectedImageBytes => _selectedImageBytes;
  XFile? get selectedXFile => _selectedXFile;
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
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        _selectedXFile = file;
        _selectedImageBytes = bytes;
        if (!kIsWeb) {
          _selectedImage = File(file.path);
        }
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
        imageQuality: 85,
        maxWidth: 1280,
        maxHeight: 1280,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        _selectedXFile = file;
        _selectedImageBytes = bytes;
        if (!kIsWeb) {
          _selectedImage = File(file.path);
        }
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
    _selectedImageBytes = null;
    _selectedXFile = null;
    _currentResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Run Detection on selected image
  Future<bool> analyzeSelectedImage({String? userToken}) async {
    if (_selectedImageBytes == null && _selectedImage == null) {
      _errorMessage = 'Please select or capture an image first';
      notifyListeners();
      return false;
    }

    _isAnalyzing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _detectionService.detectPest(
        imageFile: _selectedImage,
        imageBytes: _selectedImageBytes,
        fileName: _selectedXFile?.name ?? 'pest_photo.jpg',
        cropType: _selectedCrop,
        userToken: userToken,
      );

      _currentResult = result;
      _historyList.insert(0, result);
      _saveHistoryToDisk();
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
    _saveHistoryToDisk();
    notifyListeners();
  }

  void clearHistory() {
    _historyList.clear();
    _saveHistoryToDisk();
    notifyListeners();
  }
}
