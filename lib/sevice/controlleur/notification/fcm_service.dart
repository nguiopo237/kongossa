// lib/services/fcm_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMService {
  // Remplacez par VOTRE clé serveur (trouvée dans la console Firebase)
  static const String _serverKey = 'AIzaSyD1NNnLmuWrXkiCF-uMou5UcbFWkuafS5I';

  // Remplacez par VOTRE ID de projet
  static const String _projectId = 'kongossa237-97f15';

  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
  }) async {
    try {
      // URL de l'API FCM
      final url = 'https://fcm.googleapis.com/v1/projects/kongossa237-97f15/messages:send';

      // Préparer le message
      final Map<String, dynamic> message = {
        'to': '/topics/$topic',
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'screen': 'chat',
          'topic': topic,
        },
      };

      // Envoyer la requête HTTP
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notification envoyée avec succès');
        print('Réponse: ${response.body}');
      } else {
        print('❌ Erreur: ${response.statusCode}');
        print('Message: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}