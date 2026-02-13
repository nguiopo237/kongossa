import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:kongossa/sevice/upload/upload_compress_image.dart';


import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class UniversalCloudinaryUploader {
  static const String cloudName = "dlzkp9dix";
  static const String apiKey = "468428679726544";
  static const String apiSecret = "iJqDz8I055efjaxVJndcSInifVU";
  CloudinaryServicess item=  CloudinaryServicess();
  late final Cloudinary _cloudinary;




  UniversalCloudinaryUploader()
      : _cloudinary = Cloudinary.signedConfig(
    cloudName: cloudName,
    apiKey: apiKey,
    apiSecret: apiSecret,
  );

 static Future<bool> deleteVideoUsingApi(String publicId,Cloudinary cloudinary,url) async {
   print(url);
    try {
      // Utiliser l'API admin via le SDK
      final response = await cloudinary.destroy(
        publicId,
          // invalidate: false,
        resourceType: CloudinaryResourceType.video,
        url: url
      );
      print("response.result");
      print(response.result);
      print(response.isSuccessful);
      print("response.result");
      return response.isResultOk;
    } catch (e) {
      print('Erreur suppression: $e');
      return false;
    }
  }

  static  String extractPublicId({String? url}) {
    // Patterns d'URL Cloudinary
   // url = "https://res.cloudinary.com/dlzkp9dix/image/upload/v1770582958/kogossa_app/secure/signed_1770582940348..jpg.jpg";
   // url = "https://res.cloudinary.com/dlzkp9dix/video/upload/v1770580345/kogossa_app/secure/signed_1770580280886..mp4.mp4";
    final patterns = [
      RegExp(r'upload/(?:v\d+/)?(.+)'),
      RegExp(r'image/upload/(?:v\d+/)?(.+)'),
      RegExp(r'video/upload/(?:v\d+/)?(.+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url!);
      if (match != null && match.groupCount >= 1) {
        final publicId = match.group(1)!;
        // Retirer l'extension du fichier
        print("publicId.replaceAll(");
        print(publicId.replaceAll(RegExp(r'\.\w+$'), ''));
        print("publicId.replaceAll(Reg");
        // deleteVideoUsingApi(publicId.replaceAll(RegExp(r'\.\w+$'), ''),Cloudinary.signedConfig(
        //   cloudName: cloudName,
        //   apiKey: apiKey,
        //   apiSecret: apiSecret,
        // ),url);
        return publicId.replaceAll(RegExp(r'\.\w+$'), '');
      }
    }

    return '';
  }
  /// === FONCTION D'UPLOAD CORRIGÉE ===
   uploadAnyFile({
    required String filePath,
    required String folder,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      print('🚀 Début upload vers Cloudinary Kongossa');
      print('📁 Chemin fichier: $filePath');
      print('📂 Dossier destination: $folder');

      // 1. Vérifier que le fichier existe
      final file = File(filePath);
      if (!await file.exists()) {
        return UploadResult.error(
          message: 'Fichier introuvable: $filePath',
          code: 'FILE_NOT_FOUND',
        );
      }

      // 2. Détecter le type de fichier
      final resourceType = detectResourceType(filePath);
      print('🎯 Type détecté: ${resourceTypeToString(resourceType)}');

      // 3. Préparer le nom de fichier
      final finalFileName = fileName ??
          '${path.basenameWithoutExtension(filePath)}_${DateTime.now().millisecondsSinceEpoch}';

      // 4. Upload avec gestion d'erreurs Cloudinary
      print('📤 Envoi vers Cloudinary...');
      print(resourceTypeToString(resourceType)=="image");
      // await services.uploadImageSigned(File(filePath));

  final response = await item.uploadImageSigned(imageFile: file,isimage: resourceTypeToString(resourceType)=="image"?true:false);
 return response;
    } catch (e, stackTrace) {
      print('❌ Erreur upload: $e');
      print('📝 StackTrace: $stackTrace');

      return UploadResult.error(
        message: 'Erreur: ${e.toString()}',
        code: 'UPLOAD_EXCEPTION',
      );
    }
  }




  /// Upload avec gestion d'erreurs détaillée
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
        print('📤 Tentative $attempt/$maxRetries');

        // Options spécifiques selon le type
        final options = _getCloudinaryOptions(resourceType);

        // Log des paramètres pour debug
        print('📋 Paramètres upload:');
        print('   - CloudName: $cloudName');
        print('   - Dossier: $folder');
        print('   - Nom fichier: $fileName');
        print('   - Type: ${resourceTypeToString(resourceType)}');
        print('   - Options: $options');

        // Upload
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

        // Vérifier le résultat IMMÉDIATEMENT
        if (!response.isResultOk) {
          throw Exception('Cloudinary a retourné une erreur: ${response.error}');
        }

        return response;

      } on DioException catch (dioError) {
        print('⚠️ Erreur Dio (tentative $attempt):');
        print('   Code: ${dioError.response?.statusCode}');
        print('   Message: ${dioError.message}');
        print('   Data: ${dioError.response?.data}');

        // Analyser l'erreur 400 spécifique
        if (dioError.response?.statusCode == 400) {
          _analyze400Error(dioError, filePath, folder, fileName, resourceType);
        }

        if (attempt == maxRetries) {
          rethrow;
        }

        // Attente exponentielle
        await Future.delayed(Duration(seconds: attempt * 2));

      } catch (e) {
        print('⚠️ Autre erreur (tentative $attempt): $e');

        if (attempt == maxRetries) {
          rethrow;
        }

        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    throw Exception('Toutes les tentatives ont échoué');
  }

  /// Analyser l'erreur 400 de Cloudinary
  void _analyze400Error(
      DioException error,
      String filePath,
      String folder,
      String fileName,
      CloudinaryResourceType resourceType,
      ) {
    print('🔍 Analyse erreur 400 Cloudinary:');

    // Vérifier les données de réponse
    final responseData = error.response?.data;
    if (responseData != null) {
      print('   Réponse Cloudinary: $responseData');
    }

    // Causes courantes d'erreur 400:
    print('   ✅ Vérifications:');

    // 1. Taille du fichier
    final file = File(filePath);
    final fileSize = file.lengthSync();
    print('   - Taille fichier: ${fileSize} bytes (${fileSize / 1024 / 1024} MB)');
    if (fileSize > 100 * 1024 * 1024) {
      print('   ❌ Fichier trop volumineux (> 100MB)');
    }

    // 2. Extension vs type MIME
    final extension = path.extension(filePath).toLowerCase();
    final mimeType = lookupMimeType(filePath);
    print('   - Extension: $extension');
    print('   - MIME Type: $mimeType');

    // 3. Caractères spéciaux dans le nom
    if (fileName.contains(RegExp(r'[^a-zA-Z0-9_\-.]'))) {
      print('   ❌ Nom fichier contient caractères spéciaux: $fileName');
    }

    // 4. Format de dossier
    if (folder.contains('//') || folder.startsWith('/') || folder.endsWith('/')) {
      print('   ❌ Format dossier incorrect: $folder');
    }

    // 5. Type de ressource vs extension
    final expectedType = detectResourceType(filePath);
    if (resourceType != expectedType) {
      print('   ❌ Type mismatch: envoyé ${resourceTypeToString(resourceType)}, '
          'attendu ${resourceTypeToString(expectedType)}');
    }
  }

  /// Options Cloudinary selon le type
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

    // Options communes
    options['use_filename'] = true;
    options['unique_filename'] = false;
    options['overwrite'] = false;

    return options;
  }

  /// Parser la réponse Cloudinary
  UploadResult _parseCloudinaryResponse(
      CloudinaryResponse response,
      CloudinaryResourceType resourceType,
      ) {
    try {
      print('📥 Réponse Cloudinary reçue');
      print('   Success: ${response.isResultOk}');
      print('   PublicId: ${response.publicId}');
      print('   SecureUrl: ${response.secureUrl}');
      print('   Format: ${response.format}');
      print('   Bytes: ${response.bytes}');

      if (!response.isResultOk) {
        return UploadResult.error(
          message: 'Cloudinary error: ${response.error ?? "Unknown error"}',
          code: 'CLOUDINARY_ERROR',
        );
      }

      // Vérifier que les données essentielles sont présentes
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
      print('❌ Erreur parsing réponse: $e');
      return UploadResult.error(
        message: 'Erreur traitement réponse: $e',
        code: 'RESPONSE_PARSING_ERROR',
      );
    }
  }

  /// Détecter le type de ressource
 static CloudinaryResourceType detectResourceType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    final mimeType = lookupMimeType(filePath);

    print('🔍 Détection: extension=$extension, mimeType=$mimeType');

    // Images
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.tiff', '.svg', '.heic']
        .contains(extension)) {
      return CloudinaryResourceType.image;
    }

    // Vidéos
    if (['.mp4', '.mov', '.avi', '.mkv', '.webm', '.flv', '.wmv', '.m4v']
        .contains(extension)) {
      return CloudinaryResourceType.video;
    }

    // Documents et autres
    if (['.pdf', '.doc', '.docx', '.txt', '.zip', '.rar', '.mp3', '.wav']
        .contains(extension)) {
      return CloudinaryResourceType.raw;
    }

    // Auto-détection par MIME
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) return CloudinaryResourceType.image;
      if (mimeType.startsWith('video/')) return CloudinaryResourceType.video;
    }

    return CloudinaryResourceType.auto;
  }

  /// Convertir type en string
  static String resourceTypeToString(CloudinaryResourceType type) {
    switch (type) {
      case CloudinaryResourceType.image: return 'image';
      case CloudinaryResourceType.video: return 'video';
      case CloudinaryResourceType.raw: return 'raw';
      case CloudinaryResourceType.auto: return 'auto';
    }
  }

  /// Méthode alternative: upload simple pour tester
  Future<UploadResult> uploadSimpleTest() async {
    try {
      print('🧪 Test upload simple...');

      // Créer un fichier test minimal
      final testFile = await _createTestFile();

      final response = await _cloudinary.upload(
        file: testFile.path,
        folder: 'test-uploads',
        fileName: 'test_simple_${DateTime.now().millisecondsSinceEpoch}.txt',
        resourceType: CloudinaryResourceType.raw,
        optParams: {
          'transformation': 'q_auto',
        },
      );

      print('Test réponse: ${response.isResultOk}');
      print('Test publicId: ${response.publicId}');
      print('Test secureUrl: ${response.secureUrl}');

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
      print('❌ Test échoué: $e');
      print('📝 StackTrace: $stackTrace');
      return UploadResult.error(message: 'Test error: $e', code: 'TEST_ERROR');
    }
  }

  /// Créer un fichier test
  Future<File> _createTestFile() async {
    final tempDir = await Directory.systemTemp.createTemp('cloudinary_test');
    final testFile = File('${tempDir.path}/test.txt');

    await testFile.writeAsString('Test file for Cloudinary upload - ${DateTime.now()}');

    return testFile;
  }
}

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
  // final  Cloudinary ?cloudinary;

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
    // VALIDATION: vérifier que les données essentielles sont présentes
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
    print('❌ UploadResult.error: $message (code: $code)');

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




  /// Récupérer publicId depuis l'URL Cloudinary
  String getPublicIdFromUrl(String url) {
      url = "https://res.cloudinary.com/dlzkp9dix/image/upload/v1770582958/kogossa_app/secure/signed_1770582940348..jpg.jpg";
    try {
      // Exemple d'URL: https://res.cloudinary.com/cloudname/video/upload/v1234567/folder/video.mp4
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      // Trouver l'index de 'upload'
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex + 1 < pathSegments.length) {
        // Tout après 'upload/' est le publicId
        final publicIdParts = pathSegments.sublist(uploadIndex + 1);
        return publicIdParts.join('/');
      }

      return '';
    } catch (e) {
      print('Erreur parsing URL: $e');
      return '';
    }
  }

  /// Version améliorée




}