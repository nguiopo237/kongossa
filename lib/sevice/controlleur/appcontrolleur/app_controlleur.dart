import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  final isInForeground = true.obs;
  final lastState = AppLifecycleState.resumed.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    print("📱 Service de cycle de vie initialisé");
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    lastState.value = state;

    switch (state) {
      case AppLifecycleState.resumed:
        isInForeground.value = true;
        print("📱 PREMIER PLAN - Application active");
        if(AppUser.info?.googleId!=null){
          AppUser.info?.isonline =true;
          Users.doc(AppUser.info?.userI).update({"isOnline":true});
        }
        print( AppUser.info?.isonline);
        _onForeground();
        break;

      case AppLifecycleState.paused:
        isInForeground.value = false;
        if(AppUser.info?.googleId!=null){
          Users.doc(AppUser.info?.userI).update({"isOnline":false});
          AppUser.info?.isonline =false;
        }
        print("📱 ARRIÈRE-PLAN - Application minimisée");
        print( AppUser.info?.isonline);

        _onBackground();
        break;

      case AppLifecycleState.inactive:
        if(AppUser.info?.googleId!=null){
          Users.doc(AppUser.info?.userI).update({"isOnline":false});
          AppUser.info?.isonline =false;
        }
        print("📱 INACTIF - Écran de verrouillage/Appel");
        print( AppUser.info?.isonline);

        break;

      case AppLifecycleState.detached:
        isInForeground.value = false;
        if(AppUser.info?.googleId!=null){
          Users.doc(AppUser.info?.userI).update({"isOnline":false});
          AppUser.info?.isonline =false;
        }
        print("📱 DÉTACHÉE - Application va être fermée");
        print( AppUser.info?.isonline);
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        if(AppUser.info?.googleId!=null){
          Users.doc(AppUser.info?.userI).update({"isOnline":false});
          AppUser.info?.isonline =false;
        }
        print( AppUser.info?.isonline);
        // throw UnimplementedError();
    }
  }

  void _onForeground() {
    // Actions à faire quand l'app revient au premier plan
    print("🔄 Rafraîchissement des données au retour");
    // Exemple: rafraîchir les données utilisateur
  }

  void _onBackground() {
    // Actions à faire quand l'app passe en arrière-plan
    print("💾 Sauvegarde de l'état avant passage en arrière-plan");
    // Exemple: sauvegarder l'état, fermer les connexions
  }

  bool get isForeground => isInForeground.value;
  bool get isBackground => !isInForeground.value;
}