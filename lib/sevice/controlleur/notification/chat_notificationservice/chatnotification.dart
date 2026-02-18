
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../../../../main.dart';


class ChatNotificationService {
  static final ChatNotificationService _instance = ChatNotificationService._internal();
  factory ChatNotificationService() => _instance;
  ChatNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Envoyer une notification de message
  Future<void> sendMessageNotification({
    required String receiverId,
    required String senderName,
    required String messageContent,
    required String conversationId,
  }) async {
    try {
      // Récupérer les tokens FCM du destinataire

      print("receiverId");
      // final snapshot = await _firestore.collection('user').doc(receiverId).get();
      // print(snapshot.data()!.length);   // Affiche les données
      // print(receiverId);
      // print(tokensSnapshot.length);
      print("receiverId");

      final userDoc = await _firestore
          .collection('user')
          .doc(receiverId)
          .get();
      print("receiverId");
      print(userDoc.exists);
      print("receiverId");

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final String? token = userData['tokens'];
      // // Récupérer les tokens
      // final tokens = tokensSnapshot.docs.map((doc) => doc.data()['tokens'] as String).toList();


      // Récupérer l'image de l'expéditeur
      final senderSnapshot = await _firestore
          .collection('user')
          .doc(AppUser.info!.googleId)
          .get();

      final senderData = senderSnapshot.data();
      final senderImage = senderData?['photoUrl'] ?? senderData?['photoURL'] ?? '';

      // Préparer la notification
      final Map<String, String> notificationData = {
        'type': 'chat_message',
        'title': 'Nouveau message de $senderName',
        'body': messageContent.length > 100
            ? '${messageContent.substring(0, 97)}...'
            : messageContent,
        'senderId': AppUser.info!.googleId!,
        'senderName': senderName,
        'senderImage': senderImage,
        'receiverId': receiverId,
        'conversationId': conversationId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      };

      // Envoyer la notification via Firebase Functions (recommandé)
      await sendNotificationToUser(token: token!, title: 'bonjour', body: '237');

      // Alternative : Sauvegarder dans Firestore pour déclencher une Cloud Function
      // await _saveNotificationToFirestore(receiverId, notificationData);

    } catch (e) {
      print('Erreur lors de l\'envoi de la notification: $e');
    }
  }

  // Méthode 1: Envoyer via Cloud Function (recommandé)


  Future<void> _sendViaCloudFunction( tokens, Map<String, String> data) async {
    try {
      // Initialiser l'instance Firebase Functions
      final functions = FirebaseFunctions.instance;

      // Optionnel: Spécifier la région si votre fonction est dans une région spécifique
      // functions.useFunctionsEmulator('localhost', 5001); // Pour le développement local

      // Appeler la Cloud Function
      final HttpsCallable callable = functions.httpsCallable('sendNotification');

      // Préparer les paramètres
      final Map<String, dynamic> params = {
        'tokens': tokens,
        'data': data,
        'priority': 'high',
        'timeToLive': 86400, // 24 heures en secondes (optionnel)
      };

      // Appeler la fonction et attendre le résultat
      final HttpsCallableResult result = await callable.call(params);

      // Analyser le résultat
      print('✅ Cloud Function exécutée avec succès');
      print('📊 Résultat: ${result.data}');

      // Vérifier les résultats d'envoi
      final Map<String, dynamic> response = result.data as Map<String, dynamic>;

      if (response['success'] == true) {
        print('✅ Notifications envoyées: ${response['successCount']}/${tokens.length}');

        // Gérer les tokens invalides si la fonction les retourne
        if (response['invalidTokens'] != null && response['invalidTokens'].isNotEmpty) {
          print('⚠️ Tokens invalides: ${response['invalidTokens']}');
          await _removeInvalidTokens(response['invalidTokens']);
        }
      } else {
        print('❌ Échec: ${response['error']}');
      }

    } catch (e) {
      print('❌ Erreur lors de l\'appel de la Cloud Function: $e');


      // Rejeter l'erreur pour la gestion dans le code appelant
      throw e;
    }
  }

  Future<void> sendFCMessage({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async
  {
    // Option 1: Utiliser l'API HTTP (nécessite une clé serveur)
    // À NE PAS METTRE DANS LE CODE CLIENT EN PRODUCTION !
    // Cette clé doit rester sur votre serveur
    const String serverKey = 'AIzaSyDSPsUjihCr5IBwJ-xQQQ4n3wJ3kkUD2oo';

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data ?? {},
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            'channelId': 'chat_messages',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default'
            }
          }
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur FCM: ${response.body}');
    }
  }





  Future<bool> sendNotificationToUser({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // 1. Obtenir un access token valide
      // final accessToken = await _getAccessToken();
      // if (accessToken == null) return false;

      // 2. Construire la requête pour FCM v1
      final url = 'https://fcm.googleapis.com/v1/projects/4/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': token,  // Token du destinataire
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channelId': 'chat_messages',
            }
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
              }
            }
          }
        }
      };

      // 3. Envoyer la requête
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ',    // ⭐ Token OAuth2, pas la clé serveur
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notification envoyée avec succès');
        return true;
      } else {
        print('❌ Erreur FCM: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }
}





// Fonction pour supprimer les tokens invalides
  Future<void> _removeInvalidTokens(List<String> invalidTokens) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String token in invalidTokens) {
        // Chercher le document avec ce token
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('tokens', isEqualTo: token)
            .get();

        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {
            'tokens': FieldValue.delete(), // Supprimer le token invalide
          });
        }
      }

      await batch.commit();
      print('✅ ${invalidTokens.length} token(s) invalide(s) supprimés');
    } catch (e) {
      print('❌ Erreur lors de la suppression des tokens: $e');
    }
  }

  // Méthode 2: Sauvegarder dans Firestore pour déclencher une Cloud Function
  Future<void> _saveNotificationToFirestore(String receiverId, Map<String, String> data) async {
    await Users
        .doc(receiverId)
        .collection('notifications')
        .add({
      ...data,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
FirebaseFirestore  _firestore= FirebaseFirestore.instance;
  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String conversationId, String receiverId) async {
    try {
      final batch = _firestore.batch();

      final unreadMessages = await _firestore
          .collection('messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('receiverId', isEqualTo: receiverId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors du marquage des messages lus: $e');
    }
  }
