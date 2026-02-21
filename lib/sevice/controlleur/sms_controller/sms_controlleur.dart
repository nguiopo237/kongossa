import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SmsController extends GetxController {
  static SmsController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // États réactifs
  final RxString verificationId = ''.obs;
  final RxString smsCode = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool codeSent = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt resendTimer = 0.obs;
  final RxBool canResend = true.obs;

  // Timer pour renvoyer le SMS
  Timer? _resendTimer;

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

  // --- ENVOYER UN SMS DE VÉRIFICATION ---
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
  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.signInWithCredential(credential);

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
      cleaned = '+33${cleaned.substring(1)}';
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
}