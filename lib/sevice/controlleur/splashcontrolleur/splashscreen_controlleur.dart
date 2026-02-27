import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../config_App/colorsApp.dart';
import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../presentation/component/image_component/image.dart';
import '../../../presentation/component/widget/select_media.dart';
import '../../../presentation/component/widget/widget_component.dart';
SplashController s = Get.find();
class SplashController extends GetxController {
  // static SplashController get to => Get.find();

  final isLoading = true.obs;
  final errorMessage = ''.obs;
  StreamSubscription? subscription;
  RxBool isDeviceConnected = false.obs;
  RxBool isAlertSet = false.obs;
  RxList reply = [].obs;
  RxList <String> attachedVideos = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  List<String> assets = [
    'assets/Backgrounds/up.png',
    'assets/Backgrounds/up2.png',
    'assets/Backgrounds/up3.png',
    'assets/Backgrounds/up4.png',
    'assets/Backgrounds/up5.png',
    'assets/Backgrounds/up6.png',
  ];


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

  Widget buildProfileShimmer() {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 4.w,
          height: 4.w,
          child: CircularProgressIndicator(
            strokeWidth: 0.3.w,
            valueColor: AlwaysStoppedAnimation<Color>(ColorApp.primary1),
          ),
        ),
      ),
    );
  }

  Widget buildDefaultProfile() {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorApp.primary1.withOpacity(0.1),
            ColorApp.primary2.withOpacity(0.1),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CupertinoIcons.person_crop_circle,
        color: ColorApp.primary1,
        size: 8.w,
      ),
    );
  }

  Widget buildProfileContent(
      {DocumentSnapshot? document, double ?width = 10, double ?height = 10}) {
    return Container(
      padding: EdgeInsets.all(0.5.w),
      decoration: BoxDecoration(
        gradient: SweepGradient(
          colors: [
            ColorApp.primary1,
            ColorApp.primary2,
            ColorApp.primary3,
            ColorApp.primary1,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        padding: EdgeInsets.all(0.3.w),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: document!["photoUrl"] == null || document["photoUrl"] == ""
                  ? Container(
                width: width!.w,
                height: height!.w,
                color: Colors.grey[100],
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 6.w,
                  color: Colors.grey[400],
                ),
              )
                  : CustomImage(
                source: document["photoUrl"]!,
                type: ImageType.cachedNetwork,
                width: width!.w,
                height: height!.w,
                fit: BoxFit.cover,
              ),
            ),

            // Badge de statut en ligne
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 2.5.w,
                height: 2.5.w,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 0.2.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Bouton d'upload
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  WidgetComponent.getmodal(
                    sectionview: Container(
                      height: 60.h,
                      child: PremiumMediaSelector(
                        onSourceSelected: (p1) {},
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        ColorApp.primary1,
                        ColorApp.primary2,
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 0.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorApp.primary1.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo_rounded,
                    color: Colors.white,
                    size: 2.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget buildUserProfile({double ?width = 10, double ?height = 10,uid}) {
    return StreamBuilder(
      stream: Users.where('googleId', isEqualTo: uid??AppUser.info?.googleId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return buildProfileShimmer();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return buildDefaultProfile();
        }

        try {
          final document = snapshot.data!.docs.first;
          return buildProfileContent(document: document,height:height,width: width );
        } catch (e) {
          return buildDefaultProfile();
        }
      },
    );
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