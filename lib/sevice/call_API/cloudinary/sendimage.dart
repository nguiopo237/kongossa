import 'dart:async';
import 'dart:io';

import 'package:cloudinary/cloudinary.dart';
import 'package:path/path.dart' as path;

class CloudinaryServices {
  // Vos clés Cloudinary
  static const String cloudName = "dlzkp9dix";
  static const String apiKey = "159775225955892";
  static const String apiSecret = "Uu59oh6fY-G2FCA5Yvpvq0b4JYI";

  Future<String> uploadImageSigneds({
    required File imageFile,
    bool isImage = true,
    String? customExtension,
  }) async {
    print('🚀 === DÉBUT UPLOAD CLOUDINARY ===');

    // VALIDATION DU FICHIER
    if (!await imageFile.exists()) {
      throw Exception('Le fichier n\'existe pas: ${imageFile.path}');
    }

    // DÉTECTION DE L'EXTENSION
    final fileExtension = path.extension(imageFile.path).toLowerCase();
    final extension = customExtension ?? fileExtension.replaceFirst('.', '');

    print('📊 Informations upload:');
    print('- Chemin fichier: ${imageFile.path}');
    print('- Extension: $extension');
    print('- Type: ${isImage ? "Image" : "Video"}');
    print('- Taille: ${(await imageFile.length() / 1024).toStringAsFixed(2)} KB');

    try {
      // CRÉATION DE LA CONFIGURATION SIGNÉE
      print('🔐 Création configuration Cloudinary signée...');
      print('- CloudName: $cloudName');
      print('- API Key: ${apiKey.substring(0, 6)}...');
      print('- API Secret: ${apiSecret.substring(0, 6)}...');

      final cloudinary = Cloudinary.signedConfig(
        cloudName: cloudName,
        apiKey: apiKey,
        apiSecret: apiSecret,
      );

      print('✅ Configuration Cloudinary créée avec succès');

      // UPLOAD
      print('📤 Début de l\'upload...');

      final response = await cloudinary.upload(
        file: imageFile.path,
        resourceType: isImage
            ? CloudinaryResourceType.image
            : CloudinaryResourceType.video,
        folder: 'kogossa_app/secure',
        fileName: 'signed_${DateTime.now().millisecondsSinceEpoch}.$extension',
        // Options supplémentaires pour plus de fiabilité

        // optParams: {
        //   'timeout': 30000, // 30 secondes
        //   'chunk_size': 5000000, // 5MB chunks pour les gros fichiers
        // },
      );

      print('📥 Réponse Cloudinary reçue:');
      print('- Succès: ${response.isSuccessful}');
      print('- Code: ${response.statusCode}');

      if (response.isSuccessful) {
        print('✅ === UPLOAD RÉUSSI ===');
        print('- URL sécurisée: ${response.secureUrl}');
        print('- Public ID: ${response.publicId}');
        print('- Format: ${response.format}');
        print('- Taille: ${response.bytes} bytes');

        // Extraire le publicId si nécessaire
        final publicId = _extractPublicId(response.secureUrl!);
        print('- Public ID extrait: $publicId');

        return response.secureUrl!;
      } else {
        print('❌ === ÉCHEC UPLOAD ===');
        print('- Erreur: ${response.error}');
        print('- Message: ${response.result}');

        // Gestion des erreurs spécifiques
        if (response.statusCode == 401) {
          throw Exception('Clés API Cloudinary invalides. Vérifiez apiKey/apiSecret.');
        } else if (response.statusCode == 400) {
          throw Exception('Requête invalide. Vérifiez les paramètres.');
        } else {
          throw Exception('Upload échoué: ${response.error}');
        }
      }

    } catch (e, stackTrace) {
      print('💥 === ERREUR DANS UPLOAD ===');
      print('- Type: ${e.runtimeType}');
      print('- Message: $e');
      print('- StackTrace: $stackTrace');

      // Gestion des erreurs réseau
      if (e is SocketException) {
        throw Exception('Problème de connexion internet: ${e.message}');
      } else if (e is TimeoutException) {
        throw Exception('Timeout - La connexion est trop lente');
      } else if (e.toString().contains('401')) {
        throw Exception('Authentification Cloudinary échouée. Vérifiez vos clés.');
      }

      throw Exception('Erreur upload: $e');
    } finally {
      print('🔚 === FIN UPLOAD ===');
    }
  }

  // Fonction pour extraire le publicId depuis l'URL
  String _extractPublicId(String secureUrl) {
    try {
      final uri = Uri.parse(secureUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        // Format: /v1234567890/folder/filename.jpg
        final folderAndFile = pathSegments.sublist(1).join('/');
        return folderAndFile.replaceFirst(RegExp(r'\.[^/.]+$'), '');
      }
      return 'unknown';
    } catch (e) {
      return 'error_extracting';
    }
  }
}