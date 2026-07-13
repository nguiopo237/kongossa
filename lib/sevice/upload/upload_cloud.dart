import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../../config_App/env_config.dart';
import '../../model/upload_result.dart';

/// Unified Cloudinary service — merge of CloudinaryServicess + UniversalCloudinaryUploader
class UniversalCloudinaryUploader {
  // ─── Cloudinary Keys Set 2 (main UniversalCloudinaryUploader config) ───
  static String get cloudName => EnvConfig.cloudinaryCloudName;
  static String get apiKey => EnvConfig.cloudinaryApiKey2;
  static String get apiSecret => EnvConfig.cloudinaryApiSecret2;

  // ─── Cloudinary Keys Set 1 (ex‑CloudinaryServicess) ───
  static String get apiKey1 => EnvConfig.cloudinaryApiKey1;
  static String get apiSecret1 => EnvConfig.cloudinaryApiSecret1;
  static String get apiEnv => EnvConfig.cloudinaryUrl;

  /// Signed instance with Set 2 keys (detailed calls, retry, etc.)
  late final Cloudinary _cloudinary;

  /// Signed instance with Set 1 keys (ex‑CloudinaryServicess._cloudinaryFull)
  late final Cloudinary _cloudinarySigned;

  /// Unsigned instance (ex‑CloudinaryServicess._cloudinary)
  late final Cloudinary _cloudinaryUnsigned;

  UniversalCloudinaryUploader()
      : _cloudinary = Cloudinary.signedConfig(
          cloudName: cloudName,
          apiKey: apiKey,
          apiSecret: apiSecret,
        ),
        _cloudinarySigned = Cloudinary.signedConfig(
          apiKey: apiKey1,
          apiSecret: apiSecret1,
          cloudName: cloudName,
        ),
        _cloudinaryUnsigned = Cloudinary.unsignedConfig(
          cloudName: cloudName,
        );

  // ═══════════════════════════════════════════════════════════════════════
  // Methods from ex‑UniversalCloudinaryUploader
  // ═══════════════════════════════════════════════════════════════════════

  /// Upload a file (delegates to signed upload Set 1)
  Future<dynamic> uploadAnyFile({
    required String filePath,
    required String folder,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('🚀 Starting upload to Cloudinary Kongossa');
      debugPrint('📁 Chemin fichier: $filePath');
      debugPrint('📂 Dossier destination: $folder');

      final file = File(filePath);
      if (!await file.exists()) {
        return UploadResult.error(
          message: 'Fichier introuvable: $filePath',
          code: 'FILE_NOT_FOUND',
        );
      }

      final resourceType = detectResourceType(filePath);
      debugPrint('🎯 Detected type: ${resourceTypeToString(resourceType)}');

      final isImage = resourceTypeToString(resourceType) == 'image';

      debugPrint('📤 Envoi vers Cloudinary...');
      final response = await uploadImageSigned(
        imageFile: file,
        isimage: isImage,
      );
      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur upload: $e');
      debugPrint('📝 StackTrace: $stackTrace');
      return UploadResult.error(
        message: 'Erreur: ${e.toString()}',
        code: 'UPLOAD_EXCEPTION',
      );
    }
  }

