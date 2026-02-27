import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../screens/entryPoint/entry_point.dart';
import '../../../screens/onboding/onboding_screen.dart';
import '../../../screens/test_image_send.dart';
final AuthController authController = Get.find();
class AuthController extends GetxController {
  // static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final user = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isGoogleSignInAvailable = true.obs;



  final RxString verificationId = ''.obs;
  final RxString smsCode = ''.obs;

  final RxBool codeSent = false.obs;
  final RxInt  indexpage  = 0.obs;
  final RxInt  notification  = 0.obs;

  final RxInt resendTimer = 0.obs;
  final RxBool canResend = true.obs;
  Timer? _resendTimer;
  String? _currentToken;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    print("user");
    print(user);
    print("user");
  }

  @override
  void onReady() {

    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      this.user.value = user;
      print("user");
      print(user);
      print("user");
    });
    super.onReady();
  }

  Future<String?> getCurrentToken() async {
    print("start");
    User? user = _auth.currentUser;
    if (user != null) {
      _currentToken = await user.getIdToken();
      print(_currentToken);
      print(user.uid);
      return _currentToken;
    }
    return null;
  }






  Future<String?> getFirebaseToken() async {


    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('Permission refusée');
    }


    String? token = await _fcm.getToken();
    print('Token FCM: $token');
    _fcm.onTokenRefresh.listen((newToken) {
      print('Nouveau token: $newToken');
      // Mettre à jour le token dans votre base de données si nécessaire
    });
  }



  // Méthode de connexion
  Future<void> signInWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      Get.offAllNamed('/home'); // Redirection après connexion
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Une erreur est survenue';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Authentification avec Google
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        // L'utilisateur a annulé
        isLoading.value = false;
        print("❌ Connexion annulée par l'utilisateur");
        return;
      } else {
        print("✅ Utilisateur Google authentifié");
        print("📧 Email: ${googleAccount.email}");
      }

      // 2. Vérifier si l'utilisateur existe déjà dans la base de données
      QuerySnapshot querySnapshot = await Users
          .where('googleId', isEqualTo: googleAccount.id?.trim())
          .limit(1)
          .get();

      String userId;

      if (querySnapshot.docs.isEmpty) {
        print("🆕 Création d'un nouvel utilisateur...");

        // 3. Créer un nouvel utilisateur - UNE SEULE FOIS
        final userData = {
          "email": googleAccount.email,
          "googleId": googleAccount.id,
          "name": googleAccount.displayName,
          "photoUrl": googleAccount.photoUrl,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          "lastLogin": FieldValue.serverTimestamp(),
        };

        // Ajouter le document et récupérer l'ID (une seule fois)
        DocumentReference docRef = await Users.add(userData);
        userId = docRef.id;

        // Optionnel: Mettre à jour avec l'ID du document si nécessaire
        await docRef.update({
          'userId': userId, // ou 'userI': userId si vous voulez garder cette clé
        });

        print("✅ Nouvel utilisateur créé");
        print("📧 Email: ${googleAccount.email}");
        print("👤 Nom: ${googleAccount.displayName}");
        print("🆔 ID Firebase: $userId");
      } else {
        print("🔄 Utilisateur existant trouvé, mise à jour...");

        // 4. Utilisateur existant - récupérer l'ID et mettre à jour
        userId = querySnapshot.docs.first.id;

        await Users.doc(userId).update({
          "name": googleAccount.displayName,
          "photoUrl": googleAccount.photoUrl,
          "lastLogin": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          // "userI": userId, // Supprimé car pas nécessaire (userId est l'ID du document)
        });

        print("🔄 Utilisateur existant mis à jour");
        print("🆔 ID: $userId");
      }

      // 5. Stocker les informations localement
      // await storeUserInfoLocally(dataInfo: googleAccount, id: userId);
      await storeUserInfoocally(dataInfo: googleAccount,id:userId );

      // 6. Optionnel: Naviguer vers l'écran principal
      // Get.offAllNamed('/home');

    } catch (error) {
      errorMessage.value = 'Erreur lors de la connexion Google: $error';
      print('❌ Erreur signInWithGoogle: $error');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode utilitaire pour stocker l'ID localement
  Future<void> storeUserInfoocally({required GoogleSignInAccount dataInfo,required String id}) async {
    final prefs = await SharedPreferences.getInstance();


    final userData = {
      'displayName': dataInfo.displayName,
      'email': dataInfo.email,
      'id': dataInfo.id,
      'photoUrl': dataInfo.photoUrl,
      'serverAuthCode': dataInfo.serverAuthCode,
      'userI': id,

    };


    var data = jsonEncode(userData);
    await prefs.setString('userinfo', data);
    getUserInfoocally();
  }

  Future<void> showSimpleNotification({required Map<String, dynamic> message}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'simple_channel',
      'Notifications Simples',
      channelDescription: 'Canal pour les notifications simples',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      message["namesenderId"],
      message["content"],
      platformChannelSpecifics,
      payload: 'simple_notification',
    );

    // _showSuccessSnackBar('Notification simple envoyée');
  }



  Future<void> setupMessagesListener() async {

    print("🔍 Vérification des messages non lus arriere...");
    notif
    // .where("senderId", whereIn: [AppUser.info!.googleId, widget.receiverId])
        .where("receiveId", isEqualTo: AppUser.info!.googleId)
        .orderBy("timestamp", descending: false)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      notification.value = snapshot.docs.length;
      // Cette fonction s'exécute à CHAQUE changement

      // 1. Afficher les changements dans les documents
      for (var change in snapshot.docChanges) {
        switch (change.type) {
          case DocumentChangeType.added:
            var data = change.doc.data() as Map<String, dynamic>;
            String content = data['content'] ?? '';
            print("✏️ Message modifié: ${content}");
            // showSimpleNotification(message: data);


            // showSimpleNotification(message: '')
            // _onMessageAdded(change.doc);
            break;
          case DocumentChangeType.modified:
            var data = change.doc.data() as Map<String, dynamic>;
            String content = data['content'] ?? '';
            print("✏️ Message modifié: ${content}");
            // _onMessageModified(change.doc);
            // showSimpleNotification(message: data);
            break;
          case DocumentChangeType.removed:
            print("❌ Message supprimé: ${change.doc.data()}");
            // _onMessageRemoved(change.doc);
            break;
        }
      }
    }
    );}

  Future<void> _savePlayerIdToFirestore(String playerId) async {
    try {
      // Si l'utilisateur est connecté
      if (AppUser.info != null && AppUser.info!.googleId != null) {
        await Users.doc(AppUser.info!.userI).update({
          'onesignalId': playerId,
          'onesignalIdUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Player ID sauvegardé dans Firestore pour ${AppUser.info!.displayName}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde Firestore: $e');
    }
  }


  Future<void> getOneSignalPlayerId() async {
    try {
      // Récupérer l'ID OneSignal
      String? onesignalId = await OneSignal.User.getOnesignalId();

      if (onesignalId != null) {
        currentPlayerId = onesignalId;
        print('🆔 OneSignal Player ID récupéré: $onesignalId');
        Users.doc(AppUser.info?.userI).update({"isOnline":false});
        AppUser.info?.isonline =false;

        // Option 1: Sauvegarder dans SharedPreferences
        // await _savePlayerIdToPrefs(onesignalId);
        //
        // // Option 2: Sauvegarder dans Firestore si utilisateur connecté
        await _savePlayerIdToFirestore(onesignalId);


        // Option 3: Mettre à jour dans votre contrôleur
        if (AppUser.info != null) {
          AppUser.info!.onesignalId = onesignalId;
        }
      } else {
        print('⏳ Player ID pas encore disponible, nouvelle tentative...');
        // Réessayer après 2 secondes
        // Future.delayed(Duration(seconds: 2), () {
        //   getOneSignalPlayerId();
        // });
      }
    } catch (e) {
      print('❌ Erreur récupération Player ID: $e');
    }
  }

  Future<void> getUserInfoocally() async {
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString('userinfo');
    if (jsonString == null || jsonString.isEmpty) {
      print('ℹ️ Aucune donnée utilisateur trouvée localement');

      return  Get.offAll(()=>OnbodingScreen());

    }
    final userMap = jsonDecode(jsonString);
    AppUser.info =  AppUser.fromGoogleSignIn(userMap);
    print("userMap.id");
    print(AppUser.info!.email);
    print(AppUser.info!.photoUrl);
    print(AppUser.info!.userI);
    print("userMap.id");
    // setupMessagesListener();
    getOneSignalPlayerId();
    Get.offAll(()=>EntryPoint());
   //Get.offAll(()=>CloudinaryExample());
  }
  Future<void> getdelete() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("userinfo");
    await _googleSignIn.signOut();
    Users.doc(AppUser.info?.userI).update({"isOnline":false});
    AppUser.info?.isonline =false;
    Get.offAll(()=>OnbodingScreen());
  }

  Future<void> sendVerificationSms(String phoneNumber) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      codeSent.value = false;

      // Format international (+33 pour la France, etc.)
      String formattedPhone = _formatPhoneNumber(phoneNumber);

      // Envoyer le SMS avec Firebase
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Connexion automatique si l'OTP est détecté automatiquement
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          errorMessage.value = _getErrorMessage(e.code);
          isLoading.value = false;
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId.value = verificationId;
          codeSent.value = true;
          isLoading.value = false;

          // Démarrer le timer pour renvoyer
          _startResendTimer();

          Get.snackbar(
            'SMS envoyé',
            'Un code a été envoyé au $formattedPhone',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout - l'utilisateur doit entrer le code manuellement
          this.verificationId.value = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      errorMessage.value = 'Erreur: $e';
      isLoading.value = false;
    }
  }

  // --- VÉRIFIER LE CODE SMS ---
  Future<void> verifySmsCode(String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Créer le credential avec le code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: code,
      );

      // Se connecter
      await _signInWithPhoneCredential(credential);
    } catch (e) {
      errorMessage.value = 'Code invalide: $e';
      isLoading.value = false;
    }
  }

  // --- CONNEXION AVEC CREDENTIAL ---
  Future<void> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      await _auth.signInWithCredential(
        credential,
      );

      // Succès
      Get.snackbar(
        'Connexion réussie',
        'Bienvenue !',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Redirection
      Get.offAllNamed('/home');
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
      isLoading.value = false;
    }
  }

  // --- RENVOYER LE SMS ---
  Future<void> resendSms(String phoneNumber) async {
    if (!canResend.value) return;

    // Réinitialiser le timer
    _resendTimer?.cancel();
    canResend.value = false;
    resendTimer.value = 60;

    // Renvoyer le SMS
    await sendVerificationSms(phoneNumber);
  }

  // --- DÉMARRER LE TIMER POUR RENVOYER ---
  void _startResendTimer() {
    canResend.value = false;
    resendTimer.value = 60;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        timer.cancel();
        canResend.value = true;
      }
    });
  }

  // --- FORMATER LE NUMÉRO DE TÉLÉPHONE ---
  String _formatPhoneNumber(String phone) {
    // Supprimer les espaces et caractères spéciaux
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Ajouter l'indicatif si absent
    if (!cleaned.startsWith('+')) {
      // France par défaut, adaptez selon votre pays
      cleaned = '+237${cleaned.substring(1)}';
    }

    return cleaned;
  }

  // --- GESTION DES ERREURS ---
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'quota-exceeded':
        return 'Quota SMS dépassé';
      case 'session-expired':
        return 'Session expirée. Renvoyez le SMS';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'missing-verification-code':
        return 'Code manquant';
      case 'credential-already-in-use':
        return 'Ce numéro est déjà associé à un compte';
      default:
        return 'Erreur: $code';
    }
  }

  // Méthode d'inscription
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      Get.offAllNamed('/onboarding');
    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getErrorMessage(e.code);
    } catch (e) {
      errorMessage.value = 'Une erreur est survenue';
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode de déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }

  // Gestion des messages d'erreur
  String _getErrorMessages(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'invalid-email':
        return 'Email invalide';
      case 'weak-password':
        return 'Mot de passe trop faible';
      default:
        return 'Erreur d\'authentification';
    }
  }
}
