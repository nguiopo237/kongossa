import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/src/cache_managers/default_cache_manager.dart';
import 'package:path/path.dart' as path;

class Thumbvideo extends StatefulWidget {
  const Thumbvideo({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<Thumbvideo> createState() => _ThumbvideoState();
}

class _ThumbvideoState extends State<Thumbvideo> {
  static final Map<String, String?> _thumbnailCache = {};
  static final Map<String, Future<String?>> _thumbnailFutures = {};
  static final Set<String> _processingVideos = {};

  static const Duration _timeout = Duration(seconds: 8);
  Timer? _timeoutTimer;

  // Cache pour les fichiers vérifiés
  static final Map<String, bool> _fileExistsCache = {};

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(_timeout, () {
      if (mounted) {
        debugPrint('⏱️ Timeout génération miniature pour: ${widget.videoUrl}');
        setState(() {}); // Forcer le rebuild pour afficher le placeholder
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<String?> generateThumbnail(String videoUrl) async {
    if (_processingVideos.contains(videoUrl)) {
      debugPrint('⏳ Vidéo déjà en cours de traitement: $videoUrl');
      return null;
    }

    _processingVideos.add(videoUrl);

    try {
      // Créer un nom de fichier unique basé sur l'URL
      final videoFileName = videoUrl.split('/').last.replaceAll('.mp4', '');
      final thumbnailFileName = 'thumb_${videoFileName}.jpg';

      // Obtenir le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = path.join(tempDir.path, thumbnailFileName);

      // Vérifier si la miniature existe déjà
      final existingFile = File(thumbnailPath);
      if (await existingFile.exists()) {
        final fileAge = DateTime.now().difference(await existingFile.lastModified());
        if (fileAge.inHours < 24) { // Valide pendant 24h
          debugPrint('📦 Miniature existante trouvée: $thumbnailPath');
          _fileExistsCache[videoUrl] = true;
          return thumbnailPath;
        } else {
          // Supprimer l'ancien fichier
          await existingFile.delete();
        }
      }

      // Vérifier le cache manager
      final fileInfo = await DefaultCacheManager().getFileFromCache(videoUrl).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('⏱️ Timeout cache manager pour: $videoUrl');
          return null;
        },
      );

      String videoPath = videoUrl;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        videoPath = fileInfo.file.path;
      }

      // Générer la miniature
      final generatedPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        maxHeight: 300,
        quality: 75,
        // fileName: thumbnailFileName, // Nom de fichier fixe
      ).timeout(
        _timeout,
        onTimeout: () {
          debugPrint('⏱️ Timeout génération miniature pour: $videoUrl');
          return null;
        },
      );

      if (generatedPath != null && await File(generatedPath).exists()) {
        debugPrint('✅ Miniature générée avec succès: $generatedPath');
        _fileExistsCache[videoUrl] = true;
        return generatedPath;
      } else {
        debugPrint('❌ Échec génération miniature pour: $videoUrl');
        return null;
      }

    } catch (e) {
      debugPrint('❌ Erreur génération miniature: $e');
      return null;
    } finally {
      _processingVideos.remove(videoUrl);
    }
  }

  Future<String?> getVideoThumbnail(String videoUrl) async {
    // Vérifier le cache
    if (_thumbnailCache.containsKey(videoUrl)) {
      final cachedPath = _thumbnailCache[videoUrl];
      if (cachedPath != null) {
        // Vérifier si le fichier existe toujours
        final exists = _fileExistsCache[videoUrl] ?? await File(cachedPath).exists();
        if (exists) {
          _fileExistsCache[videoUrl] = true;
          debugPrint('📦 Miniature en cache pour: $videoUrl');
          return cachedPath;
        } else {
          // Cache invalide, supprimer l'entrée
          _thumbnailCache.remove(videoUrl);
          _fileExistsCache.remove(videoUrl);
        }
      }
    }

    // Vérifier les futures en cours
    if (_thumbnailFutures.containsKey(videoUrl)) {
      debugPrint('⏳ Future en cours pour: $videoUrl');
      return _thumbnailFutures[videoUrl];
    }

    // Nouvelle génération
    debugPrint('🆕 Génération miniature pour: $videoUrl');
    final future = generateThumbnail(videoUrl);
    _thumbnailFutures[videoUrl] = future;

    try {
      final result = await future;
      if (result != null && mounted) {
        setState(() {
          _thumbnailCache[videoUrl] = result;
          _fileExistsCache[videoUrl] = true;
        });
      }
      return result;
    } catch (e) {
      debugPrint('❌ Erreur getVideoThumbnail: $e');
      return null;
    } finally {
      _thumbnailFutures.remove(videoUrl);
    }
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripesPainter()),
          const Center(
            child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _timeoutTimer?.cancel();

    return FutureBuilder<String?>(
      future: getVideoThumbnail(widget.videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<bool>(
            future: File(snapshot.data!).exists(),
            builder: (context, fileSnapshot) {
              if (fileSnapshot.connectionState == ConnectionState.waiting) {
                return _buildVideoPlaceholder();
              }

              if (fileSnapshot.hasData && fileSnapshot.data == true) {
                return Image.file(
                  File(snapshot.data!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Erreur chargement image: $error');
                    return _buildVideoPlaceholder();
                  },
                );
              } else {
                debugPrint('❌ Fichier introuvable: ${snapshot.data}');
                return _buildVideoPlaceholder();
              }
            },
          );
        } else {
          return _buildVideoPlaceholder();
        }
      },
    );
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (i + 1) / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}