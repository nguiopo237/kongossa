// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class ChatService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   // Quand un utilisateur rejoint un salon
//   Future<void> subscribeToChatRoom(String chatRoomId) async {
//     try {
//       // Le nom du topic = "chat_12345" par exemple
//       await _fcm.subscribeToTopic('chat_$chatRoomId');
//       print('Abonné au salon $chatRoomId');
//     } catch (e) {
//       print('Erreur d\'abonnement: $e');
//     }
//   }
//
//   // Quand un utilisateur quitte un salon
//   Future<void> unsubscribeFromChatRoom(String chatRoomId) async {
//     try {
//       await _fcm.unsubscribeFromTopic('chat_$chatRoomId');
//       print('Désabonné du salon $chatRoomId');
//     } catch (e) {
//       print('Erreur de désabonnement: $e');
//     }
//   }
// }