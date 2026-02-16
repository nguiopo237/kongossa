import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
SplashController s = Get.find();
class SplashController extends GetxController {
  // static SplashController get to => Get.find();

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  DateTime getSafeDateTime(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
    } catch (e) {
      print('Erreur de conversion timestamp: $e');
    }
    return DateTime.now();
  }


  getmodal({Widget? sectionview, states}) {

    Get.bottomSheet(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        isScrollControlled: true,
        // backgroundColor: Colors.transparent,
        Material(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: StatefulBuilder(
              builder: (context, states) {
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10)),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        sectionview!,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ));


  }

  Future<void> initializeApp() async {
    try {
      // Ici vous pouvez ajouter d'autres initialisations
      // Par exemple : vérifier l'authentification, charger des données, etc.

      await Future.delayed(const Duration(seconds: 2)); // Simulation de chargement

      // Navigation vers l'écran principal
      Get.offAllNamed('/onboarding');

    } catch (e) {
      errorMessage.value = 'Erreur d\'initialisation: $e';
      isLoading.value = false;
    }
  }
}