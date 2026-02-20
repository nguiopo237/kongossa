import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String appId = "f29d87f5-87f2-4d83-b47c-93bf3b08ac0c";
  static const String apiKey =
      "os_v2_app_6koyp5mh6jgyhnd4so7twcfmbswfsuux7pyuck4lpk4kbpr2v6b76tzdqjkkkc6xesajmvo4ghb3zzgszmpvt73447shx2uwnj2ce4a"; // À sécuriser !

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
          'Authorization': 'Key $apiKey',
        },
        body: json.encode({
          'app_id': appId,
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

  // Méthode complète avec TOUS les paramètres possibles
  static Future<bool> sendNotificationToAlls({
    // Paramètres obligatoires
    required String title,
    required String message,

    // Paramètres optionnels
    Map<String, dynamic>? data,
    String? subtitle,
    String? url,
    String? imageUrl,
    String? largeIcon,
    String? bigPicture,
    int? androidAccentColor,
    String? androidChannelId,
    String? iosCategoryId,
    String? iosSound,
    String? androidSound,
    int? ttl, // Time to live en secondes
    int? priority, // 0-10
    bool? contentAvailable,
    bool? mutableContent,
    List<Map<String, dynamic>>? buttons,
    DateTime? sendAfter,
    DateTime? expireAfter,
  }) async {
    try {
      print('📤 Envoi d\'une notification à tous les utilisateurs...');
      print('📝 Titre: $title');
      print('📝 Message: $message');
      print('📦 Données additionnelles: $data');

      // Construction du payload
      Map<String, dynamic> payload = {
        'app_id': appId,
        'included_segments': ['All'], // Envoyer à tous
        'headings': {'en': title},
        'contents': {'en': message},
      };

      // Ajouter les champs optionnels s'ils sont fournis
      if (subtitle != null) payload['subtitle'] = {'en': subtitle};
      if (data != null) payload['data'] = data;
      if (url != null) payload['url'] = url;
      if (imageUrl != null) payload['chrome_web_image'] = imageUrl;
      if (largeIcon != null) payload['large_icon'] = largeIcon;
      if (bigPicture != null) payload['big_picture'] = bigPicture;
      if (androidAccentColor != null)
        payload['android_accent_color'] =
            'FF${androidAccentColor.toRadixString(16)}';
      if (androidChannelId != null)
        payload['android_channel_id'] = androidChannelId;
      if (iosCategoryId != null) payload['ios_category'] = iosCategoryId;
      if (iosSound != null) payload['ios_sound'] = iosSound;
      if (androidSound != null) payload['android_sound'] = androidSound;
      if (ttl != null) payload['ttl'] = ttl;
      if (priority != null) payload['priority'] = priority;
      if (contentAvailable != null)
        payload['content_available'] = contentAvailable;
      if (mutableContent != null) payload['mutable_content'] = mutableContent;
      if (buttons != null) payload['buttons'] = buttons;

      // Notifications programmées
      if (sendAfter != null) {
        payload['send_after'] = sendAfter.toUtc().toIso8601String();
      }
      if (expireAfter != null) {
        payload['expire_after'] = expireAfter.toUtc().toIso8601String();
      }

      // Paramètres spécifiques aux plateformes
      payload.update('web_buttons', (_) => buttons, ifAbsent: () => buttons);

      // Envoi de la requête
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $apiKey',
        },
        body: json.encode(payload),
      );

      print('📊 Status code: ${response.statusCode}');
      print('📦 Réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('✅ Notification envoyée avec succès');
        print('🆔 ID Notification: ${responseData['id']}');
        print('📊 Destinataires: ${responseData['recipients']}');
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
  }) async
  {
    print("playerId");
    print(playerId);
    print("playerId");
    try {
      final response = await http.post(
        Uri.parse('https://api.onesignal.com/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Key $apiKey',
        },
        body: json.encode({
          'app_id': appId,
          'include_player_ids': [playerId],  // ID OneSignal de l'utilisateur
          'headings': {'en': title},
          'contents': {'en': message},
          'data': data ?? {},
        }),
      );
      print("response de l envoie "); 

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
      'app_id': appId,
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
          'Authorization': 'Key $apiKey',
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
