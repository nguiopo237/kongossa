import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String _appId = "f29d87f5-87f2-4d83-b47c-93bf3b08ac0c";
  static const String _apiKey = "f29d87f5-87f2-4d83-b47c-93bf3b08ac0c"; // À sécuriser !

  // Envoyer une notification à tous les utilisateurs
  static Future<bool> sendNotificationToAll({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_apiKey',
        },
        body: json.encode({
          'app_id': _appId,
          'included_segments': ['All'], // Tous les utilisateurs
          'headings': {'en': title},
          'contents': {'en': message},
          'data': data ?? {}, // Données supplémentaires
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Notification envoyée avec succès');
        return true;
      } else {
        print('❌ Erreur: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }

  // Envoyer à un utilisateur spécifique
  static Future<bool> sendNotificationToUser({
    required String playerId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_apiKey',
        },
        body: json.encode({
          'app_id': _appId,
          'include_player_ids': [playerId], // ID OneSignal de l'utilisateur
          'headings': {'en': title},
          'contents': {'en': message},
          'data': data ?? {},
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }

  // Envoyer une notification programmée
  static Future<bool> sendScheduledNotification({
    required String title,
    required String message,
    required DateTime sendAt,
    String? playerId,
  }) async {
    // Format ISO 8601 requis
    final formattedDate = sendAt.toUtc().toIso8601String();

    final payload = {
      'app_id': _appId,
      'headings': {'en': title},
      'contents': {'en': message},
      'send_after': formattedDate,
    };

    if (playerId != null) {
      payload['include_player_ids'] = [playerId];
    } else {
      payload['included_segments'] = ['All'];
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $_apiKey',
        },
        body: json.encode(payload),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur: $e');
      return false;
    }
  }
}

// Récupérer le Player ID d'un utilisateur
String? getUserPlayerId() {
  // Vous pouvez récupérer l'ID OneSignal de l'utilisateur connecté
  return OneSignal.User.getOnesignalId() as String?;
}