import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../controlleur/splashcontrolleur/splashscreen_controlleur.dart';

class Connexioncheck{
  static checkconnection()async{
    bool result = false;
    result = await InternetConnectionChecker().hasConnection;
    if(result == true) {
      debugPrint('YAY! Free cute dog pics!');
      result = true;
      return result;
    } else {

      return result;
    }
  }

  static getConnectivity(context) {
    s.subscription = Connectivity().onConnectivityChanged.listen(
          (List<ConnectivityResult> results) async {
        // Prendre le premier résultat de la liste
        debugPrint("results.length");

        debugPrint("results.length");
        if (results.isNotEmpty) {
          // final result = results.first;
          s.isDeviceConnected.value = await InternetConnectionChecker().hasConnection;
          if (!s.isDeviceConnected.value && s.isAlertSet.value == false) {

            // c.snackbar(message: "noconnection".tr,type: SnackbarType.warning);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 60),
              content: Text('create_post.no_connection'.tr),
            ));
          } else {
            ScaffoldMessenger.of(context)
                .hideCurrentSnackBar(reason: SnackBarClosedReason.swipe);
            debugPrint("connection on");
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
              content: Text('connection.restored'.tr),
            ));

          }
        }
      },
    );
  }

}