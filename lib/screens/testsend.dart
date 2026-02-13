import 'dart:io';

import 'package:http/http.dart' as http;

import '../sevice/upload/upload_cloud.dart';

class CloudinaryService {
  // ... autres méthodes ...

  Future<bool> testConnection() async {
    try {
      // Tester avec une requête simple
      final response = await http.get(
        Uri.parse('https://res.cloudinary.com/demo/image/upload/sample.jpg'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Test connexion échoué: $e');
      return false;
    }
  }

  Future<UploadResult> uploadImageFromFile({
    required String filePath,
    required String folder,
    String? fileName,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return UploadResult(
          success: false,
          errorMessage: 'Fichier introuvable',
        );
      }

      // Lire le fichier
      final bytes = await file.readAsBytes();

      // Simuler la progression
      if (onProgress != null) {
        onProgress(0.3); // 30%
      }

      // Ici, vous devez implémenter le vrai upload vers Cloudinary
      // En attendant, simuler un upload réussi
      await Future.delayed(Duration(seconds: 2));

      if (onProgress != null) {
        onProgress(0.7); // 70%
      }

      // Générer une URL de démo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '$folder/${fileName ?? 'image-$timestamp'}';

      // Simuler fin d'upload
      if (onProgress != null) {
        onProgress(1.0); // 100%
      }

      await Future.delayed(Duration(milliseconds: 500));

      return UploadResult(
        success: true,
        publicId: publicId,
        secureUrl: 'https://res.cloudinary.com/demo/image/upload/w_800,h_600,c_fill/$publicId.jpg',
        bytes: bytes.length,
        width: 800,
        height: 600,
        format: 'jpg',
      );

    } catch (e) {
      return UploadResult(
        success: false,
        errorMessage: 'Erreur: $e',
      );
    }
  }

  Future<bool> deleteImage(String publicId) async {
    // Implémenter la suppression réelle vers Cloudinary
    await Future.delayed(Duration(seconds: 1));
    return true; // Simuler succès
  }

  Future<List<CloudinaryResource>> listImagesInFolder({
    required String folder,
    int maxResults = 50,
  }) async {
    // Implémenter la récupération réelle depuis Cloudinary
    await Future.delayed(Duration(seconds: 1));

    // Simuler des résultats
    return List.generate(12, (index) {
      return CloudinaryResource(
        publicId: '$folder/image-$index',
        secureUrl: 'https://res.cloudinary.com/demo/image/upload/w_400,h_300,c_fill/$folder/image-$index.jpg',
        format: 'jpg',
        bytes: 1024 * (index + 1),
        width: 400,
        height: 300,
        createdAt: DateTime.now().subtract(Duration(days: index)),
        folder: folder,
        resourceType: 'image',
      );
    });
  }

  String getOptimizedUrl(String url, {int? width, int? height}) {
    // Si c'est déjà une URL Cloudinary, ajouter les transformations
    if (url.contains('res.cloudinary.com')) {
      final uri = Uri.parse(url);
      final path = uri.path;

      // Extraire le publicId
      final uploadIndex = path.indexOf('/upload/');
      if (uploadIndex != -1) {
        var afterUpload = path.substring(uploadIndex + '/upload/'.length);

        // Construire les nouvelles transformations
        final transforms = <String>[];
        if (width != null) transforms.add('w_$width');
        if (height != null) transforms.add('h_$height');
        transforms.add('c_fill');
        transforms.add('q_auto');
        transforms.add('f_auto');

        final transformStr = transforms.join(',');

        return 'https://${uri.host}/image/upload/$transformStr/${afterUpload.split('/').last}';
      }
    }

    // Sinon, retourner l'URL telle quelle
    return url;
  }

  String extractPublicIdFromUrl(String url) {
    if (url.contains('res.cloudinary.com')) {
      final uri = Uri.parse(url);
      final pathParts = uri.path.split('/');

      // Trouver l'index de 'upload'
      final uploadIndex = pathParts.indexWhere((part) => part == 'upload');
      if (uploadIndex != -1 && uploadIndex + 1 < pathParts.length) {
        return pathParts.sublist(uploadIndex + 1).join('/');
      }
    }

    return url;
  }
}

class UploadResults {
  final bool success;
  final String? publicId;
  final String? secureUrl;
  final String? errorMessage;
  final int? bytes;
  final int? width;
  final int? height;
  final String? format;

  UploadResults({
    required this.success,
    this.publicId,
    this.secureUrl,
    this.errorMessage,
    this.bytes,
    this.width,
    this.height,
    this.format,
  });
}

class CloudinaryResource {
  final String publicId;
  final String secureUrl;
  final String format;
  final int bytes;
  final int width;
  final int height;
  final DateTime createdAt;
  final String? folder;
  final String? resourceType;

  CloudinaryResource({
    required this.publicId,
    required this.secureUrl,
    required this.format,
    required this.bytes,
    required this.width,
    required this.height,
    required this.createdAt,
    this.folder,
    this.resourceType,
  });
}