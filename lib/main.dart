import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'config_App/env_config.dart';
import 'firebase_options.dart';
import 'screens/splashscreen/splaschsreen.dart';
import 'sevice/controlleur/authentification/auth_controlleur.dart';
import 'sevice/controlleur/firestore_collections_service.dart';
import 'sevice/controlleur/init_controlleur/init_controlleur.dart';
import 'sevice/controlleur/notification/firebase_messaging_service.dart';
import 'sevice/controlleur/notification/local_notifications_service.dart';
import 'sevice/theme/theme_switcher_provider.dart';

// WorkManager callback (runs in background)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🔄 Background task: $task");
    debugPrint("📦 Data: $inputData");

    try {
      switch (task) {
        case "checkMessagesTask":
          await authController.setupMessagesListener() ;
          break;
        case "cleanupTask":
          await performCleanup();
          break;
        case "syncDataTask":
          await syncData();
          break;
        default:
          debugPrint("⚠️ Unknown task: $task");
      }

      debugPrint("✅ Task $task completed (background)");
      return Future.value(true);

    } catch (e, stackTrace) {
      debugPrint("❌ Error in background task $task: $e");
      debugPrint(stackTrace.toString());
      return Future.value(false);
    }
  });
}

// Function to check unread messages
Future<void> checkUnreadMessages() async {
  try {
    debugPrint("🔍 Checking unread messages (background)...");

    // Get user ID from SharedPreferences
    String? currentUserId = await getCurrentUserId();

    if (currentUserId == null) {
      debugPrint("⚠️ User not logged in, verification skipped (background)");
      return;
    }

    // Get unread messages
    var snapshot = await FirestoreCollectionsService.sms
        .where("receiveId", isEqualTo: currentUserId)
        .where("isRead", isEqualTo: false)
        .get();

    int unreadCount = snapshot.docs.length;

    if (unreadCount > 0) {
      debugPrint("🔔 $unreadCount unread message(s) (background)");

      // Group by sender for more details
      Map<String, int> senderCounts = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String sender = data['namesenderId'] ?? 'Inconnu';
        senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
      }

      debugPrint("👥 By sender (background):");
      senderCounts.forEach((sender, count) {
        debugPrint("   • $sender: $count");
      });

      // Envoyer une notification
      // await showBackgroundNotification(unreadCount, senderCounts);
    } else {
      debugPrint("✅ No new messages (background)");
    }

  } catch (e) {
    debugPrint("❌ Error checkUnreadMessages (background): $e");
  }
}

// Fonction de nettoyage
Future<void> performCleanup() async {
  try {
    debugPrint("🧹 Cleanup in progress... (background)");

    // Nettoyer les anciens messages (plus de 30 jours)
    DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

    var oldMessages = await FirestoreCollectionsService.sms
        .where("timestamp", isLessThan: thirtyDaysAgo)
        .get();

    if (oldMessages.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint("✅ ${oldMessages.docs.length} old messages deleted (background)");
    }

    // Other cleanup tasks if needed
    debugPrint("✅ Cleanup completed (background)");

  } catch (e) {
    debugPrint("❌ Error performCleanup (background): $e");
  }
}

// Fonction de synchronisation
Future<void> syncData() async {
  try {
    debugPrint("🔄 Data synchronization... (background)");

    String? currentUserId = await getCurrentUserId();
    if (currentUserId == null) return;

    // Votre logique de synchronisation ici
    // For example, update statuses, etc.

    debugPrint("✅ Synchronization completed (background)");

  } catch (e) {
    debugPrint("❌ Error syncData (background): $e");
  }
}

// Fonction pour obtenir l'ID utilisateur depuis SharedPreferences
Future<String?> getCurrentUserId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userinfo'); // Adjust to your key
  } catch (e) {
    debugPrint("❌ Error getCurrentUserId (background): $e");
    return null;
  }
}

// Function to display an enhanced notification
// Future<void> showBackgroundNotification(int count, Map<String, int>? senderCounts) async {
//   try {
//     FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
//
//     // Create a detailed message
//     String body = 'Vous avez $count nouveau(x) message(s) arriere';
//
//     if (senderCounts != null && senderCounts.isNotEmpty) {
//       String details = senderCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
//       body = '$body\nDe: $details';
//     }
//
//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//     AndroidNotificationDetails(
//       'background_channel',
//       'Messages Kongossa',
//       channelDescription: 'Background message notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       showWhen: true,
//       enableVibration: true,
//       playSound: true,
//       color: Colors.deepOrange,
//       ledColor: Colors.deepOrange,
//       ledOnMs: 1000,
//       ledOffMs: 500,
//     );
//
//     final NotificationDetails platformChannelSpecifics = NotificationDetails(
//       android: androidPlatformChannelSpecifics,
//       iOS: DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         badgeNumber: count,
//       ),
//     );
//
//     await flip.show(
//       DateTime.now().millisecond,
//       '📬 Nouveaux messages',
//       body,
//       platformChannelSpecifics,
//     );
//
//     debugPrint("📬 Notification envoyée arriere: $body");
//
//   } catch (e) {
//     debugPrint("❌ Erreur showBackgroundNotification arriere: $e");
//   }
// }

