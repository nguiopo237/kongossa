import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:path/path.dart' as path;

import '../../../model/datamodel/story_model.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../screens/mymember/chatpage.dart';
import '../../../sevice/connection/connectionchecker.dart';
import '../../../sevice/upload/compress_video.dart';
import '../../../sevice/upload/select_image.dart';
import '../../../sevice/upload/upload_cloud.dart';
import '../../../../main.dart';
import '../video_size.dart';
CreatePostPremiumController c = Get.find();
class CreatePostPremiumController extends GetxController
    with StateMixin<dynamic> {
  // Contrôleurs et Focus
  final TextEditingController postController = TextEditingController();
  final FocusNode postFocusNode = FocusNode();

  // États observables
  final RxBool hasContent = false.obs;
  final RxBool load = false.obs;
  final RxBool isPublic = true.obs;
  final RxString selectedAudience = 'Public'.obs;
  final RxList<String> attachedImages = <String>[].obs;
  final RxList<String> attachedVideos = <String>[].obs;
  final RxList<String> sender = <String>[].obs;
  final RxBool hasLocation = false.obs;
  final RxString locationName = 'Paris, France'.obs;
  final RxBool tagPeople = false.obs;
  final RxList<String> taggedPeople = <String>['Marie Dupont', 'Jean Martin'].obs;
  final RxBool isFeeling = false.obs;
  final RxString selectedFeeling = ''.obs;
  final RxBool isPoll = false.obs;
  final RxInt charCount = 0.obs;
  final RxInt maxChars = 280.obs;

  // Données utilisateur
  final Rx<DocumentSnapshot?> userData = Rx<DocumentSnapshot?>(null);
  final RxBool isLoadingUser = true.obs;

  // Options de sentiment
  final List<Map<String, dynamic>> feelingOptions = [
    {'icon': '😊', 'label': 'Heureux', 'color': Colors.amber},
    {'icon': '😢', 'label': 'Triste', 'color': Colors.blue},
    {'icon': '😎', 'label': 'Cool', 'color': Colors.green},
    {'icon': '❤️', 'label': 'Amoureux', 'color': Colors.red},
    {'icon': '🤔', 'label': 'Pensif', 'color': Colors.purple},
  ];

  // Services
  // final NativeVideoCompressService compress = NativeVideoCompressService();
  final UniversalCloudinaryUploader uploader = UniversalCloudinaryUploader();

  // Timers
  Timer? _textFieldTimer;
  StreamSubscription<QuerySnapshot>? _userStreamSubscription;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    setupPostListener();
  }

  @override
  void onClose() {
    _textFieldTimer?.cancel();
    _userStreamSubscription?.cancel();
    postController.dispose();
    postFocusNode.dispose();
    super.onClose();
  }

  void setupPostListener() {
    postController.addListener(() {
      _textFieldTimer?.cancel();
      _textFieldTimer = Timer(const Duration(milliseconds: 100), () {
        updateContent();
      });
    });
  }

  void updateContent() {
    final hasContentNow = postController.text.isNotEmpty ||
        attachedImages.isNotEmpty ||
        attachedVideos.isNotEmpty;

    if (hasContent.value != hasContentNow) {
      hasContent.value = hasContentNow;
      charCount.value = postController.text.length;
    } else {
      if (charCount.value != postController.text.length) {
        charCount.value = postController.text.length;
      }
    }
  }

  void loadUserData() {
    Users.where('googleId', isEqualTo: AppUser.info?.googleId)
        .snapshots()
        .listen((querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        userData.value = querySnapshot.docs.first;
        isLoadingUser.value = false;
        change(null, status: RxStatus.success());
      }
    }, onError: (error) {
      isLoadingUser.value = false;
      change(null, status: RxStatus.error('Erreur de chargement: $error'));
    });
  }

  void toggleAudience() {
    isPublic.toggle();
    selectedAudience.value = isPublic.value ? 'Public' : 'Amis uniquement';
  }

  Future<void> addImage() async {
    attachedVideos.clear();
    final pickedFile = await SelectImage.uploadMultipleImages();
    if (pickedFile?.isNotEmpty == true) {
      for (var element in pickedFile!) {
        attachedImages.add(element.path);
      }
    }
  }

  Future<List<String>> uploadFilesstory() async {
    List<String> uploadedUrlstory = [];
    if (attachedVideos.isNotEmpty) {
      for (var element in attachedVideos) {
        try {
          String originalName = path.basename(element);
          final url = await uploader.uploadAnyFile(
            filePath: element,
            folder: 'kogossa_app/story',
            fileName: originalName,
          );
          if (url != null) uploadedUrlstory.add(url);
        } catch (e) {
          print('❌ Erreur upload vidéo $element: $e');
        }
      }
    }

    if (attachedImages.isNotEmpty) {
      for (var element in attachedImages) {
        try {
          String originalName = path.basename(element);
          final url = await uploader.uploadAnyFile(
            filePath: element,
            folder: 'kogossa_app/story',
            fileName: originalName,
          );
          if (url != null) uploadedUrlstory.add(url);
        } catch (e) {
          print('❌ Erreur upload image $element: $e');
        }
      }
    }

    sender.value = uploadedUrlstory;
    return uploadedUrlstory;
  }






  Future<void> addImagestory() async {
    attachedImages.clear();
    attachedVideos.clear();

    final pickedFile = await SelectImage.uploadMultipleImages();

    if (pickedFile?.isNotEmpty == true) {
      Get.back();
      attachedImages.add(pickedFile!.first.path);
      List<String> uploadedUrls = await uploadFilesstory();

      // 🕐 Dates en UTC + format Timestamp Firestore
      final now = Timestamp.now(); // Équivalent à DateTime.now().toUtc() en Timestamp
      final expires = Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(hours: 24))
      );

      final datastory = SocialStatus(
        id: AppUser.info!.googleId,
        userId: AppUser.info!.userI,
        content: '',
        mediaUrls: uploadedUrls,
        createdAt: now,        // ✅ Timestamp
        updatedAt: DateTime.now(),        // ✅ Timestamp
        expiresAt: expires,    // ✅ Timestamp
      );

      await Story.add(datastory.toJson());
    }
  }
  Future<void> addVideotory() async {
    attachedImages.clear();
    attachedVideos.clear();

    final pickedFile = await SelectImage.uploadMultipleVideo();

    if (pickedFile?.isNotEmpty == true) {
      Get.back();
      attachedVideos.add(pickedFile!.first.path);
      List<String> uploadedUrls = await uploadFilesstory();

      // 🕐 Dates en UTC + format Timestamp Firestore
      final now = Timestamp.now(); // Équivalent à DateTime.now().toUtc() en Timestamp
      final expires = Timestamp.fromDate(
          DateTime.now().toUtc().add(const Duration(hours: 24))
      );

      final datastory = SocialStatus(
        id: AppUser.info!.googleId,
        userId: AppUser.info!.userI,
        content: '',
        mediaUrls: uploadedUrls,
        createdAt: now,        // ✅ Timestamp
        updatedAt: DateTime.now(),        // ✅ Timestamp
        expiresAt: expires,    // ✅ Timestamp
      );

      await Story.add(datastory.toJson());
    }
  }

  Future<void> addVideo(BuildContext context) async {
    attachedImages.clear();
    attachedVideos.clear();
    final pickedFile = await SelectImage.uploadMultipleVideo();
    if (pickedFile?.isNotEmpty == true) {

      WidgetComponent.getmodal(sectionview: Container(height: Get.height,child: VideoEditor(file: File(pickedFile!.first.path),),));
      // Note: Le VideoEditor doit être géré dans la vue
      // for (var element in pickedFile!) {
      //   attachedVideos.add(element.path);
      // }
    }
  }

  void toggleLocation() {
    hasLocation.toggle();
  }

  void toggleFeeling() {
    isFeeling.toggle();
    if (!isFeeling.value) {
      selectedFeeling.value = '';
    }
  }

  void togglePoll() {
    isPoll.toggle();
  }

  void selectFeeling(Map<String, dynamic> feeling) {
    selectedFeeling.value = feeling['label'];
  }

  Future<void> publishPost(BuildContext context) async {
    final isConnected = await Connexioncheck.checkconnection();
    if (!isConnected) {
      Get.snackbar(
        'Erreur',
        'noconnect'.tr,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP
      );
      return;
    }

    if (!hasContent.value) {
      showNotification('Ajoutez du contenu avant de publier', Colors.orange);
      return;
    }

    if (postController.text.trim().isEmpty) {
      showNotification('Le titre du post est requis', Colors.orange);
      return;
    }

    try {
      String postTitle = postController.text.trim();
      hasContent.value = false;
      load.value = true;


      // Vérification du titre existant
      QuerySnapshot existingPosts = await Posts
          .where('postData.posttitle', isEqualTo: postTitle)
          .where('userData.googleId', isEqualTo: AppUser.info!.googleId)
          .get();

      if (existingPosts.docs.isNotEmpty) {
        showNotification(
          'Ce titre de post existe déjà. Veuillez en choisir un autre.',
          Colors.orange,
        );
        return;
      }

      // Upload des fichiers
      List<String> uploadedUrls = await uploadFiles();

      // Création du post
      load.value = false;
      await createPostDocument(postTitle, uploadedUrls);

      showNotification('🎉 Post publié avec succès!', Colors.green);
      resetForm();
    } catch (e) {
      print('❌ Erreur publication: $e');
      showNotification('Erreur lors de la publication', Colors.red);
    }
  }

  Future<List<String>> uploadFiles() async {
    List<String> uploadedUrls = [];

    if (attachedVideos.isNotEmpty) {
      for (var element in attachedVideos) {
        try {
          String originalName = path.basename(element);
          final url = await uploader.uploadAnyFile(
            filePath: element,
            folder: 'kogossa_app/secure',
            fileName: originalName,
          );
          if (url != null) uploadedUrls.add(url);
        } catch (e) {
          print('❌ Erreur upload vidéo $element: $e');
        }
      }
    }

    if (attachedImages.isNotEmpty) {
      for (var element in attachedImages) {
        try {
          String originalName = path.basename(element);
          final url = await uploader.uploadAnyFile(
            filePath: element,
            folder: 'kogossa_app/secure',
            fileName: originalName,
          );
          if (url != null) uploadedUrls.add(url);
        } catch (e) {
          print('❌ Erreur upload image $element: $e');
        }
      }
    }

    sender.value = uploadedUrls;
    return uploadedUrls;
  }

  Future<void> createPostDocument(String postTitle, List<String> uploadedUrls) async {
    final userDataMap = {
      'email': AppUser.info!.email,
      'googleId': AppUser.info!.googleId,
      'name': AppUser.info!.displayName,
      'photoUrl': AppUser.info!.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };

    final postData = {
      'posttitle': postTitle,
      'imagepost': attachedImages.isEmpty && attachedVideos.isEmpty
          ? []
          : attachedImages.isNotEmpty
          ? uploadedUrls
          : [],
      'videopost': attachedVideos.isEmpty && sender.isEmpty
          ? []
          : attachedVideos.isNotEmpty
          ? uploadedUrls
          : [],
      'likes': 0,
      'islike': false,
      'status': 'published',
      'commentaire': [],
      'personlike': [],
      'allike': [],
      'createdAt': FieldValue.serverTimestamp(),
      'userId': AppUser.info!.googleId,
    };

    final postDocument = {
      'userData': userDataMap,
      'postData': postData,
      'timestamp': FieldValue.serverTimestamp(),
    };

    DocumentReference docRef = await Posts.add(postDocument);
    print('✅ Post créé avec ID: ${docRef.id}');
  }

  void resetForm() {
    postController.clear();
    attachedImages.clear();
    attachedVideos.clear();
    sender.clear();
    hasLocation.value = false;
    tagPeople.value = false;
    isFeeling.value = false;
    selectedFeeling.value = '';
    isPoll.value = false;
    charCount.value = 0;
    hasContent.value = false;
  }

  void showNotification(String message, Color color) {
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.grey[900],
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 15,
      margin: const EdgeInsets.all(10),
    );
  }

  Color getCharacterCounterColor() {
    final percentage = charCount.value / maxChars.value;
    if (percentage < 0.7) return Colors.green;
    if (percentage < 0.9) return Colors.orange;
    return Colors.red;
  }

  int getRemainingChars() {
    return maxChars.value - charCount.value;
  }
}