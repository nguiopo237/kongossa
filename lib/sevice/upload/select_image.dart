import 'dart:io';

import 'package:image_picker/image_picker.dart';

class SelectImage {


 static Future<File?> takeAndUploadPhoto({bool iscamera=true}) async {
    final pickedFile = await ImagePicker().pickImage(
      source: iscamera?ImageSource.camera:ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // await _uploadImage(File(pickedFile.path));
      return File(pickedFile.path);
    }
  }

 static Future<List<XFile>?>uploadMultipleImages() async {
   final pickedFiles = await ImagePicker().pickMultiImage(
     imageQuality: 85,
     maxWidth: 2000,
   );

   if (pickedFiles.isNotEmpty) {
     return pickedFiles;
   }
   return null;
 }
 static Future<List<XFile>?>uploadMultipleVideo() async {
   List<XFile>? item = [];
   final pickedFiles = await ImagePicker().pickVideo(
     // imageQuality: 85,
     // maxWidth: 2000,
     source: ImageSource.gallery,
   );

   if (pickedFiles!=null) {
     item.add(pickedFiles);
     return item;
   }
   return null;
 }


}