// // lib/controllers/gallery_controller.dart
//
// import 'package:flutter/material.dart';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:image_picker/image_picker.dart';
// import '../../gallery_service/GalleryService.dart';
//
//
// class GalleryController extends ChangeNotifier {
//   final GalleryService _galleryService = GalleryService();
//   final ImagePicker _imagePicker = ImagePicker();
//
//   // États
//   bool _isLoading = false;
//   String? _lastSavedPath;
//   String? _errorMessage;
//
//   // Getters
//   bool get isLoading => _isLoading;
//   String? get lastSavedPath => _lastSavedPath;
//   String? get errorMessage => _errorMessage;
//
//   // Réinitialiser les messages
//   void clearMessages() {
//     _lastSavedPath = null;
//     _errorMessage = null;
//     notifyListeners();
//   }
//
//   /// Sélectionne et sauvegarde une image de la galerie
//   Future<bool> pickAndSaveImage() async {
//     _setLoading(true);
//     clearMessages();
//
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//
//       if (pickedFile == null) {
//         _setLoading(false);
//         return false;
//       }
//
//       final File imageFile = File(pickedFile.path);
//       final result = await _galleryService.saveImageFromFile(
//         imageFile,
//         fileName: 'saved_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
//       );
//
//       if (result.success) {
//         _lastSavedPath = result.filePath;
//         _setLoading(false);
//         return true;
//       } else {
//         _errorMessage = result.errorMessage;
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Error picking image: $e';
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   /// Prend une photo et la sauvegarde
//   Future<bool> takePhotoAndSave() async {
//     _setLoading(true);
//     clearMessages();
//
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//
//       if (pickedFile == null) {
//         _setLoading(false);
//         return false;
//       }
//
//       final File imageFile = File(pickedFile.path);
//       final result = await _galleryService.saveImageFromFile(
//         imageFile,
//         fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
//       );
//
//       if (result.success) {
//         _lastSavedPath = result.filePath;
//         _setLoading(false);
//         return true;
//       } else {
//         _errorMessage = result.errorMessage;
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Error taking photo: $e';
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   /// Sauvegarde une image à partir de bytes
//   Future<bool> saveImageFromBytes(Uint8List bytes, {String? fileName}) async {
//     _setLoading(true);
//     clearMessages();
//
//     try {
//       final result = await _galleryService.saveImageFromBytes(
//         bytes,
//         fileName: fileName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.png',
//       );
//
//       if (result.success) {
//         _lastSavedPath = result.filePath;
//         _setLoading(false);
//         return true;
//       } else {
//         _errorMessage = result.errorMessage;
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Error saving image: $e';
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   /// Sauvegarde une vidéo
//   Future<bool> pickAndSaveVideo() async {
//     _setLoading(true);
//     clearMessages();
//
//     try {
//       final XFile? pickedFile = await _imagePicker.pickVideo(
//         source: ImageSource.gallery,
//         maxDuration: const Duration(minutes: 5),
//       );
//
//       if (pickedFile == null) {
//         _setLoading(false);
//         return false;
//       }
//
//       final result = await _galleryService.saveVideo(
//         pickedFile.path,
//         fileName: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
//       );
//
//       if (result.success) {
//         _lastSavedPath = result.filePath;
//         _setLoading(false);
//         return true;
//       } else {
//         _errorMessage = result.errorMessage;
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Error saving video: $e';
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   /// Sauvegarde un widget en tant qu'image
//   Future<bool> saveWidgetAsImage({
//     required BuildContext context,
//     required GlobalKey repaintKey,
//     String? fileName,
//   }) async {
//     _setLoading(true);
//     clearMessages();
//
//     try {
//       final result = await _galleryService.saveImageFromWidget(
//         context: context,
//         repaintKey: repaintKey,
//         fileName: fileName ?? 'widget_${DateTime.now().millisecondsSinceEpoch}.png',
//       );
//
//       if (result.success) {
//         _lastSavedPath = result.filePath;
//         _setLoading(false);
//         return true;
//       } else {
//         _errorMessage = result.errorMessage;
//         _setLoading(false);
//         return false;
//       }
//     } catch (e) {
//       _errorMessage = 'Error saving widget: $e';
//       _setLoading(false);
//       return false;
//     }
//   }
//
//   void _setLoading(bool value) {
//     _isLoading = value;
//     notifyListeners();
//   }
// }