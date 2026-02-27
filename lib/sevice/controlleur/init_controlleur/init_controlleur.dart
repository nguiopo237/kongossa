


import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../connection/connectionchecker.dart';
import '../../member_service/member_service.dart';
import '../authentification/auth_controlleur.dart';
import '../chat_controlleur/chat_controlleur.dart';
import '../publish_element/PublishControlleur.dart';
import '../sms_controller/sms_controlleur.dart';
import '../splashcontrolleur/splashscreen_controlleur.dart';
import '../video_service.dart';

class AppControllers {

  static initialize() async {

     //Get.put(() => AuthController(), permanent: true);

     Get.lazyPut(() => AuthController(), fenix: true);
     Get.lazyPut(() => SplashController(), fenix: true);
     Get.lazyPut(() => SmsController(), fenix: true);
     // Get.lazyPut(() => ChatController(receiverId: '989', receiverName: ''), fenix: true);
     Get.lazyPut(() => MemberService(), fenix: true);
     Get.lazyPut(() => CreatePostPremiumController (), fenix: true);
     // Get.lazyPut(()=>VideoEditorController());


  }
}
