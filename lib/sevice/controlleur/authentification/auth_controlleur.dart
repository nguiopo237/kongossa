import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firestore_collections_service.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../screens/entryPoint/entry_point.dart';
import '../../../screens/onboding/onboding_screen.dart';
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
  // FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  // FlutterLocalNotificationsPlugin();


  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    debugPrint("user");

    debugPrint("user");
  }

  @override
  void onReady() {

    // Écouter les changements d'état d'authentification
    _auth.authStateChanges().listen((User? user) {
      this.user.value = user;

    });
    super.onReady();
  }

  Future<String?> getCurrentToken() async {
    debugPrint("start");
    User? user = _auth.currentUser;
    if (user != null) {
      _currentToken = await user.getIdToken();
      debugPrint(_currentToken);
      debugPrint(user.uid);
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
      debugPrint('Permission denied');
    }

    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('New FCM token: $newToken');
      try {
        final userId = await _getCurrentFirestoreUserId();
        if (userId != null) {
          await FirestoreCollectionsService.users.doc(userId).update({
            'fcmToken': newToken,
          });
        }
      } catch (e) {
        debugPrint('⚠️ FCM token update error: $e');
      }
    });
    return token;
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
      errorMessage.value = 'auth.error_occurred'.tr;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      debugPrint("Verifying...");
      // 1. Authentification avec Google
      final googleAccounts = await _googleSignIn.signIn();
      print(googleAccounts?.email);
      debugPrint("Verification step 1");

      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();
      debugPrint("Verification complete");
      print(googleAccount?.email);
      debugPrint("Verification complete");
      if (googleAccount == null) {
        // L'utilisateur a annulé
        debugPrint("No Google account selected");
        isLoading.value = false;
        return;
      }
      debugPrint("Google account selected");
      // 2. Vérifier si l'utilisateur existe déjà dans la base de données
      QuerySnapshot querySnapshot =
          await FirestoreCollectionsService.users.where('googleId', isEqualTo: googleAccount.id.trim())
              .limit(1)
              .get(
                // GetOptions(source: Source.serverAndCache),
              ); // Utiliser cache et serveur

      String userId;

      if (querySnapshot.docs.isEmpty) {
        // 3. Créer un nouvel utilisateur
        final userData = {
          "email": googleAccount.email,
          "googleId": googleAccount.id,
          "name": googleAccount.displayName,
          "photoUrl": googleAccount.photoUrl,
          "createdAt": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
          "lastLogin": FieldValue.serverTimestamp(),
        };

        // Ajouter le document et récupérer l'ID
        DocumentReference docRef = await FirestoreCollectionsService.users.add(userData);
        userId = docRef.id;

        debugPrint("✅ New user created");
        debugPrint("📧 Email: ${googleAccount.email}");
        debugPrint("👤 Name: ${googleAccount.displayName}");
        debugPrint("🆔 Firebase ID: $userId");
      } else {
        // 4. Utilisateur existant - mettre à jour les infos
        userId = querySnapshot.docs.first.id;

        await FirestoreCollectionsService.users.doc(userId).update({
          "name": googleAccount.displayName,
          "photoUrl": googleAccount.photoUrl,
          "lastLogin": FieldValue.serverTimestamp(),
          "updatedAt": FieldValue.serverTimestamp(),
        });

        debugPrint("🔄 Existing user updated");
        debugPrint("🆔 ID: $userId");
      }

      // 5. Stocker l'ID utilisateur localement
      await storeUserInfoLocally(googleAccount);

      // 6. Sauvegarder le token FCM sur Firestore
      try {
        final fcmToken = await _fcm.getToken();
        if (fcmToken != null && userId.isNotEmpty) {
          await FirestoreCollectionsService.users.doc(userId).update({
            'fcmToken': fcmToken,
          });
          debugPrint('✅ FCM token saved to Firestore');
        }
      } catch (e) {
        debugPrint('⚠️ Unable to save FCM token: $e');
      }

      // 7. Naviguer vers l'écran principal
    } catch (error) {
      errorMessage.value = '${'auth.google_error'.tr}: $error';
      debugPrint('❌ signInWithGoogle error: $error');
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode utilitaire pour stocker l'ID localement
  Future<void> storeUserInfoLocally(GoogleSignInAccount dataInfo) async {
    final prefs = await SharedPreferences.getInstance();

    final userData = {
      'displayName': dataInfo.displayName,
      'email': dataInfo.email,
      'id': dataInfo.id,
      'photoUrl': dataInfo.photoUrl,
      'serverAuthCode': dataInfo.serverAuthCode,
    };

    var data = jsonEncode(userData);
    await prefs.setString('userinfo', data);
    getUserInfoLocally();
  }

  // Future<void> showSimpleNotification({required Map<String, dynamic> message}) async
  // {
  //   const AndroidNotificationDetails androidPlatformChannelSpecifics =
  //   AndroidNotificationDetails(
  //     'simple_channel',
  //     'Notifications Simples',
  //     channelDescription: 'Canal pour les notifications simples',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //     ticker: 'ticker',
  //   );
  //
  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: androidPlatformChannelSpecifics,
  //     iOS: DarwinNotificationDetails(),
  //   );
  //
  //   await flutterLocalNotificationsPlugin.show(
  //     0,
  //     message["namesenderId"],
  //     message["content"],
  //     platformChannelSpecifics,
  //     payload: 'simple_notification',
  //   );
  //
  //   // _showSuccessSnackBar('Notification simple envoyée');
  // }



  Future<void> setupMessagesListener() async {

    debugPrint("🔍 Checking unread messages background...");
    FirestoreCollectionsService.notif
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
            debugPrint("✏️ Message modified: ${content}");
            // showSimpleNotification(message: data);


            // showSimpleNotification(message: '')
            // _onMessageAdded(change.doc);
            break;
          case DocumentChangeType.modified:
            var data = change.doc.data() as Map<String, dynamic>;
            String content = data['content'] ?? '';
            debugPrint("✏️ Message modified: ${content}");
            // _onMessageModified(change.doc);
            // showSimpleNotification(message: data);
            break;
          case DocumentChangeType.removed:
            debugPrint("❌ Message deleted: ${change.doc.data()}");
            // _onMessageRemoved(change.doc);
            break;
        }
      }
    }
    );}

  Future<void> getUserInfoLocally() async {
    final prefs = await SharedPreferences.getInstance();
    var jsonString = prefs.getString('userinfo');
    if (jsonString == null || jsonString.isEmpty) {
      debugPrint('ℹ️ No user data found locally');
      return Get.offAll(() => OnbodingScreen());
    }
    final userMap = jsonDecode(jsonString);
    AppUser.info = AppUser.fromGoogleSignIn(userMap);
    debugPrint("👤 User connected: ${AppUser.info!.email}");
    setupMessagesListener();
    Get.offAll(() => EntryPoint());
  }
  Future<void> getdelete() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("userinfo");
    await _googleSignIn.signOut();
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
            'sms.title_sent'.tr,
            '${'sms.code_sent'.tr}$formattedPhone',
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
      errorMessage.value = '${'sms.error'.tr}: $e';
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
      errorMessage.value = '${'sms.invalid_code_error'.tr}: $e';
      isLoading.value = false;
    }
  }

  // --- CONNEXION AVEC CREDENTIAL ---
  Future<void> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Succès
      Get.snackbar(
        'auth.login_success'.tr,
        'auth.welcome'.tr,
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
      // Cameroun par défaut (237), adaptez selon votre pays
      final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
      cleaned = '+237$digitsOnly';
    }

    return cleaned;
  }

  /// Récupère l'ID Firestore du document utilisateur à partir du googleId.
  Future<String?> _getCurrentFirestoreUserId() async {
    if (AppUser.info?.googleId == null) return null;
    try {
      final snap = await FirestoreCollectionsService.users
          .where('googleId', isEqualTo: AppUser.info!.googleId)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.id;
    } catch (e) {
      debugPrint('⚠️ _getCurrentFirestoreUserId error: $e');
      return null;
    }
  }

  // --- GESTION DES ERREURS ---
  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'sms.invalid_phone'.tr;
      case 'too-many-requests':
        return 'sms.too_many_attempts'.tr;
      case 'quota-exceeded':
        return 'sms.quota_exceeded'.tr;
      case 'session-expired':
        return 'sms.session_expired'.tr;
      case 'invalid-verification-code':
        return 'sms.invalid_code'.tr;
      case 'missing-verification-code':
        return 'sms.code_missing'.tr;
      case 'credential-already-in-use':
        return 'sms.number_exists'.tr;
      default:
        return '${'sms.error'.tr}: $code';
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
      errorMessage.value = 'auth.error_occurred'.tr;
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
        return 'auth.user_not_found'.tr;
      case 'wrong-password':
        return 'auth.wrong_password'.tr;
      case 'email-already-in-use':
        return 'auth.email_in_use'.tr;
      case 'invalid-email':
        return 'auth.invalid_email'.tr;
      case 'weak-password':
        return 'auth.weak_password'.tr;
      default:
        return 'auth.auth_error'.tr;
    }
  }
}