  /// Upload with detailed error handling (Set 2)
  Future<CloudinaryResponse> _uploadWithDetailedErrorHandling({
    required String filePath,
    required String fileName,
    required String folder,
    required CloudinaryResourceType resourceType,
    Function(double)? onProgress,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('📤 Tentative $attempt/$maxRetries');

        final options = _getCloudinaryOptions(resourceType);

        debugPrint('📋 Upload params:');
        debugPrint('   - CloudName: $cloudName');
        debugPrint('   - Dossier: $folder');
        debugPrint('   - Nom fichier: $fileName');
        debugPrint('   - Type: ${resourceTypeToString(resourceType)}');
        debugPrint('   - Options: $options');

        final response = await _cloudinary.upload(
          file: filePath,
          fileName: fileName,
          folder: folder,
          resourceType: resourceType,
          optParams: options,
          progressCallback: onProgress != null
              ? (count, total) {
                  if (total != null) {
                    onProgress(count / total);
                  }
                }
              : null,
        );

        if (!response.isResultOk) {
          throw Exception(
              'Cloudinary a retourné une erreur: ${response.error}');
        }

        return response;
      } on DioException catch (dioError) {
        debugPrint('⚠️ Erreur Dio (tentative $attempt):');
        debugPrint('   Code: ${dioError.response?.statusCode}');
        debugPrint('   Message: ${dioError.message}');
        debugPrint('   Data: ${dioError.response?.data}');

        if (dioError.response?.statusCode == 400) {
          _analyze400Error(
              dioError, filePath, folder, fileName, resourceType);
        }

        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint('⚠️ Autre erreur (tentative $attempt): $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Toutes les tentatives ont échoué');
  }

  void _analyze400Error(
    DioException error,
    String filePath,
    String folder,
    String fileName,
    CloudinaryResourceType resourceType,
  ) {
    debugPrint('🔍 Analyse erreur 400 Cloudinary:');
    final responseData = error.response?.data;
    if (responseData != null) {
      debugPrint('   Cloudinary response: $responseData');
    }

    debugPrint('   ✅ Checks:');
    final file = File(filePath);
    final fileSize = file.lengthSync();
    debugPrint(
        '   - Taille fichier: ${fileSize} bytes (${fileSize / 1024 / 1024} MB)');
    if (fileSize > 100 * 1024 * 1024) {
      debugPrint('   ❌ Fichier trop volumineux (> 100MB)');
    }

    final extension = path.extension(filePath).toLowerCase();
    final mimeType = lookupMimeType(filePath);
    debugPrint('   - Extension: $extension');
    debugPrint('   - MIME Type: $mimeType');

    if (fileName.contains(RegExp(r'[^a-zA-Z0-9_\-.]'))) {
      debugPrint('   ❌ Filename contains special characters: $fileName');
    }

    if (folder.contains('//') || folder.startsWith('/') || folder.endsWith('/')) {
      debugPrint('   ❌ Format dossier incorrect: $folder');
    }

    final expectedType = detectResourceType(filePath);
    if (resourceType != expectedType) {
      debugPrint(
          '   ❌ Type mismatch: envoyé ${resourceTypeToString(resourceType)}, '
          'attendu ${resourceTypeToString(expectedType)}');
    }
  }

  Map<String, dynamic> _getCloudinaryOptions(CloudinaryResourceType resourceType) {
    final Map<String, dynamic> options = {};

    switch (resourceType) {
      case CloudinaryResourceType.image:
        options['transformation'] = 'q_auto,f_auto';
        options['colors'] = true;
        break;
      case CloudinaryResourceType.video:
        options['resource_type'] = 'video';
        options['transformation'] = 'q_auto';
        options['video_codec'] = 'h264';
        break;
      case CloudinaryResourceType.raw:
        options['access_mode'] = 'authenticated';
        break;
      case CloudinaryResourceType.auto:
        options['transformation'] = 'q_auto';
        break;
    }

    options['use_filename'] = true;
    options['unique_filename'] = false;
    options['overwrite'] = false;

    return options;
  }

  UploadResult _parseCloudinaryResponse(
    CloudinaryResponse response,
    CloudinaryResourceType resourceType,
  ) {
    try {
      debugPrint('📥 Cloudinary response received');
      debugPrint('   Success: ${response.isResultOk}');
      debugPrint('   PublicId: ${response.publicId}');
      debugPrint('   SecureUrl: ${response.secureUrl}');
      debugPrint('   Format: ${response.format}');
      debugPrint('   Bytes: ${response.bytes}');

      if (!response.isResultOk) {
        return UploadResult.error(
          message: 'Cloudinary error: ${response.error ?? "Unknown error"}',
          code: 'CLOUDINARY_ERROR',
        );
      }

      if (response.publicId == null || response.secureUrl == null) {
        return UploadResult.error(
          message: 'Réponse Cloudinary incomplète',
          code: 'INCOMPLETE_RESPONSE',
        );
      }

      return UploadResult.success(
        publicId: response.publicId!,
        secureUrl: response.secureUrl!,
        resourceType: resourceTypeToString(resourceType),
        format: response.format,
        bytes: response.bytes ?? 0,
        width: response.width,
        height: response.height,
      );
    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      return UploadResult.error(
        message: 'Erreur traitement réponse: $e',
        code: 'RESPONSE_PARSING_ERROR',
      );
    }
  }

  static Future<bool> deleteVideoUsingApi(
      String publicId, Cloudinary cloudinary, url) async {
    debugPrint(url);
    try {
      final response = await cloudinary.destroy(
        publicId,
        resourceType: CloudinaryResourceType.video,
        url: url,
      );
      debugPrint('response.result');
      debugPrint(response.result);
      debugPrint('response.result');
      return response.isResultOk;
    } catch (e) {
      debugPrint('Erreur suppression: $e');
      return false;
    }
  }

  static String extractPublicId({String? url}) {
    final patterns = [
      RegExp(r'upload/(?:v\d+/)?(.+)'),
      RegExp(r'image/upload/(?:v\d+/)?(.+)'),
      RegExp(r'video/upload/(?:v\d+/)?(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url!);
      if (match != null && match.groupCount >= 1) {
        final publicId = match.group(1)!;
        debugPrint('publicId.replaceAll(');
        debugPrint(publicId.replaceAll(RegExp(r'\.\w+$'), ''));
        debugPrint('publicId.replaceAll(Reg');
        return publicId.replaceAll(RegExp(r'\.\w+$'), '');
      }
    }

    return '';
  }

  static CloudinaryResourceType detectResourceType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final mimeType = lookupMimeType(filePath);      debugPrint('🔍 Detection: extension=$extension, mimeType=$mimeType');

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.svg',
            '.heic']
        .contains(extension)) {
      return CloudinaryResourceType.image;
    }

