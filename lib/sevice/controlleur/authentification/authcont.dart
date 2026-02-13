import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // États réactifs
  final user = Rxn<User>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isGoogleSignInAvailable = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkGoogleSignInAvailability();
    _setupAuthListener();
  }

  // Vérifier si Google Sign-In est disponible
  Future<void> _checkGoogleSignInAvailability() async {
    try {
      await _googleSignIn.signInSilently();
      isGoogleSignInAvailable.value = true;
    } catch (e) {
      isGoogleSignInAvailable.value = false;
      print('Google Sign-In non disponible: $e');
    }
  }

  // Écouter les changements d'authentification
  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      user.value = firebaseUser;

      // Si l'utilisateur est connecté, naviguer vers l'écran principal
      if (firebaseUser != null) {
        Get.offAllNamed('/home');
      }
    });
  }

  // --- CONNEXION GOOGLE ---
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // 1. Déclencher l'authentification Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        isLoading.value = false;
        return;
      }

      // 2. Obtenir les informations d'authentification
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // 3. Créer un credential Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Se connecter à Firebase avec le credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // 5. Stocker des informations supplémentaires si nécessaire
      await _saveUserData(userCredential.user!);

      // 6. Succès - la navigation est gérée par le listener
      Get.snackbar(
        'Connexion réussie',
        'Bienvenue ${userCredential.user!.displayName}',
        snackPosition: SnackPosition.BOTTOM,
      );

    } on FirebaseAuthException catch (e) {
      errorMessage.value = _getFirebaseErrorMessage(e.code);
      Get.snackbar(
        'Erreur',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      errorMessage.value = 'Erreur lors de la connexion Google: $e';
      Get.snackbar(
        'Erreur',
        'Impossible de se connecter avec Google',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- CONNEXION SILENCIEUSE (au démarrage) ---
  Future<void> signInSilently() async {
    try {
      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signInSilently();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print('Connexion silencieuse échouée: $e');
    }
  }

  // --- DÉCONNEXION ---
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Déconnexion de Google
      await _googleSignIn.signOut();

      // Déconnexion de Firebase
      await _auth.signOut();

      // Navigation vers l'écran de connexion
      Get.offAllNamed('/login');

      Get.snackbar(
        'Déconnexion',
        'Vous êtes déconnecté',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      errorMessage.value = 'Erreur lors de la déconnexion: $e';
      Get.snackbar(
        'Erreur',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // --- SAUVEGARDE DES DONNÉES UTILISATEUR ---
  Future<void> _saveUserData(User user) async {
    // Ici vous pouvez sauvegarder les infos utilisateur dans Firestore
    final userData = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'provider': 'google',
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    // Exemple avec Firestore (si vous l'utilisez)
    // await FirebaseFirestore.instance
    //   .collection('users')
    //   .doc(user.uid)
    //   .set(userData, SetOptions(merge: true));
  }

  // --- MESSAGES D'ERREUR ---
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cette adresse email';
      case 'invalid-credential':
        return 'Les informations d\'identification sont invalides';
      case 'operation-not-allowed':
        return 'La connexion Google n\'est pas activée';
      case 'user-disabled':
        return 'Ce compte utilisateur a été désactivé';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-verification-code':
        return 'Code de vérification invalide';
      case 'invalid-verification-id':
        return 'ID de vérification invalide';
      default:
        return 'Erreur d\'authentification: $code';
    }
  }

  // --- GETTERS UTILES ---
  bool get isLoggedIn => user.value != null;
  String? get userEmail => user.value?.email;
  String? get userName => user.value?.displayName;
  String? get userPhoto => user.value?.photoURL;
}