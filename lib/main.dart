import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/screens/authentification.dart';

import 'package:kongossa/screens/onboding/onboding_screen.dart';
import 'package:kongossa/screens/splashscreen/splaschsreen.dart';
import 'package:kongossa/sevice/controlleur/authentification/auth_controlleur.dart';
import 'package:kongossa/sevice/controlleur/init_controlleur/init_controlleur.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'firebase_options.dart';

CollectionReference Users = FirebaseFirestore.instance.collection(
  'user',
);
CollectionReference Posts = FirebaseFirestore.instance.collection(
  'postcarduser',
);



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avant de lancer l'application
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Cache illimité
  );
  AppControllers.initialize();
  runApp(const MyApp());
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
          ),
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
