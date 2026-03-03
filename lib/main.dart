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
import 'package:kongossa/sevice/call_API/zegocloud/interface_call.dart';
import 'package:kongossa/sevice/call_API/zegocloud/interface_receive.dart';
import 'package:kongossa/sevice/controlleur/appcontrolleur/app_controlleur.dart';
import 'package:kongossa/sevice/controlleur/authentification/auth_controlleur.dart';
import 'package:kongossa/sevice/controlleur/init_controlleur/init_controlleur.dart';
import 'package:kongossa/sevice/controlleur/notification/chat_notificationservice/one_signalservice.dart';
import 'package:kongossa/sevice/controlleur/notification/configservice.dart';

import 'package:kongossa/sevice/controlleur/notification/local_notifications_service.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'firebase_options.dart';
import 'model/datamodel/user_model.dart';

CollectionReference Users = FirebaseFirestore.instance.collection('user');
CollectionReference Posts = FirebaseFirestore.instance.collection(
  'postcarduser',
);
CollectionReference Sms = FirebaseFirestore.instance.collection('message');
CollectionReference notif = FirebaseFirestore.instance.collection(
  'notification',
);

String? currentPlayerId;

// Callback pour WorkManager (s'exécute en arrière-plan)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🔄 Tâche en arrière-plan: $task");
    print("📦 Données: $inputData");

    try {
      switch (task) {
        case "checkMessagesTask":
          await authController.setupMessagesListener();
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

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Fonction pour vérifier les messages non lus
// Future<void> checkUnreadMessages() async {
//   try {
//     print("🔍 Vérification des messages non lus arriere...");
//
//     // Récupérer l'ID utilisateur depuis SharedPreferences
//     // String? currentUserId = await getCurrentUserId();
//
//     if (currentUserId == null) {
//       print("⚠️ Utilisateur non connecté, vérification ignorée arriere");
//       return;
//     }
//
//     // Récupérer les messages non lus
//     var snapshot = await Sms
//         .where("receiveId", isEqualTo: currentUserId)
//         .where("isRead", isEqualTo: false)
//         .get();
//
//     int unreadCount = snapshot.docs.length;
//
//     if (unreadCount > 0) {
//       print("🔔 $unreadCount message(s) non lu(s) arriere");
//
//       // Grouper par expéditeur pour plus de détails
//       Map<String, int> senderCounts = {};
//       for (var doc in snapshot.docs) {
//         var data = doc.data() as Map<String, dynamic>;
//         String sender = data['namesenderId'] ?? 'Inconnu';
//         senderCounts[sender] = (senderCounts[sender] ?? 0) + 1;
//       }
//
//       print("👥 Par expéditeur: arriere");
//       senderCounts.forEach((sender, count) {
//         print("   • $sender: $count");
//       });
//
//       // Envoyer une notification
//       await showBackgroundNotification(unreadCount, senderCounts);
//     } else {
//       print("✅ Aucun nouveau message arriere");
//     }
//
//   } catch (e) {
//     print("❌ Erreur checkUnreadMessages arriere: $e");
//   }
// }

Future<void> setupMessagesListener() async {
  print("🔍 Vérification des messages non lus arriere...");
  notif
      .where("receiveId", isEqualTo: AppUser.info!.googleId)
      .orderBy("timestamp", descending: false)
      .snapshots()
      .listen((QuerySnapshot snapshot) {
        for (var change in snapshot.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
              var data = change.doc.data() as Map<String, dynamic>;
              String content = data['content'] ?? '';
              print("✏️ Message modifié: ${content}");
              // showSimpleNotification(message: data);
              break;
            case DocumentChangeType.modified:
              var data = change.doc.data() as Map<String, dynamic>;
              String content = data['content'] ?? '';
              print("✏️ Message modifié: ${content}");
              // showSimpleNotification(message: data);
              break;
            case DocumentChangeType.removed:
              print("❌ Message supprimé: ${change.doc.data()}");
              break;
          }
        }
      });
}

// Fonction de nettoyage
Future<void> performCleanup() async {
  try {
    print("🧹 Nettoyage en cours... arriere");

    // Nettoyer les anciens messages (plus de 30 jours)
    DateTime thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));

    var oldMessages = await Sms.where(
      "timestamp",
      isLessThan: thirtyDaysAgo,
    ).get();

    if (oldMessages.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in oldMessages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("✅ ${oldMessages.docs.length} anciens messages supprimés arriere");
    }

    print("✅ Nettoyage terminé arriere");
  } catch (e) {
    print("❌ Erreur performCleanup arriere: $e");
  }
}

// Fonction de synchronisation
Future<void> syncData() async {
  try {
    print("🔄 Synchronisation des données... arriere");

    // String? currentUserId = await getCurrentUserId();
    // if (currentUserId == null) return;

    print("✅ Synchronisation terminée arriere");
  } catch (e) {
    print("❌ Erreur syncDataarriere: $e");
  }
}

