import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:videosdk/videosdk.dart';

import '../../config_App/env_config.dart';

/// Service singleton for VideoSDK room lifecycle.
///
/// Uses a **verification token** (pre-generated JWT from the VideoSDK dashboard)
/// stored in `.env` as `VIDEOSDK_TOKEN`. For production, move token generation
/// to a Firebase Function so secrets never live on the client.
class VideoSdkService extends GetxService {
  static VideoSdkService get to => Get.find();

  /// The verification token from .env
  String get _token => EnvConfig.videosdkToken;

  // ── Room creation (REST API) ─────────────────────────────────────────────

  /// Create a new VideoSDK room and return its `roomId`.
  ///
  /// Throws on failure so callers can handle the error.
  Future<String> createRoom({bool isHls = false}) async {
    final uri = Uri.parse('https://api.videosdk.live/v2/rooms');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': _token,
        'Content-Type': 'application/json',
      },
      body:
          isHls ? jsonEncode({'autoCloseConfig': {'closeOnAllLeave': true}}) : null,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create VideoSDK room: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['roomId'] as String;
  }

  /// Check if a room still exists.
  Future<bool> roomExists(String roomId) async {
    final uri = Uri.parse('https://api.videosdk.live/v2/rooms/$roomId');
    final response = await http.get(
      uri,
      headers: {'Authorization': _token},
    );
    return response.statusCode == 200;
  }

  // ── Room initialisation ──────────────────────────────────────────────────

  /// Create and initialise a [Room] instance for the current user.
  /// Does **not** call `.join()` – the caller controls when to join.
  Room initRoom({
    required String roomId,
    required String displayName,
    bool micEnabled = true,
    bool camEnabled = true,
  }) {
    return VideoSDK.createRoom(
      roomId: roomId,
      token: _token,
      displayName: displayName,
      micEnabled: micEnabled,
      camEnabled: camEnabled,
    );
  }
}
