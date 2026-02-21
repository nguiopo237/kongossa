// service/config_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';


class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  final CollectionReference _config = FirebaseFirestore.instance.collection('config');

  static String? oneSignalAppId;
  static String? onesignalkey;







  // Récupérer l'App ID OneSignal depuis Firestore
  Future<String?> getOneSignalAppId() async {
    // Si déjà en cache, retourner la valeur
    if (oneSignalAppId != null) {
      return oneSignalAppId;
    }

    try {
      // Récupérer depuis Firestore
      final doc = await _config.doc('keys').get();

      if (doc.exists) {
        oneSignalAppId = doc.get('onesignal_app_id') as String?;
        onesignalkey = doc.get('apikey') as String?;
        print('✅ OneSignal App ID récupéré depuis Firestore');
        return oneSignalAppId;
      } else {
        print('⚠️ Document de configuration non trouvé');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la config: $e');
      return null;
    }
  }

  // Version avec cache et fallback (pour le développement)
  Future<String> getOneSignalAppIdWithFallback() async {
    // Essayer de récupérer depuis Firestore
    final remoteId = await getOneSignalAppId();

    if (remoteId != null && remoteId.isNotEmpty) {
      return remoteId;
    }

    // Fallback pour le développement (À RETIRER en production !)
    print('⚠️ UTILISATION DU FALLBACK - À RETIRER EN PRODUCTION');
    return "votre-app-id-de-secours"; // Mettez votre vrai ID ici temporairement
  }
}
