import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

/// Résultat d'un upload vers Cloudinary
class CloudinaryUploadResult {
  final bool success;
  final String? publicId;
  final String? secureUrl;
  final String? resourceType; // 'image', 'video', 'raw', 'auto'
  final String? format;
  final int? bytes;
  final int? width;
  final int? height;
  final double? duration;
  final Map<String, dynamic>? metadata;
  final String? errorMessage;
  final String? errorCode;

  CloudinaryUploadResult({
    required this.success,
    this.publicId,
    this.secureUrl,
    this.resourceType,
    this.format,
    this.bytes,
    this.width,
    this.height,
    this.duration,
    this.metadata,
    this.errorMessage,
    this.errorCode,
  });

  factory CloudinaryUploadResult.fromCloudinaryResponse(
      Map<String, dynamic> response) {
    return CloudinaryUploadResult(
      success: response['error'] == null,
      publicId: response['public_id'],
      secureUrl: response['secure_url'],
      resourceType: response['resource_type'],
      format: response['format'],
      bytes: response['bytes'],
      width: response['width'],
      height: response['height'],
      duration: response['duration']?.toDouble(),
      metadata: response,
    );
  }

  factory CloudinaryUploadResult.error(String message, {String? code}) {
    return CloudinaryUploadResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  @override
  String toString() {
    return 'CloudinaryUploadResult{success: $success, type: $resourceType, url: $secureUrl}';
  }
}
