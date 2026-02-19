import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kongossa/screens/authentification.dart';
import 'package:kongossa/screens/onboding/onboding_screen.dart';
import 'package:kongossa/screens/splashscreen/splaschsreen.dart';
import 'package:kongossa/sevice/controlleur/authentification/auth_controlleur.dart';
import 'package:kongossa/sevice/controlleur/init_controlleur/init_controlleur.dart';
import 'package:kongossa/sevice/controlleur/notification/firebase_messaging_service.dart';
import 'package:kongossa/sevice/controlleur/notification/local_notifications_service.dart';
import 'package:kongossa/utils/test2.0.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'model/datamodel/user_model.dart';

CollectionReference Users = FirebaseFirestore.instance.collection('user');
CollectionReference Posts = FirebaseFirestore.instance.collection('postcarduser');
CollectionReference Sms = FirebaseFirestore.instance.collection('message');
CollectionReference notif = FirebaseFirestore.instance.collection('notification');

// Callback pour WorkManager (s'exécute en arrière-plan)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔄 Tâche en arrière-plan: $task");
    print("📦 Données: $inputData");

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
          print("⚠️ Tâche inconnue: $task");
      }

      print("✅ Tâche $task terminée arriere");
      return Future.value(true);

    } catch (e, stackTrace) {
      print("❌ Erreur dans la tâche  arriere$task: $e");
      print(stackTrace);
      return Future.value(false);
    }
  });
}

// Fonction pour vérifier les messages non lus
Future<void> checkUnreadMessages() async {
  try {
    print("🔍 Vérification des messages non lus arriere...");

    // Récupérer l'ID utilisateur depuis SharedPreferences
    String? currentUserId = await getCurrentUserId();

    if (currentUserId == null) {
      print("⚠️ Utilisateur non connecté, vérification ignorée arriere");
      return;
    }

    // Récupérer les messages non lus
    var snapshot = await Sms
        .where("receiveId", isEqualTo: currentUserId)
        .where("isRead", isEqualTo: false)
        .get();

    int unreadCount = snapshot.docs.length;

    if (unreadCount > 0) {
      print("🔔 $unreadCount message(s) non lu(s) arriere");

      // Grouper par expéditeur pour plus de détails
      Map<String, int> senderCounts = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String sender = data['namesenderId'] ?? 'Inconnu';
        senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
      }

      print("👥 Par expéditeur: arriere");
      senderCounts.forEach((sender, count) {
        print("   • $sender: $count");
      });

      // Envoyer une notification
      await showBackgroundNotification(unreadCount, senderCounts);
    } else {
      print("✅ Aucun nouveau message arriere");
    }

  } catch (e) {
    print("❌ Erreur checkUnreadMessages arriere: $e");
  }
}

// Fonction de nettoyage
Future<void> performCleanup() async {
  try {
    print("🧹 Nettoyage en cours... arriere");

    // Nettoyer les anciens messages (plus de 30 jours)
    DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

    var oldMessages = await Sms
        .where("timestamp", isLessThan: thirtyDaysAgo)
        .get();

    if (oldMessages.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("✅ ${oldMessages.docs.length} anciens messages supprimés arriere");
    }

    // Autres tâches de nettoyage si nécessaire
    print("✅ Nettoyage terminé arriere");

  } catch (e) {
    print("❌ Erreur performCleanup arriere: $e");
  }
}

// Fonction de synchronisation
Future<void> syncData() async {
  try {
    print("🔄 Synchronisation des données... arriere");

    String? currentUserId = await getCurrentUserId();
    if (currentUserId == null) return;

    // Votre logique de synchronisation ici
    // Par exemple, mettre à jour les statuts, etc.

    print("✅ Synchronisation terminée arriere");

  } catch (e) {
    print("❌ Erreur syncDataarriere: $e");
  }
}

// Fonction pour obtenir l'ID utilisateur depuis SharedPreferences
Future<String?> getCurrentUserId() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userinfo'); // Adaptez selon votre clé
  } catch (e) {
    print("❌ Erreur getCurrentUserId arriere: $e");
    return null;
  }
}

