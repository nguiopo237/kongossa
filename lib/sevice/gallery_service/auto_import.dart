import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';

class AutoGalleryImportService {
  // Singleton
  static final AutoGalleryImportService _instance = AutoGalleryImportService._internal();
  factory AutoGalleryImportService() => _instance;
  AutoGalleryImportService._internal();

  // Liste des images importées
  List<String> importedImages = [];

  // Dernière date d'import
  DateTime? lastImportTime;

  // Callback pour notifier les nouvelles images
  Function(List<String>)? onNewImagesImported;

  // Types MIME d'images acceptés
  final List<String> _allowedImageMimeTypes = [
    'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
    'image/webp', 'image/bmp', 'image/heic', 'image/heif'
  ];

  // Extensions de fichiers acceptées
  final List<String> _allowedExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif'
  ];

  /// ================== GESTION DES PERMISSIONS ==================

  Future<bool> requestPermissions() async {
    try {
      if (await Permission.photos.isDenied || await Permission.photos.isPermanentlyDenied) {
        PermissionStatus status = await Permission.photos.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
        return false;
      }
      else if (await Permission.storage.isDenied || await Permission.storage.isPermanentlyDenied) {
        PermissionStatus status = await Permission.storage.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('❌ Erreur permission: $e');
      return false;
    }
  }

  /// ================== VALIDATION DES IMAGES ==================

  bool _isValidImageFile(File file) {
    try {
      if (!file.existsSync()) return false;

      int fileSize = file.lengthSync();
      if (fileSize < 1024 || fileSize > 50 * 1024 * 1024) return false;

      String extension = file.path.toLowerCase();
      bool hasValidExtension = _allowedExtensions.any((ext) => extension.endsWith(ext));
      if (!hasValidExtension) return false;

      final mimeType = lookupMimeType(file.path);
      if (mimeType == null) return false;

      return _allowedImageMimeTypes.contains(mimeType);

    } catch (e) {
      return false;
    }
  }

  /// ================== COMPTER LES IMAGES DANS LA GALERIE ==================

  Future<int> countImagesInGallery() async {
    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) return 0;

      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      int total = 0;
      for (var album in albums) {
        total +=await album.assetCountAsync;
      }

      return total;
    } catch (e) {
      debugPrint('❌ Erreur comptage: $e');
      return 0;
    }
  }

  /// ================== RÉCUPÉRER TOUTES LES IMAGES VALIDES ==================

  Future<List<File>> _getAllValidImagesFromGallery() async {
    List<File> validImages = [];

    try {
      bool hasPermission = await requestPermissions();
      if (!hasPermission) return validImages;

      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      for (var album in albums) {
        List<AssetEntity> assets = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );

        for (var asset in assets) {
          try {
            File? file = await asset.file;
            if (file != null && _isValidImageFile(file)) {
              validImages.add(file);
            }
          } catch (e) {
            continue;
          }
        }
      }

    } catch (e) {
      debugPrint('❌ Erreur récupération: $e');
    }

    return validImages;
  }

  /// ================== IMPORTER TOUTES LES IMAGES ==================

  Future<List<String>> importAllValidImages() async {
    List<String> importedPaths = [];

    try {
      debugPrint("🚀 Début de l'importation de TOUTES les images...");

      bool hasPermission = await requestPermissions();
      if (!hasPermission) {
        debugPrint("❌ Permission refusée");
        return importedPaths;
      }

      Directory appDir = await getApplicationDocumentsDirectory();
      String appImagesPath = '${appDir.path}/imported_images';
      await Directory(appImagesPath).create(recursive: true);

      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isEmpty) {
        debugPrint("📸 Aucun album trouvé");
        return importedPaths;
      }

      int totalImages = 0;
      for (var album in albums) {
        totalImages +=  await album.assetCountAsync;
      }

      debugPrint("📊 Total d'images trouvées: $totalImages");

      int importedCount = 0;

      for (var album in albums) {
        debugPrint("📁 Importation de l'album: ${album.name}");

        int pageSize = 50;
        for (int start = 0; start < await album.assetCountAsync; start += pageSize) {
          int end = start + pageSize;
          if (end > await album.assetCountAsync) end = await album.assetCountAsync;;

          List<AssetEntity> assets = await album.getAssetListRange(
            start: start,
            end: end,
          );

          for (var asset in assets) {
            try {
              File? file = await asset.file;
              if (file == null) continue;

              if (!_isValidImageFile(file)) continue;

              String fileName = file.path.split('/').last;
              bool alreadyExists = importedPaths.any((path) => path.contains(fileName));
              if (alreadyExists) continue;

              String extension = file.path.split('.').last.toLowerCase();
              String uniqueFileName = 'IMG_${DateTime.now().millisecondsSinceEpoch}_${importedCount.toString().padLeft(6, '0')}.$extension';
              String newPath = '$appImagesPath/$uniqueFileName';

              File newImage = await file.copy(newPath);

              if (await newImage.exists()) {
                importedPaths.add(newImage.path);
                importedCount++;

                if (importedCount % 10 == 0) {
                  debugPrint("📸 Progression: $importedCount/$totalImages");
                }
              }

            } catch (e) {
              continue;
            }
          }
        }
      }

      importedImages = importedPaths;
      lastImportTime = DateTime.now();

      debugPrint("✅ IMPORTATION TERMINÉE: $importedCount images");

    } catch (e) {
      debugPrint('❌ Erreur: $e');
    }

    return importedPaths;
  }

  /// ================== IMPORTER NOUVELLES IMAGES ==================

  Future<List<String>> importNewValidImages() async {
    List<String> newImportedPaths = [];

    try {
      List<File> allValidImages = await _getAllValidImagesFromGallery();

      Directory appDir = await getApplicationDocumentsDirectory();
      String appImagesPath = '${appDir.path}/imported_images';
      await Directory(appImagesPath).create(recursive: true);

      DateTime filterTime = lastImportTime ?? DateTime.now().subtract(Duration(days: 30));

      int importedCount = 0;

      for (var imageFile in allValidImages) {
        try {
          DateTime lastModified = await imageFile.lastModified();

          if (lastModified.isAfter(filterTime)) {
            String extension = imageFile.path.split('.').last.toLowerCase();
            String fileName = 'NEW_${DateTime.now().millisecondsSinceEpoch}_${importedCount.toString().padLeft(4, '0')}.$extension';
            String newPath = '$appImagesPath/$fileName';

            File newImage = await imageFile.copy(newPath);

            if (await newImage.exists()) {
              newImportedPaths.add(newImage.path);
              importedCount++;
            }
          }
        } catch (e) {
          continue;
        }
      }

      importedImages.addAll(newImportedPaths);
      lastImportTime = DateTime.now();

      if (newImportedPaths.isNotEmpty && onNewImagesImported != null) {
        onNewImagesImported!(newImportedPaths);
      }

    } catch (e) {
      debugPrint('❌ Erreur: $e');
    }

    return newImportedPaths;
  }

  /// ================== NETTOYAGE ==================

  Future<void> cleanupInvalidImages() async {
    try {
      Directory appDir = await getApplicationDocumentsDirectory();
      String appImagesPath = '${appDir.path}/imported_images';

      if (!await Directory(appImagesPath).exists()) return;

      List<FileSystemEntity> files = Directory(appImagesPath).listSync();
      int deletedCount = 0;

      for (var file in files) {
        if (file is File) {
          try {
            if (!_isValidImageFile(file)) {
              await file.delete();
              deletedCount++;
            }
          } catch (e) {
            try {
              await file.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }

      importedImages = importedImages.where((path) {
        return File(path).existsSync();
      }).toList();

      debugPrint('🧹 Nettoyage: $deletedCount fichiers');

    } catch (e) {
      debugPrint('❌ Erreur nettoyage: $e');
    }
  }

  /// ================== SURVEILLANCE ==================

  void startMonitoring({Function(List<String>)? onNewImages}) {
    this.onNewImagesImported = onNewImages;

    PhotoManager.addChangeCallback((event) async {
      debugPrint('👀 Changement détecté');
      List<String> newImages = await importNewValidImages();
      if (newImages.isNotEmpty && onNewImages != null) {
        onNewImages(newImages);
      }
    });

    PhotoManager.startChangeNotify();
    debugPrint('👀 Surveillance activée');
  }

  void stopMonitoring() {
    PhotoManager.stopChangeNotify();
    PhotoManager.removeChangeCallback((value) {

    },);
    debugPrint('👀 Surveillance désactivée');
  }

  /// ================== UTILITAIRES ==================

  List<String> getImportedImages() {
    return importedImages.where((path) {
      return File(path).existsSync();
    }).toList();
  }

  Future<void> deleteImage(String path) async {
    try {
      File file = File(path);
      if (await file.exists()) {
        await file.delete();
        importedImages.remove(path);
      }
    } catch (e) {}
  }
}