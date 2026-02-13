import 'package:firebase_auth/firebase_auth.dart';

class AuthCallGoogle {


  static Future<void> checkAuthState() async {
    // Écoute l'état d'authentification
    print("start");
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('Utilisateur connecté depuis le cache : ${user.email}');

        // Récupérer les données du cache
        String? cachedToken = user.getIdToken().toString();
        bool isEmailVerified = user.emailVerified;
        DateTime? lastSignIn = user.metadata.lastSignInTime;

        // Les données sont disponibles même offline
        print('Dernière connexion : $lastSignIn');
        print('Email vérifié : $isEmailVerified');
      }else{
        print("rien sauvegarder");
      }
    });
  }
}