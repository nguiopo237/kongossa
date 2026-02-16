


import 'package:get/get.dart';

import '../../member_service/member_service.dart';
import '../authentification/auth_controlleur.dart';
import '../sms_controller/sms_controlleur.dart';
import '../splashcontrolleur/splashscreen_controlleur.dart';

class AppControllers {

  static initialize() async {

     //Get.put(() => AuthController(), permanent: true);
     Get.lazyPut(() => AuthController(), fenix: true);
     Get.lazyPut(() => SplashController(), fenix: true);
     Get.lazyPut(() => SmsController(), fenix: true);
     Get.lazyPut(() => MemberService(), fenix: true);

  }
}