// Fonction pour obtenir l'ID utilisateur depuis SharedPreferences
// Future<String?> getCurrentUserId() async {
//   try {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getString('userinfo');
//   } catch (e) {
//     print("❌ Erreur getCurrentUserId arriere: $e");
//     return null;
//   }
// }

// Fonction pour afficher une notification améliorée
Future<void> showBackgroundNotification(
  int count,
  Map<String, int>? senderCounts,
) async {
  try {
    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();

    String body = 'Vous avez $count nouveau(x) message(s) arriere';

    if (senderCounts != null && senderCounts.isNotEmpty) {
      String details = senderCounts.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
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

    await Workmanager().registerPeriodicTask(
      "cleanupTask",
      "cleanupTask",
      frequency: Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.connected),
    );

    await Workmanager().registerPeriodicTask(
      "syncDataTask",
      "syncDataTask",
      frequency: Duration(minutes: 30),
      constraints: Constraints(networkType: NetworkType.connected),
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

// StreamController pour gérer les notifications
final StreamController<OSNotification> notificationStreamController =
    StreamController<OSNotification>.broadcast();

Stream<OSNotification> get notificationStream =>
    notificationStreamController.stream;

// Clé globale pour la navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Variable pour suivre l'overlay actuel
OverlayEntry? _currentOverlayEntry;

// Fonction pour personnaliser l'affichage des notifications OneSignal
void _showCustomNotification(OSNotification notification) {
  print('📱 Affichage personnalisé: ${notification.title}');

  // Récupérer toutes les données
  final title = notification.title ?? 'Nouvelle notification';
  final body = notification.body ?? '';
  final additionalData = notification.additionalData ?? {};

  // Analyser le type de notification
  final type = additionalData['type'] ?? 'unknown';
  final senderName = additionalData['senderName'] ?? 'Quelqu\'un';

  // PERSONNALISATION SELON LE TYPE
  String displayTitle = title;
  String displayBody = body;
  IconData icon = Icons.notifications;
  Color color = Colors.blue;

  switch (type) {
    case 'like':
      displayTitle = '❤️ Nouveau like';
      displayBody = '$senderName a aimé votre publication';
      icon = Icons.favorite;
      color = Colors.red;
      break;

    case 'comment':
      displayTitle = '💬 Nouveau commentaire';
      displayBody = '$senderName a commenté votre post';
      icon = Icons.comment;
      color = Colors.green;
      break;

    case 'follow':
      displayTitle = '👥 Nouvel abonné';
      displayBody = '$senderName a commencé à vous suivre';
      icon = Icons.person_add;
      color = Colors.purple;
      break;

    case 'chat_message':
      displayTitle = '✉️ Nouveau message';
      displayBody = '$senderName: $body';
      icon = Icons.message;
      color = Colors.orange;
      break;
  }

  // CHOISIR UN SEUL MODE D'AFFICHAGE (Overlay est plus élégant)
  _showCustomOverlayNotification(
    notification,
    displayTitle,
    displayBody,
    icon,
    color,
  );

  // Émettre via le StreamController
  notificationStreamController.add(notification);
}

// Overlay personnalisé (élégant)
// NOUVELLE VERSION - Avec images !
void _showCustomOverlayNotification(
  OSNotification notification,
  String title,
  String body,
  IconData icon,
  Color color,
) {
  final context = navigatorKey.currentContext;
  if (context == null) return;

  // Récupérer l'URL de l'image depuis les données supplémentaires
  final additionalData = notification.additionalData ?? {};
  final imageUrl = additionalData['imageUrl'];
  final senderPhoto = additionalData['senderPhoto'];
  print("voici kesdsd  :   ${additionalData['imageUrl']}");

  // Supprimer l'overlay précédent s'il existe
  _currentOverlayEntry?.remove();

  _currentOverlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 50,
      left: 10,
      right: 10,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            _currentOverlayEntry?.remove();
            _currentOverlayEntry = null;
            _handleNotificationClick(notification);
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image à gauche (photo de profil ou icône)
                if (senderPhoto != null && senderPhoto.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Image.network(
                      senderPhoto,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // En cas d'erreur de chargement, afficher l'icône par défaut
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: Colors.white, size: 30),
                        );
                      },
                    ),
                  )
                else
                  // Pas de photo, afficher l'icône du TYPE (❤️, 💬, etc.)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),

                SizedBox(width: 12),

                // Contenu texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Image supplémentaire si présente
                      if (imageUrl != null && imageUrl.isNotEmpty) ...[
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            height: 80,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 80,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Text('Image non disponible'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Bouton fermer
                GestureDetector(
                  onTap: () {
                    _currentOverlayEntry?.remove();
                    _currentOverlayEntry = null;
                  },
                  child: Icon(Icons.close, color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Overlay.of(context).insert(_currentOverlayEntry!);

  // Auto-disparition après 5 secondes
  Future.delayed(Duration(seconds: 5), () {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  });
}

void _configureNotificationHandlers() {
  // Quand l'app est en premier plan
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print(
      '📱 Notification reçue en premier plan: ${event.notification.jsonRepresentation()}',
    );
    event.preventDefault();
    _showCustomNotification(event.notification);
  });

  // Quand l'utilisateur clique sur une notification
  OneSignal.Notifications.addClickListener((event) {
    print(
      '👆 Notification cliquée: ${event.notification.jsonRepresentation()}',
    );
    _handleNotificationClick(event.notification);
  });

  // Récupérer l'ID du joueur
  OneSignal.User.getOnesignalId().then((id) {
    if (id != null) {
      print('🆔 OneSignal User ID: $id');
    }
  });
}

void _handleNotificationClick(OSNotification notification) {
  print('👆 Notification cliquée: ${notification.title}');

  final additionalData = notification.additionalData ?? {};
  print('📦 Données: $additionalData');

  final type = additionalData['type'];
  final postId = additionalData['postId'];
  final commentId = additionalData['commentId'];

  final context = navigatorKey.currentContext;
  if (context != null) {
    if (type == 'like' && postId != null) {
      navigatorKey.currentState?.pushNamed('/post', arguments: postId);
    } else if (type == 'comment' && postId != null) {
      navigatorKey.currentState?.pushNamed('/comments', arguments: postId);
    } else if (type == 'follow') {
      navigatorKey.currentState?.pushNamed(
        '/profile',
        arguments: additionalData['userId'],
      );
    } else {
      navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final lifecycleService = AppLifecycleService();
  await Get.putAsync(() async => lifecycleService);

  await initializeDateFormatting('fr_FR', null);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // final lifecycleService = AppLifecycleService();
  // await Get.putAsync(() async => lifecycleService);
  // await initializeDateFormatting('fr_FR', null);
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FirebaseFirestore.instance.settings = const Settings(
  //   persistenceEnabled: true,
  //   cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  // );
  //
  // final localNotificationsService = LocalNotificationsService.instance();
  // await localNotificationsService.init();

  // final firebaseMessagingService = FirebaseMessagingService.instance();
  // await firebaseMessagingService.init(localNotificationsService: localNotificationsService);

  // AppControllers.initialize();

  // await Workmanager().initialize(
  //   callbackDispatcher,
  //   isInDebugMode: true,
  // );

  // String? userId = await getCurrentUserId();
  // if (userId != null) {
  //   await scheduleAllBackgroundTasks();
  // }
  // ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  // await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
  //   ZegoUIKitSignalingPlugin(),
  // ]);
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((
  //   _,
  // ) async {
    // await OneSignalKeyManager.getOneSignalAppId();

    // final configService = ConfigService();
    // final oneSignalAppId = await configService.getOneSignalAppId();
    // print("oneSignalAppId");
    // print(oneSignalAppId);
    // print("oneSignalAppId");
    //
    // if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
    //   OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    //   OneSignal.initialize(oneSignalAppId); // Utilisation de la clé récupérée
    //   OneSignal.Notifications.requestPermission(true);
    //   _configureNotificationHandlers();
    // } else {
    //   print('❌ Impossible de récupérer l\'App ID OneSignal');
    //   // Option: afficher un message à l'utilisateur ou réessayer
    //   // }
    // }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      print('❌ Flutter Error: ${details.exception}');
    };
    try {
      await initializeApp();
      runApp(MyApp());
    } catch (e, stackTrace) {
      print('❌ Fatal Error during initialization: $e');
      print(stackTrace);

      // Show error screen in development, white screen in production
      runApp(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Error initializing app: $e')),
          ),
        ),
      );
    }

}

Future<void> initializeApp() async {


  // Initialize Firebase with error handling
  try {

  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    rethrow;
  }



  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();

  AppControllers.initialize();

  ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
  await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI([
    ZegoUIKitSignalingPlugin(),
  ]);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Handle OneSignal initialization
  try {
    final configService = ConfigService();
    final oneSignalAppId = await configService.getOneSignalAppId();
    print("📱 OneSignal App ID: $oneSignalAppId");

    if (oneSignalAppId != null && oneSignalAppId.isNotEmpty) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(oneSignalAppId);
      OneSignal.Notifications.requestPermission(true);
      _configureNotificationHandlers();
    } else {
      print('⚠️ OneSignal App ID is null or empty - notifications disabled');
    }
  } catch (e) {
    print('❌ OneSignal initialization failed: $e');
    // Continue without OneSignal
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          navigatorKey: navigatorKey,
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
          // enableLog: false,
          defaultGlobalState: true,
          onInit: () => authController.getUserInfoocally(),
          // home: HomeCall(),
          home: SplashScreen(),
          // home: HomePage(),
          // home: VideoEditorExample(),
          // home: VideoEditorExample(),
        );
      },
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
);
