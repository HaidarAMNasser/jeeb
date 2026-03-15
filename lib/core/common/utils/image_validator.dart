import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';

/// Image validation result
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ImageValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Image validator utility for validating image files
class ImageValidator {
  // Supported formats
  static const List<String> supportedFormats = ['png', 'jpg', 'jpeg', 'webp'];
  
  // Minimum dimensions
  static const int minWidth = 1024;
  static const int minHeight = 1024;
  
  // Maximum file size (10 MB)
  static const int maxFileSize = 10 * 1024 * 1024;

  /// Validates an image file
  /// Returns [ImageValidationResult] with validation status and error message
  static Future<ImageValidationResult> validateImage(XFile imageFile) async {
    try {
      // Check file extension
      final extension = _getFileExtension(imageFile.path);
      if (!supportedFormats.contains(extension.toLowerCase())) {
        return const ImageValidationResult(
          isValid: false,
          errorMessage: 'Unsupported image format. Please use PNG, JPG, JPEG, or WebP.',
        );
      }

      // Check file size
      final file = File(imageFile.path);
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Image size exceeds maximum limit of ${(maxFileSize / (1024 * 1024)).toStringAsFixed(0)}MB.',
        );
      }

      // Check image dimensions using dart:io Image class
      final imageBytes = await file.readAsBytes();
      final decodedImage = await _decodeImage(imageBytes);
      
      if (decodedImage == null) {
        return const ImageValidationResult(
          isValid: false,
          errorMessage: 'Unable to read image. Please try a different image.',
        );
      }

      final width = decodedImage.width;
      final height = decodedImage.height;

      // Check minimum dimensions
      if (width < minWidth || height < minHeight) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Image dimensions must be at least ${minWidth}x${minHeight} pixels. Current: ${width}x${height}',
        );
      }

      // Check aspect ratio (1:1 square)
      final aspectRatio = width / height;
      const tolerance = 0.01; // Allow small tolerance for floating point errors
      if ((aspectRatio - 1.0).abs() > tolerance) {
        return ImageValidationResult(
          isValid: false,
          errorMessage: 'Image must be square (1:1 ratio). Current ratio: ${aspectRatio.toStringAsFixed(2)}:1',
        );
      }

      return const ImageValidationResult(isValid: true);
    } catch (e) {
      return ImageValidationResult(
        isValid: false,
        errorMessage: 'Error validating image: ${e.toString()}',
      );
    }
  }

  /// Validates multiple images
  static Future<List<ImageValidationResult>> validateImages(
    List<XFile> imageFiles,
  ) async {
    final results = <ImageValidationResult>[];
    for (var image in imageFiles) {
      final result = await validateImage(image);
      results.add(result);
    }
    return results;
  }

  /// Validates and shows toast message if invalid
  static Future<bool> validateAndShowToast(XFile imageFile) async {
    final result = await validateImage(imageFile);
    if (!result.isValid && result.errorMessage != null) {
      customToast(msg: result.errorMessage!);
    }
    return result.isValid;
  }

  /// Gets file extension from path
  static String _getFileExtension(String path) {
    return path.split('.').last.toLowerCase();
  }

  /// Decodes image to get dimensions using dart:ui
  static Future<({int width, int height})?> _decodeImage(
    List<int> imageBytes,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(
        Uint8List.fromList(imageBytes),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      
      final width = image.width;
      final height = image.height;
      
      // Dispose the image to free memory
      image.dispose();
      
      return (width: width, height: height);
    } catch (e) {
      return null;
    }
  }
}

