// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   Future<void> initNotifications() async {
//     // Demander la permission à l'utilisateur
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//
//     if (settings.authorizationStatus != AuthorizationStatus.authorized) {
//       print('Permission refusée');
//       return;
//     }
//
//     // Récupérer le token FCM du device
//     String? token = await _fcm.getToken();
//     print('Token FCM: $token');
//
//     // Écouter les nouveaux tokens (quand ils sont rafraîchis)
//     _fcm.onTokenRefresh.listen((newToken) {
//       print('Nouveau token: $newToken');
//       // Mettre à jour le token dans votre base de données si nécessaire
//     });
//
//     // Configurer les handlers de messages
//     // _setupMessageHandlers();
//   }
// }