    if (['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v']
        .contains(extension)) {
      return CloudinaryResourceType.video;
    }

    if (['.pdf', '.doc', '.docx', '.txt', '.zip', '.rar', '.mp3', '.wav']
        .contains(extension)) {
      return CloudinaryResourceType.raw;
    }

    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return CloudinaryResourceType.image;
      if (mimeType.startsWith('video/')) return CloudinaryResourceType.video;
    }

    return CloudinaryResourceType.auto;
  }

  static String resourceTypeToString(CloudinaryResourceType type) {
    switch (type) {
      case CloudinaryResourceType.image:
        return 'image';
      case CloudinaryResourceType.video:
        return 'video';
      case CloudinaryResourceType.raw:
        return 'raw';
      case CloudinaryResourceType.auto:
        return 'auto';
    }
  }

  Future<UploadResult> uploadSimpleTest() async {
    try {
      debugPrint('🧪 Testing simple upload...');
      final testFile = await _createTestFile();

      final response = await _cloudinary.upload(
        file: testFile.path,
        folder: 'test-uploads',
        fileName:
            'test_simple_${DateTime.now().millisecondsSinceEpoch}.txt',
        resourceType: CloudinaryResourceType.raw,
        optParams: {'transformation': 'q_auto'},
      );

      debugPrint('Test response: ${response.isResultOk}');
      debugPrint('Test publicId: ${response.publicId}');
      debugPrint('Test secureUrl: ${response.secureUrl}');

      if (response.isResultOk && response.publicId != null) {
        return UploadResult.success(
          publicId: response.publicId!,
          secureUrl: response.secureUrl ?? 'No URL',
          resourceType: 'raw',
        );
      } else {
        return UploadResult.error(
          message: 'Test failed: ${response.error}',
          code: 'TEST_FAILED',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Test failed: $e');
      debugPrint('📝 StackTrace: $stackTrace');
      return UploadResult.error(message: 'Test error: $e', code: 'TEST_ERROR');
    }
  }

  Future<File> _createTestFile() async {
    final tempDir = await Directory.systemTemp.createTemp('cloudinary_test');
    final testFile = File('${tempDir.path}/test.txt');
    await testFile.writeAsString(
        'Test file for Cloudinary upload - ${DateTime.now()}');
    return testFile;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Methods from ex‑CloudinaryServicess
  // ═══════════════════════════════════════════════════════════════════════

  /// Simple unsigned upload (Set 1)
  Future<String> uploadImageSimple(File imageFile) async {
    try {
      final response = await _cloudinaryUnsigned.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app',
        fileName: 'img_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful) {
        debugPrint('✅ Image uploaded: ${response.secureUrl}');
        return response.secureUrl!;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      rethrow;
    }
  }

  /// Upload avec transformations (Set 1)
  Future<String> uploadImageWithTransformations(File imageFile) async {
    try {
      final response = await _cloudinaryUnsigned.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app',
        fileName: 'optimized_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return _addTransformationsToUrl(response.secureUrl!);
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  String _addTransformationsToUrl(String originalUrl) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_800,h_600,c_fill,q_auto,f_auto/',
    );
  }

  /// Signed upload (Set 1) — used by `uploadAnyFile()`
  Future<String> uploadImageSigned({
    File? imageFile,
    bool isimage = true,
    String? fileExtension,
  }) async {
    try {
      if (imageFile == null || !await imageFile.exists()) {
        throw Exception('Fichier introuvable ou invalide');
      }

      final extension =
          fileExtension ?? path.extension(imageFile.path).toLowerCase();        debugPrint('📤 Starting signed upload');
      debugPrint('📁 Chemin: ${imageFile.path}');
      debugPrint('🔍 Extension: $extension');
      debugPrint('🖼️ Est image: $isimage');
      debugPrint('☁️ Cloud Name: ${_cloudinarySigned.cloudName}');
      debugPrint('🔑 API Key: ${_cloudinarySigned.apiKey}');

      final resourceType = (isimage == true)
          ? CloudinaryResourceType.image
          : CloudinaryResourceType.video;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'signed_$timestamp$extension';

      final response = await _cloudinarySigned.upload(
        file: imageFile.path,
        resourceType: resourceType,
        folder: 'kogossa_app/secure',
        fileName: fileName,
      );

      if (response.isSuccessful) {
        debugPrint('✅ Signed upload successful!');
        debugPrint('🔗 URL: ${response.secureUrl}');
        debugPrint('🆔 Public ID: ${response.publicId}');
        final publicId = response.publicId;
        debugPrint('📋 ID Public extrait: $publicId');
        return response.secureUrl!;
      } else {
        debugPrint('❌ Upload failed: ${response.error}');
        throw Exception('Upload signé échoué: ${response.error}');
      }
    } catch (e) {
      debugPrint('🔥 Erreur lors de l\'upload: $e');
      debugPrint('📝 Stack trace: ${e.toString()}');
      throw Exception('Échec de l\'upload signé: $e');
    }
  }

  /// Upload depuis une URL (Set 1)
  Future<String> uploadFromUrl(String imageUrl) async {
    try {
      final response = await _cloudinaryUnsigned.upload(
        file: imageUrl,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app/url_uploads',
        fileName: 'from_url_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful) {
        return response.secureUrl!;
      } else {
        throw Exception('Upload from URL failed: ${response.error}');
      }
    } catch (e) {
      throw Exception('Upload from URL failed: $e');
    }
  }

  /// Generate an optimized URL
  String getOptimizedUrl(String originalUrl,
      {int width = 400, int height = 400}) {
    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) return originalUrl;

      final version = pathSegments[0];
      final cloudName = uri.host.split('.')[0];
      final publicId = pathSegments.sublist(1).join('/');
      final cleanPublicId =
          publicId.replaceAll(RegExp(r'\.(jpg|jpeg|png|gif|webp)$'), '');

      return 'https://res.cloudinary.com/$cloudName/image/upload/'
          'w_$width,h_$height,c_fill,q_auto,f_auto/'
          '$version/$cleanPublicId';
    } catch (e) {
      debugPrint('❌ Error generating optimized URL: $e');
      return originalUrl;
    }
  }

  /// Supprimer une image par URL
  Future<bool> deleteImage(String imageUrl) async {
    debugPrint('🗑️ Suppression de url : $imageUrl');
    try {
      final publicId = extractPublicIdFromUrl(imageUrl);
      debugPrint('🗑️ Deleting public ID: $publicId');

      if (publicId.isEmpty) {
        debugPrint('❌ Impossible d\'extraire publicId de l\'URL');
        return false;
      }

      final response = await _cloudinaryUnsigned.destroy(
        publicId,
        resourceType: CloudinaryResourceType.auto,
        invalidate: true,
      );

      return response.isSuccessful;
    } catch (e) {
      debugPrint('❌ Erreur suppression: $e');
      return false;
    }
  }

  /// Extract Public ID from a Cloudinary URL (instance method)
  String extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) return '';

      final folderAndFile = pathSegments.sublist(1).join('/');
      return folderAndFile.replaceAll(RegExp(r'\.[^/.]+$'), '');
    } catch (e) {
      return '';
    }
  }

  /// Upload avec callback de progression
  Future<String> uploadWithProgress(
    File imageFile,
    void Function(double) onProgress,
  ) async {
    try {
      onProgress(0.1);

      final response = await _cloudinaryUnsigned.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app',
        fileName: 'progress_${DateTime.now().millisecondsSinceEpoch}',
      );

      onProgress(1.0);

      if (response.isSuccessful) {
        return response.secureUrl!;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      throw Exception('Upload with progress failed: $e');
    }
  }
}
