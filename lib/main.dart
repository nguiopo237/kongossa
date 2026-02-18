import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:kongossa/screens/authentification.dart';

import 'package:kongossa/screens/onboding/onboding_screen.dart';
import 'package:kongossa/screens/splashscreen/splaschsreen.dart';
import 'package:kongossa/sevice/controlleur/authentification/auth_controlleur.dart';
import 'package:kongossa/sevice/controlleur/init_controlleur/init_controlleur.dart';
import 'package:kongossa/sevice/controlleur/notification/firebase_messaging_service.dart';
import 'package:kongossa/sevice/controlleur/notification/local_notifications_service.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'firebase_options.dart';

CollectionReference Users = FirebaseFirestore.instance.collection(
  'user',
);
CollectionReference Posts = FirebaseFirestore.instance.collection(
  'postcarduser',
);
CollectionReference Sms = FirebaseFirestore.instance.collection(
  'message',
);



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  // Initialiser Firebase avant de lancer l'application
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Cache illimité
  );

  final localNotificationsService = LocalNotificationsService.instance();
  await localNotificationsService.init();
  final firebaseMessagingService = FirebaseMessagingService.instance();
  await firebaseMessagingService.init(localNotificationsService: localNotificationsService);


  AppControllers.initialize();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
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
        //  initialBinding: AppBinding(),
        //onInit: () => AppControllers.initialize(),
        onInit: () => authController.getUserInfoocally(),
        //  onReady: authController.getUserInfoocally,
          home: const SplashScreen(),
          // Écran de démarrage avec GetX
          // getPages: [
          //   GetPage(
          //     name: '/onboarding',
          //     // page: () => LoginScreen(),
          //     page: () => OnbodingScreen(),
          //   ),
          //   // Ajoutez vos autres routes ici
          // ],
        );
      },
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
);
