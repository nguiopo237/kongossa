import 'dart:math';

import 'package:animated_gradient_background/animated_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';
import '../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../authentification.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }
  @override
  Widget build(BuildContext context) {
  //   Get.put(SplashController());

    return Scaffold(
     // backgroundColor: const Color(0xFFEEF1F8),
      body: AnimatedGradientBackground(
        begin: Alignment.topLeft,
        end: Alignment.topLeft,
        colors: [
          // Color((Random().nextDouble() * 0xfffe4c06).toInt()).withOpacity(1.0),
          // Color((Random().nextDouble() * 0xfffe7e03).toInt()).withOpacity(1.0),
          // Color((Random().nextDouble() * 0xff0462bc).toInt()).withOpacity(0.5),
          // Color((Random().nextDouble() * 0xff0478c5).toInt()).withOpacity(1.0),
          //  ColorApp.onSecondary,  ColorApp.foreground, ColorApp.primary3,
         // Colors.white,Colors.black
          Color(0xFFEEF1F8),
          Color(0xFFEEF1F8),

        ],

        child: GetBuilder<SplashController>(
          builder: (controller) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Image.asset(Consticon.logo),
                   SizedBox(height: 1.h),

                  // Indicateur de chargement
                  if (controller.isLoading.value)
                    CircularProgressIndicator(padding: EdgeInsets.zero,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorApp.primary,
                      ),
                      color: ColorApp.primary1,
                      backgroundColor: ColorApp.primary2,

                    ),

                  // Message d'erreur
                  if (controller.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            controller.errorMessage.value,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              controller.initializeApp();
                            },
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}