// Function to schedule all tasks
Future<void> scheduleAllBackgroundTasks() async {
  try {
    // Check messages every 15 minutes
    await Workmanager().registerPeriodicTask(
      "1",
      "checkMessagesTask",
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
      initialDelay: Duration(minutes: 1),
    );

    // Nettoyage une fois par jour
    await Workmanager().registerPeriodicTask(
      "cleanupTask",
      "cleanupTask",
      frequency: Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    // Synchronisation toutes les 30 minutes
    await Workmanager().registerPeriodicTask(
      "syncDataTask",
      "syncDataTask",
      frequency: Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    debugPrint("✅ All tasks scheduled (background)");

  } catch (e) {
    debugPrint("❌ Error scheduleAllBackgroundTasks (background): $e");
  }
}

// Function to cancel all tasks
Future<void> cancelAllBackgroundTasks() async {
  await Workmanager().cancelAll();
  debugPrint("🛑 All tasks cancelled (background)");
}


// In your main.dart, in the class where you have initializeOneSignal()

void _showCustomNotification(OSNotification notification) {
  // Display a custom notification in the app
  debugPrint('📱 Custom display: ${notification.title}');

  // Option 1: Utiliser un ScaffoldMessenger si vous avez un contexte
  // But note: _showCustomNotification has no context access here

  // Option 2: Emit an event to be handled elsewhere
  notificationStreamController.add(notification);
}

// Create a StreamController to manage notifications
final StreamController<OSNotification> notificationStreamController =
StreamController<OSNotification>.broadcast();

// Getter pour le stream
Stream<OSNotification> get notificationStream => notificationStreamController.stream;


void _configureNotificationHandlers() {
  // Quand l'app est en premier plan — afficher la notification OneSignal normalement
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    debugPrint('📱 Foreground notification received: ${event.notification.jsonRepresentation()}');
    // Ne pas appeler preventDefault() pour laisser OneSignal afficher la notification
    // _showCustomNotification(event.notification);
  });

  // Quand l'utilisateur clique sur une notification
  OneSignal.Notifications.addClickListener((event) {
    debugPrint('👆 Notification clicked: ${event.notification.jsonRepresentation()}');
    _handleNotificationClick(event.notification);
  });

  // Get the player ID (unique device identifier)
  OneSignal.User.getOnesignalId().then((id) {
    if (id != null) {
      debugPrint('🆔 OneSignal User ID: $id');
      // Save this ID to send notifications to this device
    }
  });
}
// Dans votre main.dart, ajoutez cette fonction
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void _handleNotificationClick(OSNotification notification) {
  debugPrint('👆 Notification clicked: ${notification.title}');

  // Get additional data
  final additionalData = notification.additionalData ?? {};
  debugPrint('📦 Data: $additionalData');

  // Navigate to the appropriate screen based on notification type
  final type = additionalData['type'];
  final postId = additionalData['postId'];


  // Utiliser le navigatorKey pour naviguer
  final context = navigatorKey.currentContext;
  if (context != null) {
    if (type == 'like' && postId != null) {
      navigatorKey.currentState?.pushNamed('/post', arguments: postId);
    } else if (type == 'comment' && postId != null) {
      navigatorKey.currentState?.pushNamed('/comments', arguments: postId);
    } else if (type == 'follow') {
      navigatorKey.currentState?.pushNamed('/profile', arguments: additionalData['userId']);
    } else {
      // Default: go to notifications screen
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les variables d'environnement (.env)
  await EnvConfig.load();

  // Initialiser le formatage des dates
  await initializeDateFormatting('fr_FR', null);

  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configuration Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialiser les notifications locales
  // final localNotificationsService = LocalNotificationsService.instance();
  // await localNotificationsService.init();

  // Initialiser Firebase Messaging
  // final firebaseMessagingService = FirebaseMessagingService.instance();
  // await firebaseMessagingService.init(localNotificationsService: localNotificationsService);

  // Initialize controllers
  AppControllers.initialize();

  // Load saved theme BEFORE runApp (prevents dark theme flash)
  await ThemeSwitcherProvider.loadSavedTheme();

  // Initialiser WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    );

  // Schedule tasks if user is logged in
  String? userId = await getCurrentUserId();
  if (userId != null) {
    await scheduleAllBackgroundTasks();
  }

  // Configurer l'orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize(EnvConfig.onesignalAppId);
        OneSignal.Notifications.requestPermission(true);
        _configureNotificationHandlers();
    FocusManager.instance.primaryFocus?.unfocus();
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return ThemeSwitcherProvider.buildApp(
          title: 'Kongossa',
          homeBuilder: (_) => const SplashScreen(),
          onInit: () => authController.getUserInfoLocally(),
        );
      },
    );
  }
}