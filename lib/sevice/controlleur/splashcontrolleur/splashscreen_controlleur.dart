import 'package:get/get.dart';

class SplashController extends GetxController {
  static SplashController get to => Get.find();

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      // Ici vous pouvez ajouter d'autres initialisations
      // Par exemple : vérifier l'authentification, charger des données, etc.

      await Future.delayed(const Duration(seconds: 2)); // Simulation de chargement

      // Navigation vers l'écran principal
      Get.offAllNamed('/onboarding');

    } catch (e) {
      errorMessage.value = 'Erreur d\'initialisation: $e';
      isLoading.value = false;
    }
  }
}