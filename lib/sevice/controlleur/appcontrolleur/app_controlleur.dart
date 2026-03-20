import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../call_API/zegocloud/zecloud_fonction.dart';

class AppLifecycleService extends GetxService with WidgetsBindingObserver {
  final isInForeground = true.obs;
  final lastState = AppLifecycleState.resumed.obs;

  // Timer pour éviter les mises à jour trop fréquentes
  Timer? _debounceTimer;
  bool _isUpdatingOnlineStatus = false;

  // Constantes Zego - À remplacer par vos vraies valeurs
  static const int _zegoAppID = 0; // Remplacez par votre appID
  static const String _zegoAppSign = ''; // Remplacez par votre appSign

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    print("📱 Service de cycle de vie initialisé");
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = lastState.value;
    lastState.value = state;

    print("📱 Changement d'état: $previousState -> $state");

    switch (state) {
      case AppLifecycleState.resumed:
        _handleForeground();
        break;

      case AppLifecycleState.paused:
        _handleBackground();
        break;

      case AppLifecycleState.inactive:
        _handleInactive();
        break;

      case AppLifecycleState.detached:
        _handleDetached();
        break;

      case AppLifecycleState.hidden:
        _handleHidden();
        break;
    }
  }

  void _handleForeground() {
    isInForeground.value = true;
    print("📱 PREMIER PLAN - Application active");

    // Réinitialiser Zego quand l'app revient au premier plan
    _reinitializeZego();

    // Mettre à jour le statut en ligne avec debounce
    _updateOnlineStatus(true);
  }

  void _handleBackground() {
    isInForeground.value = false;
    print("📱 ARRIÈRE-PLAN - Application minimisée");

    // IMPORTANT: Nettoyer Zego avant de passer en arrière-plan
    _cleanupZegoForBackground();

    // Mettre à jour le statut hors ligne
    _updateOnlineStatus(false);

    _onBackground();
  }

  void _handleInactive() {
    print("📱 INACTIF - Écran de verrouillage/Appel");

    // En inactif, on met à jour le statut mais on garde Zego si possible
    if (AppUser.info?.googleId != null) {
      _updateOnlineStatus(false);
    }
  }

  void _handleDetached() {
    isInForeground.value = false;
    print("📱 DÉTACHÉE - Application va être fermée");

    // Nettoyage complet avant fermeture
    _completeCleanup();
  }

  void _handleHidden() {
    print("📱 CACHÉE - Application cachée");
    if (AppUser.info?.googleId != null) {
      _updateOnlineStatus(false);
    }
  }

  void _updateOnlineStatus(bool isOnline) async {
    // Éviter les mises à jour concurrentes
    if (_isUpdatingOnlineStatus) return;

    // Vérifier que l'utilisateur est connecté
    if (AppUser.info?.googleId == null || AppUser.info?.userI == null) {
      return;
    }

    _isUpdatingOnlineStatus = true;

    // Debounce pour éviter trop de mises à jour
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        // Mettre à jour localement
        AppUser.info?.isonline = isOnline;

        // Mettre à jour dans Firestore
        await Users.doc(AppUser.info?.userI).update({
          "isOnline": isOnline,
          "lastSeen": FieldValue.serverTimestamp(),
        });

        print("📱 Statut en ligne mis à jour: $isOnline");
      } catch (e) {
        print("❌ Erreur mise à jour statut: $e");
      } finally {
        _isUpdatingOnlineStatus = false;
      }
    });
  }

  void _reinitializeZego() {
    // Ne pas réinitialiser si l'appID n'est pas configuré
    if (_zegoAppID == 0 || _zegoAppSign.isEmpty) {
      print("⚠️ Zego non configuré - Ignorer la réinitialisation");
      return;
    }

    try {
      print("🔄 Réinitialisation de Zego...");

      // Réinitialiser Zego UIKit
      if (AppUser.info?.userI != null) {
        Call.loginUser();
      }
    } catch (e) {
      print("❌ Exception lors de la réinitialisation Zego: $e");
    }
  }

  void _cleanupZegoForBackground() {
    // Ne pas nettoyer si l'appID n'est pas configuré
    if (_zegoAppID == 0 || _zegoAppSign.isEmpty) {
      return;
    }

    try {
      print("🧹 Nettoyage Zego pour l'arrière-plan...");

      // Désactiver les notifications et appels en arrière-plan
  ZegoUIKitPrebuiltCallInvitationService().uninit();


      // Optionnel: Déconnecter mais garder la session
      // ZegoUIKitCore.shared.logout();

      print("✅ Zego nettoyé pour l'arrière-plan");
    } catch (e) {
      print("❌ Erreur nettoyage Zego: $e");
    }
  }

  void _completeCleanup() {
    // Ne pas nettoyer si l'appID n'est pas configuré
    if (_zegoAppID == 0 || _zegoAppSign.isEmpty) {
      return;
    }

    try {
      print("🧹 Nettoyage complet...");

      // Nettoyage Zego
  ZegoUIKitPrebuiltCallInvitationService().uninit();

      // Mettre à jour le statut hors ligne une dernière fois
      if (AppUser.info?.googleId != null && AppUser.info?.userI != null) {
        Users.doc(AppUser.info?.userI).update({
          "isOnline": false,
          "lastSeen": FieldValue.serverTimestamp(),
        }).catchError((e) {
          print("❌ Erreur mise à jour finale: $e");
        });
      }

      print("✅ Nettoyage complet terminé");
    } catch (e) {
      print("❌ Erreur nettoyage complet: $e");
    }
  }

  void _onBackground() {
    print("💾 Sauvegarde de l'état avant passage en arrière-plan");
    // Sauvegarder l'état local si nécessaire
    _saveAppState();
  }

  void _saveAppState() {
    // Implémentez la sauvegarde de l'état si nécessaire
    // Par exemple: sauvegarder la position de scroll, les données temporaires, etc.
  }

  bool get isForeground => isInForeground.value;
  bool get isBackground => !isInForeground.value;

  // Méthode pour configurer Zego avec les vraies valeurs
  void configureZego({required int appID, required String appSign}) {
    // Cette méthode permet de configurer Zego depuis l'extérieur
    // _zegoAppID = appID; // Ne peut pas être modifié car ce sont des constantes
    // Pour modifier, il faudrait les rendre non-constantes
    print("⚠️ Pour configurer Zego, modifiez directement _zegoAppID et _zegoAppSign dans le fichier");
  }
}