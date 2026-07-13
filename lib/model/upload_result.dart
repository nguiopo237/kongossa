/// Résultat d'upload avec validation
class UploadResult {
  final bool success;
  final String? publicId;
  final String? secureUrl;
  final String? resourceType;
  final String? format;
  final int bytes;
  final int? width;
  final int? height;
  final String? errorMessage;
  final String? errorCode;

  UploadResult({
    required this.success,
    this.publicId,
    this.secureUrl,
    this.resourceType,
    this.format,
    this.bytes = 0,
    this.width,
    this.height,
    this.errorMessage,
    this.errorCode,
  });

  factory UploadResult.success({
    required String publicId,
    required String secureUrl,
    required String resourceType,
    String? format,
    int bytes = 0,
    int? width,
    int? height,
  }) {
    if (publicId.isEmpty || secureUrl.isEmpty) {
      return UploadResult.error(
        message: 'Données manquantes dans le succès',
        code: 'INVALID_SUCCESS_DATA',
      );
    }

    return UploadResult(
      success: true,
      publicId: publicId,
      secureUrl: secureUrl,
      resourceType: resourceType,
      format: format,
      bytes: bytes,
      width: width,
      height: height,
    );
  }

  factory UploadResult.error({
    required String message,
    String? code,
  }) {
    return UploadResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }

  @override
  String toString() {
    if (success) {
      return '✅ UploadResult{publicId: $publicId, url: $secureUrl, type: $resourceType}';
    } else {
      return '❌ UploadResult{error: $errorMessage, code: $errorCode}';
    }
  }
}
