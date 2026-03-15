import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/sevice/call_API/zegocloud/utils.dart';
import 'package:zego_plugin_adapter/zego_plugin_adapter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../../../model/datamodel/user_model.dart';

class Call{
 static Future<void> loginUser() async {
    // Générer un ID utilisateur unique


    // Initialiser le service d'invitation APRÈS la connexion utilisateur
    await ZegoUIKitPrebuiltCallInvitationService().init(
      appID: utils.appId,
      appSign: utils.appsignId,
      userID: AppUser.info!.googleId,
      userName: AppUser.info!.displayName,
      plugins: [ZegoUIKitSignalingPlugin()],
      // Configuration des notifications
      notificationConfig: ZegoCallInvitationNotificationConfig(
        androidNotificationConfig: ZegoAndroidNotificationConfig(
          channelID: 'zego_call_channel',
          channelName: 'Appels vidéo',
          sound: 'incoming_call.mp3',
        ),
      ),
      // Événements d'invitation
      invitationEvents: ZegoUIKitPrebuiltCallInvitationEvents(
        // 📞 Quand un appel entrant est reçu
        onIncomingCallReceived: (String callID, ZegoCallUser caller,
            ZegoCallInvitationType callType, List<ZegoCallUser> callees,
            String customData) {
          print('📞 Appel entrant de : ${caller.name}');
          // Get.snackbar(
          //   'Appel entrant',
          //   '${caller.name} vous appelle...',
          //   snackPosition: SnackPosition.TOP,
          //   backgroundColor: Colors.green,
          //   colorText: Colors.white,
          //   duration: const Duration(seconds: 10),
          // );
        },

        // ❌ Quand l'appel entrant est annulé par l'appelant
        onIncomingCallCanceled: (String callID, ZegoCallUser caller,
            String customData) {
          print('❌ Appel annulé par ${caller.name}');
          Get.snackbar(
            'Appel annulé',
            '${caller.name} a annulé l\'appel',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        },

        // ⏱️ Quand l'appel entrant expire (pas de réponse)
        onIncomingCallTimeout: (String callID, ZegoCallUser caller) {
          print('⏱️ Appel entrant expiré de ${caller.name}');
          Get.snackbar(
            'Appel manqué',
            'Vous n\'avez pas répondu à l\'appel de ${caller.name}',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey,
            colorText: Colors.white,
          );
        },

        // ✅ Quand l'appel entrant est accepté
        onIncomingCallAcceptButtonPressed: () {
          print('✅ Bouton accepter pressé');
        },

        // ❌ Quand l'appel entrant est refusé
        onIncomingCallDeclineButtonPressed: () {
          print('❌ Bouton refuser pressé');
        },

        // ✅ Quand l'appel sortant est accepté par le destinataire
        onOutgoingCallAccepted: (String callID, ZegoCallUser callee) {
          print('✅ Appel accepté par ${callee.name}');
          Get.snackbar(
            'Appel accepté',
            '${callee.name} a accepté l\'appel',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        },

        // ❌ Quand l'appel sortant est refusé par le destinataire
        onOutgoingCallDeclined: (String callID, ZegoCallUser callee,
            String customData) {
          print('❌ Appel refusé par ${callee.name}');
          Get.snackbar(
            'Appel refusé',
            '${callee.name} a refusé l\'appel',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },

        // 📞 Quand le destinataire est en ligne mais occupé (déjà en appel)
        onOutgoingCallRejectedCauseBusy: (String callID, ZegoCallUser callee,
            String customData) {
          print('📞 ${callee.name} est en ligne mais occupé(e)');
          Get.snackbar(
            'Occupé',
            '${callee.name} est déjà en appel',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        },

        // ⏱️ Quand l'appel sortant expire (pas de réponse)
        onOutgoingCallTimeout: (String callID, List<ZegoCallUser> callees,
            bool isVideoCall) {
          print('⏱️ Appel sortant expiré');
          Get.snackbar(
            'Appel sans réponse',
            'Le destinataire n\'a pas répondu',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey,
            colorText: Colors.white,
          );
        },

        // 📤 Quand l'invitation est envoyée avec succès
        onOutgoingCallSent: (String callID, ZegoCallUser caller,
            ZegoCallInvitationType callType, List<ZegoCallUser> callees,
            String customData) {
          print('📤 Invitation envoyée avec succès');
        },

        // 🔄 Quand l'état des utilisateurs change
        onInvitationUserStateChanged: (List<ZegoSignalingPluginInvitationUserInfo> userInfos) {
          print('🔄 Changement d\'état utilisateur');
        },

        // ⚠️ Gestion des erreurs
        onError: (ZegoUIKitError error) {
          print('⚠️ Erreur: ${error.message}');
          Get.snackbar(
            'Erreur',
            error.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        },
      ),
    );

    print('✅ Service d\'appel initialisé pour ${AppUser.info!.googleId}');
  }


  static void startCall({required String targetUserId,required String nameuser, required bool isVideoCall}) {
   // Envoyer une invitation - Note: utiliser 'send' au lieu de 'sendInvitation'
   ZegoUIKitPrebuiltCallInvitationService().send(
     invitees: [
       ZegoCallUser(
         targetUserId,
         nameuser,
       ),
     ],
     isVideoCall: isVideoCall, // true pour vidéo, false pour audio
     timeoutSeconds: 60,
     // Pour les notifications hors ligne (à configurer dans la console)
     resourceID: 'zego_call_notification',
     notificationTitle: isVideoCall ? 'Appel vidéo' : 'Appel audio',
     notificationMessage: 'Cliquez pour répondre',
     customData: 'verification', // Données personnalisées optionnelles
   ).then((success) {
     if (success) {
       // Get.snackbar(
       //   'Succès',
       //   'Invitation envoyée !',
       //   snackPosition: SnackPosition.BOTTOM,
       //   backgroundColor: Colors.green,
       //   colorText: Colors.white,
       // );
     } else {
       Get.snackbar(
         'Erreur',
         'Échec de l\'envoi de l\'invitation',
         snackPosition: SnackPosition.BOTTOM,
         backgroundColor: Colors.red,
         colorText: Colors.white,
       );
     }
   });
 }

}