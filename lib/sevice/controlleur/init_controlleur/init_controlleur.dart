import 'package:get/get.dart';

import '../../member_service/member_service.dart';
import '../authentification/auth_controlleur.dart';
import '../firestore_collections_service.dart';
import '../sms_controller/sms_controlleur.dart';
import '../live_controller.dart';
import '../splashcontrolleur/splashscreen_controlleur.dart';
import '../theme_controller/theme_controlleur.dart';

class AppControllers {
  static Future<void> initialize() async {
    // Get.put(() => AuthController(), permanent: true);

    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => SplashController(), fenix: true);
    Get.lazyPut(() => SmsController(), fenix: true);
    Get.lazyPut(() => MemberService(), fenix: true);
    Get.put(FirestoreCollectionsService(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.lazyPut(() => LiveController(), fenix: true);
  }
}
