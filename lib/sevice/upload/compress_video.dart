import 'dart:io';

import 'package:flutter/material.dart';
import 'package:native_video_compress/controller/native_video_compressor.dart';
import 'package:native_video_compress/enum/audio_setting.dart';
import 'package:native_video_compress/enum/video_setting.dart';

import 'package:path_provider/path_provider.dart';

class NativeVideoCompressService {
  static final NativeVideoCompressService _instance =
  NativeVideoCompressService._internal();
  factory NativeVideoCompressService() => _instance;
  NativeVideoCompressService._internal();

  // Compresser avec qualité "YouTube-like"
  Future<String?> compressLikeYouTube(String inputPath) async {
    try {
      print('🎬 Début compression: $inputPath');

      // Paramètres optimisés pour qualité maximale
      final output = await NativeVideoController.compressVideo(
        inputPath: inputPath,
        bitrate: 4_000_000,        // 4 Mbps - qualité YouTube 1080p
        videoSetting: VideoSetting.h264, // H.264 pour compatibilité
        audioSetting: AudioSetting.aac,
        audioBitrate: 128000,
        printingInfo: true,           // Affiche les infos détaillées
      );

      if (output != null) {
        print('✅ Compression réussie: $output');
        print('📦 Compressé: ${(int.parse(output)! / 1048576).toStringAsFixed(2)} MB');
        return output;
      } else {
        print('❌ Échec compression');
        return null;
      }
    } catch (e) {
      print('❌ Erreur: $e');
      return null;
    }
  }

  // Version avec contrôle fin pour qualité optimale
  Future<String?> compressHighQuality(String originalPath) async {
    try {
      // 1. Obtenir les infos du fichier original
      final originalFile = File(originalPath);
      final originalSize = await originalFile.length();

      print('🎬 Début compression...');
      print('📁 Original: ${(originalSize / 1048576).toStringAsFixed(2)} MB');

      // 2. Compresser la vidéo et récupérer le chemin du fichier compressé
      final compressedPath = await NativeVideoController.compressVideo(
        inputPath: originalPath,
        bitrate: 6_000_000,          // 6 Mbps - excellente qualité
        width: 1920,                  // Full HD
        height: 1080,
        videoSetting: VideoSetting.h264,
        audioSetting: AudioSetting.aac,
        audioBitrate: 192000,         // Audio haute qualité
        printingInfo: true,
      );

      // 3. Vérifier si la compression a réussi
      if (compressedPath == null) {
        print('❌ Échec de la compression');
        return null;
      }

      // 4. Obtenir les infos du fichier compressé
      final compressedFile = File(compressedPath);
      final compressedSize = await compressedFile.length();

      // 5. Calculer les statistiques
      final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
      final saved = originalSize - compressedSize;

      // 6. Afficher les résultats
      print('\n📊 RÉSULTATS COMPRESSION:');
      print('📁 Original: ${(originalSize / 1048576).toStringAsFixed(2)} MB');
      print('📦 Compressé: ${(compressedSize / 1048576).toStringAsFixed(2)} MB');
      print('📉 Ratio: $ratio%');
      print('💰 Économie: ${(saved / 1048576).toStringAsFixed(2)} MB');
      print('📍 Chemin: $compressedPath');

      return compressedPath;

    } catch (e) {
      print('❌ Erreur lors de la compression: $e');
      return null;
    }
  }

  // Version pour partage rapide (plus compressé)
  Future<String?> compressForSharing(String inputPath) async {
    return await NativeVideoController.compressVideo(
      inputPath: inputPath,
      bitrate: 1_500_000,          // 1.5 Mbps - bon pour mobile
      width: 854,                    // 480p
      height: 480,
      videoSetting: VideoSetting.h264,
      audioSetting: AudioSetting.aac,
      audioBitrate: 64000,
      printingInfo: true,
    );
  }

  // Nettoyer le cache
  Future<void> clearCache() async {
    await NativeVideoController.clearCache();
    print('🧹 Cache nettoyé');
  }
}