// lib/sevice/audio_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:voice_message_package/voice_message_package.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final Map<String, VoiceController> _activeControllers = {};
  final Map<String, AudioCacheInfo> _audioCache = {}; // URL -> info de cache
  String? _currentlyPlayingId;

  static const int MAX_CACHED_AUDIOS = 3;
  static const int MAX_LOCAL_FILES = 30; // Garder plus de fichiers

  // Récupérer ou télécharger l'audio avec vérification
  Future<String> getLocalAudioPath(String url) async {
    // Vérifier si déjà en cache et si le fichier existe toujours
    if (_audioCache.containsKey(url)) {
      final cacheInfo = _audioCache[url]!;
      final file = File(cacheInfo.path);

      if (await file.exists()) {
        // Mettre à jour la date de dernier accès
        cacheInfo.lastAccessed = DateTime.now();
        print("📀 Audio trouvé en cache: ${cacheInfo.path}");
        return cacheInfo.path;
      } else {
        // Fichier supprimé, on le retire du cache
        _audioCache.remove(url);
        print("⚠️ Fichier cache manquant, re-téléchargement: $url");
      }
    }

    // Télécharger et sauvegarder
    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final savePath = '${dir.path}/$fileName';

      print("📥 Téléchargement audio: $url");

      // Télécharger le fichier avec timeout
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      // Vérifier que le fichier a bien été téléchargé
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception("Fichier non créé après téléchargement");
      }

      // Vérifier la taille
      final fileSize = await file.length();
      if (fileSize == 0) {
        await file.delete();
        throw Exception("Fichier téléchargé vide");
      }

      // Sauvegarder dans le cache
      _audioCache[url] = AudioCacheInfo(
        path: savePath,
        createdAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      // Nettoyer les vieux fichiers si trop nombreux
      _cleanupOldFiles();

      print("💾 Audio sauvegardé: $savePath (${fileSize} bytes)");
      return savePath;

    } catch (e) {
      print("❌ Erreur téléchargement audio: $e");
      return url; // Fallback à l'URL si échec
    }
  }

  // Nettoyer les vieux fichiers
  void _cleanupOldFiles() async {
    if (_audioCache.length <= MAX_LOCAL_FILES) return;

    // Trier par date de dernier accès (plus ancien d'abord)
    final entries = _audioCache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

    // Supprimer les plus anciens jusqu'à revenir sous la limite
    int toDelete = _audioCache.length - MAX_LOCAL_FILES;
    for (int i = 0; i < toDelete; i++) {
      final entry = entries[i];
      try {
        final file = File(entry.value.path);
        if (await file.exists()) {
          await file.delete();
          print("🗑️ Ancien fichier supprimé: ${entry.value.path}");
        }
      } catch (e) {
        print("Erreur suppression: $e");
      }
      _audioCache.remove(entry.key);
    }
  }

  void registerController(String audioId, VoiceController controller) {
    // Nettoyer les contrôleurs inactifs
    _cleanupInactiveControllers();

    // Si on a trop de contrôleurs, disposer le plus ancien
    if (_activeControllers.length >= MAX_CACHED_AUDIOS) {
      final oldestKey = _activeControllers.keys.first;
      try {
        _activeControllers[oldestKey]?.dispose();
      } catch (e) {
        print("Erreur disposal: $e");
      }
      _activeControllers.remove(oldestKey);
    }

    _activeControllers[audioId] = controller;
    print("🎵 Audio enregistré: $audioId (total: ${_activeControllers.length})");
  }

  void _cleanupInactiveControllers() {
    // Garder seulement les contrôleurs valides
    _activeControllers.removeWhere((key, controller) {
      try {
        // Vérifier si le contrôleur est toujours valide
        return false; // Garder tous pour l'instant
      } catch (e) {
        return true;
      }
    });
  }

  void unregisterController(String audioId) {
    _activeControllers.remove(audioId);
    if (_currentlyPlayingId == audioId) {
      _currentlyPlayingId = null;
    }
  }

  void playAudio(String audioId) {
    _currentlyPlayingId = audioId;
  }

  void disposeAll() {
    print("🧹 Nettoyage de tous les audio (${_activeControllers.length})");
    for (var controller in _activeControllers.values) {
      try {
        controller.dispose();
      } catch (e) {
        print("Erreur: $e");
      }
    }
    _activeControllers.clear();
    _currentlyPlayingId = null;
  }

  // Nettoyer tous les fichiers locaux
  Future<void> clearAllLocalFiles() async {
    for (var cacheInfo in _audioCache.values) {
      try {
        final file = File(cacheInfo.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print("Erreur suppression: $e");
      }
    }
    _audioCache.clear();
    print("🧹 Tous les fichiers audio locaux supprimés");
  }
}

class AudioCacheInfo {
  final String path;
  final DateTime createdAt;
  DateTime lastAccessed;

  AudioCacheInfo({
    required this.path,
    required this.createdAt,
    required this.lastAccessed,
  });
}