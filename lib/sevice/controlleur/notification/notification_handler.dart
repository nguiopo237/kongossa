import 'package:cloud_firestore/cloud_firestore.dart';


import 'fcm_service.dart';

class NotificationHandler {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String currentUserId;

  FCMService fcmService = FCMService();

  NotificationHandler(this.currentUserId) {
    _listenForNotificationRequests();
  }

  void _listenForNotificationRequests() {
    _firestore
        .collection('notification_requests')
        .where('timestamp', isGreaterThan: DateTime.now().subtract(Duration(minutes: 5)))
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();

          // Ne pas envoyer de notification si c'est l'expéditeur
          if (data?['senderId'] != currentUserId) {
            await _sendFCMNotification(
              topic: data?['topic'],
              title: data?['title'],
              body: data?['body'],
            );
          }

          // Optionnel : supprimer la requête traitée
          // await change.doc.reference.delete();
        }
      }
    });
  }

  Future<void> _sendFCMNotification({
    required String? topic,
    required String? title,
    required String? body,
  }) async {
    if (topic == null || title == null || body == null) return;

    try {
      // Envoyer la notification via FCM
      await fcmService.sendNotificationToTopic(topic: topic, title: title, body: body);
    } catch (e) {
      print('Erreur envoi notification: $e');
    }
  }
}