// Fonction pour afficher une notification améliorée
Future<void> showBackgroundNotification(int count, Map<String, int>? senderCounts) async {
  try {
    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();

    // Créer un message détaillé
    String body = 'Vous avez $count nouveau(x) message(s) arriere';

    if (senderCounts != null && senderCounts.isNotEmpty) {
      String details = senderCounts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      body = '$body\nDe: $details';
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'background_channel',
      'Messages Kongossa',
      channelDescription: 'Notifications des messages en arrière-plan',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      color: Colors.deepOrange,
      ledColor: Colors.deepOrange,
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: count,
      ),
    );

    await flip.show(
      DateTime.now().millisecond,
      '📬 Nouveaux messages',
      body,
      platformChannelSpecifics,
    );

    print("📬 Notification envoyée arriere: $body");

  } catch (e) {
    print("❌ Erreur showBackgroundNotification arriere: $e");
  }
}

// Fonction pour planifier toutes les tâches
Future<void> scheduleAllBackgroundTasks() async {
  try {
    // Vérifier les messages toutes les 15 minutes
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

    print("✅ Toutes les tâches planifiées arriere");

  } catch (e) {
    print("❌ Erreur scheduleAllBackgroundTasks arriere: $e");
  }
}

// Fonction pour annuler toutes les tâches
Future<void> cancelAllBackgroundTasks() async {
  await Workmanager().cancelAll();
  print("🛑 Toutes les tâches annulées arriere");
}


// Dans votre main.dart, dans la classe où vous avez initializeOneSignal()

void _showCustomNotification(OSNotification notification) {
  // Afficher une notification personnalisée dans l'application
  print('📱 Affichage personnalisé: ${notification.title}');

  // Option 1: Utiliser un ScaffoldMessenger si vous avez un contexte
  // Mais attention, _showCustomNotification n'a pas accès au contexte ici

  // Option 2: Émettre un événement pour être géré ailleurs
  notificationStreamController.add(notification);
}

// Créer un StreamController pour gérer les notifications
final StreamController<OSNotification> notificationStreamController =
StreamController<OSNotification>.broadcast();

// Getter pour le stream
Stream<OSNotification> get notificationStream => notificationStreamController.stream;


void _configureNotificationHandlers() {
  // Quand l'app est en premier plan
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('📱 Notification reçue en premier plan: ${event.notification.jsonRepresentation()}');

    // Vous pouvez personnaliser l'affichage ici
    event.preventDefault(); // Empêcher l'affichage automatique
    _showCustomNotification(event.notification);
  });

  // Quand l'utilisateur clique sur une notification
  OneSignal.Notifications.addClickListener((event) {
    print('👆 Notification cliquée: ${event.notification.jsonRepresentation()}');
    _handleNotificationClick(event.notification);
  });

  // Récupérer l'ID du joueur (identifiant unique du device)
  OneSignal.User.getOnesignalId().then((id) {
    if (id != null) {
      print('🆔 OneSignal User ID: $id');
      // Sauvegarder cet ID pour envoyer des notifications à ce device
    }
  });
}
// Dans votre main.dart, ajoutez cette fonction
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void _handleNotificationClick(OSNotification notification) {
  print('👆 Notification cliquée: ${notification.title}');

  // Récupérer les données supplémentaires
  final additionalData = notification.additionalData ?? {};
  print('📦 Données: $additionalData');

  // Naviguer vers l'écran approprié selon le type de notification
  final type = additionalData['type'];
  final postId = additionalData['postId'];
  final commentId = additionalData['commentId'];

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
      // Par défaut, aller à l'écran des notifications
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  // Initialiser Firebase Messaging
  final firebaseMessagingService = FirebaseMessagingService.instance();
  await firebaseMessagingService.init(localNotificationsService: localNotificationsService);

  // Initialiser les contrôleurs
  AppControllers.initialize();

  // Initialiser WorkManager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Mettre false en production
  );

  // Planifier les tâches si l'utilisateur est connecté
  String? userId = await getCurrentUserId();
  if (userId != null) {
    await scheduleAllBackgroundTasks();
  }

  // Configurer l'orientation
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.initialize("f29d87f5-87f2-4d83-b47c-93bf3b08ac0c");
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
        return GetMaterialApp(
          title: 'Kongossa',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFEEF1F8),
            primarySwatch: Colors.deepOrange,
            fontFamily: "Intel",
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
              ),
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              errorStyle: TextStyle(height: 0),
              border: defaultInputBorder,
              enabledBorder: defaultInputBorder,
              focusedBorder: defaultInputBorder,
              errorBorder: defaultInputBorder,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            useMaterial3: true,
          ),
          enableLog: false,
          defaultGlobalState: true,
          onInit: () => authController.getUserInfoocally(),
          home: SplashScreen(),
        );
      },
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
);