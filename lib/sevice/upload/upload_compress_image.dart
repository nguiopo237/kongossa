import 'dart:io';
import 'package:cloudinary/cloudinary.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kongossa/sevice/upload/upload_cloud.dart';
import 'package:path/path.dart' as path;

import '../../config_App/environnement.dart';

class CloudinaryServicess {
  // Configuration Cloudinary - VERSION CORRIGÉE

 static String cloudName = "dlzkp9dix";
 static String APIkey = "159775225955892";
 static String APIsecret = "Uu59oh6fY-G2FCA5Yvpvq0b4JYI";
 static  String APIenv = "CLOUDINARY_URL=cloudinary://468428679726544:iJqDz8I055efjaxVJndcSInifVU@dlzkp9dix";





 final Cloudinary _cloudinary = Cloudinary.unsignedConfig(
   cloudName: '${cloudName}', // cloudName seulement

  );

  // Configuration complète (si besoin d'upload signé)
  final Cloudinary _cloudinaryFull = Cloudinary.signedConfig(

    apiKey: '${Env.APIkey}',    // apiKey
    apiSecret: '${Env.APIsecret}', // apiSecret
    cloudName: '${cloudName}', // cloudName
  );

  // 1. Upload simple (non signé - pour frontend) - CORRIGÉ
  Future<String> uploadImageSimple(File imageFile) async {
    try {
      final response = await _cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app',
        fileName: 'img_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful) {
        print('✅ Image uploaded: ${response.secureUrl}');
        return response.secureUrl!;
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // 2. Upload avec transformations - CORRIGÉ
  Future<String> uploadImageWithTransformations(File imageFile) async {
    try {
      final response = await _cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.image,
        folder: 'kogossa_app',
        fileName: 'optimized_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.isSuccessful && response.secureUrl != null) {
        // Ajouter les transformations à l'URL après upload
        return _addTransformationsToUrl(response.secureUrl!);
      } else {
        throw Exception('Upload failed: ${response.error}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  // Méthode pour ajouter des transformations à l'URL
  String _addTransformationsToUrl(String originalUrl) {
    // Transformations en temps réel via URL
    final cloudinaryUrl = originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_800,h_600,c_fill,q_auto,f_auto/',
    );
    return cloudinaryUrl;
  }

  // 3. Upload signé (plus sécurisé) - CORRIGÉ
 Future<String> uploadImageSigned({
   File? imageFile,
   bool isimage = true,
   String? fileExtension, // Renommé pour éviter conflit
 }) async
 {
   try {
     // Validation du fichier
     if (imageFile == null || !await imageFile.exists()) {
       throw Exception('Fichier introuvable ou invalide');
     }

     // Déterminer l'extension
     final extension = fileExtension ?? path.extension(imageFile.path).toLowerCase();

     // Debug logs
     print("📤 Début upload signé");
     print("📁 Chemin: ${imageFile.path}");
     print("🔍 Extension: $extension");
     print("🖼️ Est image: $isimage");
     print("☁️ Cloud Name: ${_cloudinaryFull.cloudName}");
     print("🔑 API Key: ${_cloudinaryFull.apiKey}");

     // Déterminer le type de ressource
     final resourceType = (isimage == true)
         ? CloudinaryResourceType.image
         : CloudinaryResourceType.video;

     // Générer un nom de fichier unique
     final timestamp = DateTime.now().millisecondsSinceEpoch;
     final fileName = 'signed_${timestamp}${extension}';

     // Effectuer l'upload
     final response = await _cloudinaryFull.upload(
       file: imageFile.path, // CORRECTION ICI : 'filePath:' au lieu de 'file:'
       resourceType: resourceType,
       folder: 'kogossa_app/secure',
       fileName: fileName,
       // Si besoin d'un upload preset signé :
       // uploadPreset: 'your_signed_preset',
     );

     // Vérifier la réponse
     if (response.isSuccessful) {
       print('✅ Upload signé réussi !');
       print('🔗 URL: ${response.secureUrl}');
       print('🆔 Public ID: ${response.publicId}');

       // Extraire l'ID public correctement
       final publicId = response.publicId;
       print('📋 ID Public extrait: $publicId');

       return response.secureUrl!;
     } else {
       print('❌ Upload échoué: ${response.error}');
       throw Exception('Upload signé échoué: ${response.error}');
     }
   } catch (e) {
     print('🔥 Erreur lors de l\'upload: $e');
     print('📝 Stack trace: ${e.toString()}');
     throw Exception('Échec de l\'upload signé: $e');
   }
 }

  // 4. Upload depuis URL (si image déjà en ligne) - CORRIGÉ
  Future<String> uploadFromUrl(String imageUrl) async {
    try {
      final response = await _cloudinary.upload(
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

  // 5. Générer une URL optimisée - CORRIGÉ
  String getOptimizedUrl(String originalUrl, {int width = 400, int height = 400}) {
    try {
      // Extraire le public ID de l'URL
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) {
        return originalUrl;
      }

      // Reconstruire l'URL avec transformations
      final version = pathSegments[0];
      final cloudName = uri.host.split('.')[0];
      final publicId = pathSegments.sublist(1).join('/');

      // Nettoyer l'extension du fichier
      final cleanPublicId = publicId.replaceAll(RegExp(r'\.(jpg|jpeg|png|gif|webp)$'), '');

      // URL avec transformations
      return 'https://res.cloudinary.com/$cloudName/image/upload/'
          'w_$width,h_$height,c_fill,q_auto,f_auto/'
          '$version/$cleanPublicId';
    } catch (e) {
      print('❌ Error generating optimized URL: $e');
      return originalUrl;
    }
  }

  // 6. Supprimer une image - CORRIGÉ
   Future<bool> deleteImage(String imageUrl) async {
     print('🗑️ Suppression de url : $imageUrl');
     print('https://res.cloudinary.com/dlzkp9dix/image/upload/v1770509900/kogossa_app/secure/signed_1770509896205.jpg.jpg');
    try {
      // CORRECTION: Extraire le publicId de l'URL
      final publicId = extractPublicIdFromUrl(imageUrl);
      print('🗑️ Suppression de la cle publique de  : $publicId');


      if (publicId.isEmpty) {
        print('❌ Impossible d\'extraire publicId de l\'URL');
        return false;
      }

      print('🗑️ Suppression de: $publicId');

      // CORRECTION: Utiliser la bonne méthode pour supprimer
      final response = await _cloudinary.destroy(
        publicId,  // Juste le publicId, pas de paramètre nommé
        resourceType: CloudinaryResourceType.auto,
        invalidate: true,
        // optParams: []
      );

      return response.isSuccessful;

    } catch (e) {
      print('❌ Erreur suppression: $e');
      return false;
    }
  }

  // 7. NOUVELLE MÉTHODE: Extraire le Public ID depuis une URL Cloudinary
  String extractPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) return '';

      // Format: /v1234567890/folder/image.jpg
      final version = pathSegments[0];
      final folderAndFile = pathSegments.sublist(1).join('/');

      // Retirer l'extension
      final publicId = folderAndFile.replaceAll(RegExp(r'\.[^/.]+$'), '');

      return publicId;
    } catch (e) {
      return '';
    }
  }

  // 8. NOUVELLE MÉTHODE: Upload avec callback de progression
  Future<String> uploadWithProgress(
      File imageFile,
      void Function(double) onProgress,
      ) async {
    try {
      // Dans cloudinary 1.2.0, on simule la progression
      onProgress(0.1);

      final response = await _cloudinary.upload(
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

 // Future<bool> testConnection() async {
 //   try {
 //     // Essayer de lister 1 image pour tester la connexion
 //     await _cloudinary.resources(
 //       maxResults: 1,
 //       resourceType: CloudinaryResourceType.image,
 //     );
 //     return true;
 //   } catch (e) {
 //     print('❌ Test connexion échoué: $e');
 //     return false;
 //   }
 // }


}