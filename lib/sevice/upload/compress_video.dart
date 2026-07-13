import 'dart:io';

import 'package:flutter/material.dart';
import 'package:native_video_compress/controller/native_video_compressor.dart';
import 'package:native_video_compress/enum/audio_setting.dart';
import 'package:native_video_compress/enum/video_setting.dart';

class NativeVideoCompressService {
  static final NativeVideoCompressService _instance =
  NativeVideoCompressService._internal();
  factory NativeVideoCompressService() => _instance;
  NativeVideoCompressService._internal();

  // Compress with "YouTube-like" quality
  Future<String?> compressLikeYouTube(String inputPath) async {
    try {
      debugPrint('🎬 Starting compression: $inputPath');

      // Optimized settings for maximum quality
      final output = await NativeVideoController.compressVideo(
        inputPath: inputPath,
        bitrate: 4_000_000,        // 4 Mbps - YouTube 1080p quality
        videoSetting: VideoSetting.h264, // H.264 for compatibility
        audioSetting: AudioSetting.aac,
        audioBitrate: 128000,
        printingInfo: true,           // Show detailed info
      );

      if (output != null) {
        debugPrint('✅ Compression successful: $output');
        debugPrint('📦 Compressed: ${(int.parse(output)! / 1048576).toStringAsFixed(2)} MB');
        return output;
      } else {
        debugPrint('❌ Compression failed');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      return null;
    }
  }

  // Fine-controlled version for optimal quality
  Future<String?> compressHighQuality(String originalPath) async {
    try {
      // 1. Get original file info
      final originalFile = File(originalPath);
      final originalSize = await originalFile.length();

      debugPrint('🎬 Starting compression...');
      debugPrint('📁 Original: ${(originalSize / 1048576).toStringAsFixed(2)} MB');

      // 2. Compress video and get compressed file path
      final compressedPath = await NativeVideoController.compressVideo(
        inputPath: originalPath,
        bitrate: 6_000_000,          // 6 Mbps - excellent quality
        width: 1920,                  // Full HD
        height: 1080,
        videoSetting: VideoSetting.h264,
        audioSetting: AudioSetting.aac,
        audioBitrate: 192000,         // High quality audio
        printingInfo: true,
      );

      // 3. Check if compression succeeded
      if (compressedPath == null) {
        debugPrint('❌ Compression failed');
        return null;
      }

      // 4. Get compressed file info
      final compressedFile = File(compressedPath);
      final compressedSize = await compressedFile.length();

      // 5. Calculate statistics
      final ratio = (compressedSize / originalSize * 100).toStringAsFixed(1);
      final saved = originalSize - compressedSize;

      // 6. Display results
      debugPrint('\n📊 COMPRESSION RESULTS:');
      debugPrint('📁 Original: ${(originalSize / 1048576).toStringAsFixed(2)} MB');
      debugPrint('📦 Compressed: ${(compressedSize / 1048576).toStringAsFixed(2)} MB');
      debugPrint('📉 Ratio: $ratio%');
      debugPrint('💰 Saved: ${(saved / 1048576).toStringAsFixed(2)} MB');
      debugPrint('📍 Path: $compressedPath');

      return compressedPath;

    } catch (e) {
      debugPrint('❌ Compression error: $e');
      return null;
    }
  }

  // Version for quick sharing (more compressed)
  Future<String?> compressForSharing(String inputPath) async {
    return await NativeVideoController.compressVideo(
      inputPath: inputPath,
      bitrate: 1_500_000,          // 1.5 Mbps - good for mobile
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
    debugPrint('🧹 Cache cleared');
  }
}