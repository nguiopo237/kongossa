import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WidgetComponent {
 static getmodal({Widget? sectionview, states}) {

   WidgetsBinding.instance.addPostFrameCallback((_) {
     Get.bottomSheet(
         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
         isScrollControlled: true,
         Material(
           shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.only(
                   topLeft: Radius.circular(20), topRight: Radius.circular(20))),
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
             child: StatefulBuilder(
               builder: (context, states) {
                 return Container(
                   decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(10)),
                   child: SingleChildScrollView(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         sectionview!,
                       ],
                     ),
                   ),
                 );
               },
             ),
           ),
         ));
   });


  }

 static getdialog({Widget? sectionview, states, barrierDismissible}) {
   return Get.dialog(
       barrierDismissible:
       barrierDismissible == null ? false : barrierDismissible,
       Dialog(
         child: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               sectionview!,
             ],
           ),
         ),
       ));
 }
}