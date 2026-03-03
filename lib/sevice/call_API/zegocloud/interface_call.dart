import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/sevice/call_API/zegocloud/utils.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class HomeCall extends StatelessWidget {
  HomeCall({super.key});

  final TextEditingController callIDController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appel vidéo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: callIDController,
                decoration: const InputDecoration(
                  labelText: 'ID de l\'appel',
                  border: OutlineInputBorder(),
                  hintText: 'Entrez l\'ID de l\'appel',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (callIDController.text.isNotEmpty) {
                    Get.to(
                          () => CallPage(
                        callID: callIDController.text,
                        userId: DateTime.now().millisecondsSinceEpoch.toString(),
                      ),
                    );
                  } else {
                    Get.snackbar(
                      'Erreur',
                      'Veuillez entrer un ID d\'appel',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text(
                  "Rejoindre",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CallPage extends StatelessWidget {
  final String callID;
  final String userId;

  const CallPage({
    super.key,
    required this.callID,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: utils.appId,
        appSign: utils.appsignId,
        callID: callID,
        userID: userId,
        userName: 'user_$userId',
        config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        // Utiliser le paramètre events pour les callbacks
        events: ZegoUIKitPrebuiltCallEvents(
          onHangUpConfirmation: (event, defaultAction) async {
            final shouldHangUp = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Terminer l\'appel ?'),
                    content: const Text('Voulez-vous vraiment quitter cet appel ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Terminer'),
                      ),
                    ],
                  ),
                );
            return shouldHangUp ?? false;
          },


          // Gérer la fin de l'appel
          onCallEnd: (event, defaultAction) {
            print('Appel terminé : ${event.reason}');

            // Vous pouvez ajouter une logique personnalisée ici
            Get.snackbar(
              'Appel terminé',
              'Raison : ${_getReasonText(event.reason)}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.blue,
              colorText: Colors.white,
            );

            // IMPORTANT: Appeler defaultAction pour retourner à la page précédente
            defaultAction.call();
          },

          // Gérer les erreurs (optionnel)
          onError: (error) {
            print('Erreur d\'appel : $error');
            Get.snackbar(
              'Erreur',
              'Une erreur est survenue : ${error.message}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
          },

          // Suivre les événements utilisateur (optionnel)
          user: ZegoCallUserEvents(
            onEnter: (user) {
              print('Utilisateur entré : ${user.name}');
              Get.snackbar(
                'Nouveau participant',
                '${user.name} a rejoint l\'appel',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            onLeave: (user) {
              print('Utilisateur parti : ${user.name}');
            },
          ),
        ),  
      ),
    );
  }

  // Fonction utilitaire pour traduire les raisons de fin d'appel
  String _getReasonText(ZegoCallEndReason reason) {
    switch (reason) {
      case ZegoCallEndReason.localHangUp:
        return 'Vous avez raccroché';
      case ZegoCallEndReason.remoteHangUp:
        return 'L\'autre participant a raccroché';
      case ZegoCallEndReason.kickOut:
        return 'Vous avez été déconnecté';
      default:
        return 'Raison inconnue';
    }
  }
}

