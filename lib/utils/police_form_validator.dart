import 'dart:io';

/// Police form validation utilities
class PoliceFormValidator {
  /// Validate description field
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 5000) {
      return 'Description must be less than 5000 characters';
    }
    return null;
  }

  /// Validate address field
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (value.trim().length > 500) {
      return 'Address must be less than 500 characters';
    }
    return null;
  }

  /// Validate latitude
  static String? validateLatitude(double? latitude) {
    if (latitude == null) {
      return 'Location is required';
    }
    if (latitude < -90 || latitude > 90) {
      return 'Invalid latitude coordinates';
    }
    return null;
  }

  /// Validate longitude
  static String? validateLongitude(double? longitude) {
    if (longitude == null) {
      return 'Location is required';
    }
    if (longitude < -180 || longitude > 180) {
      return 'Invalid longitude coordinates';
    }
    return null;
  }

  /// Validate media file
  static Future<String?> validateMediaFile(File? file) async {
    if (file == null) {
      return null; // Media is optional
    }

    // Check if file exists
    if (!await file.exists()) {
      return 'Selected file does not exist';
    }

    // Check file size (max 10MB)
    final fileSize = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10MB in bytes
    
    if (fileSize > maxSize) {
      final sizeMB = (fileSize / 1024 / 1024).toStringAsFixed(1);
      return 'File too large ($sizeMB MB). Maximum size is 10MB';
    }

    // Check file extension
    final extension = file.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'mp4'];
    
    if (!allowedExtensions.contains(extension)) {
      return 'Invalid file type. Allowed: JPG, PNG, MP4';
    }

    return null; // Valid file
  }

  /// Get human-readable file size
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
  }

  /// Check if all required fields are valid for submission
  static bool isFormValid({
    required String description,
    required String address,
    required double? latitude,
    required double? longitude,
    File? media,
  }) {
    return validateDescription(description) == null &&
           validateAddress(address) == null &&
           validateLatitude(latitude) == null &&
           validateLongitude(longitude) == null;
  }

  /// Get comprehensive form validation errors
  static Future<Map<String, String>> getFormErrors({
    required String description,
    required String address,
    required double? latitude,
    required double? longitude,
    File? media,
  }) async {
    final errors = <String, String>{};

    final descError = validateDescription(description);
    if (descError != null) errors['description'] = descError;

    final addressError = validateAddress(address);
    if (addressError != null) errors['address'] = addressError;

    final latError = validateLatitude(latitude);
    if (latError != null) errors['latitude'] = latError;

    final lngError = validateLongitude(longitude);
    if (lngError != null) errors['longitude'] = lngError;

    final mediaError = await validateMediaFile(media);
    if (mediaError != null) errors['media'] = mediaError;

    return errors;
  }
}
