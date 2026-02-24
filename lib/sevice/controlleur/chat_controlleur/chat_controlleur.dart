import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as ThumbVideo;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:just_audio/just_audio.dart';

import '../../../main.dart';
import '../../../model/datamodel/message_model.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../presentation/component/video_component/tiktok_player_video.dart';
import '../../call_API/kongossa_ia/ia_service.dart';
import '../../upload/upload_cloud.dart';
import '../notification/chat_notificationservice/one_signalservice.dart';


class ChatController extends GetxController {
  // ============================================================================
  // DEPENDENCIES
  // ============================================================================
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final bool isOnline;
  final String? onesignalId;

  ChatController({
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    this.isOnline = true,
    this.onesignalId,
  });

  // ============================================================================
  // CONTROLLERS
  // ============================================================================
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();
  RxBool shouldAutoScroll = true.obs;

  // Cache pour les AudioPlayers
  final Map<String, AudioPlayer> _audioPlayers = {};
  final Set<String> _processingVideos = {};

  // ============================================================================
  // REACTIVE STATE
  // ============================================================================
  final _isSendingMedia = false.obs;
  final _showScrollButton = false.obs;
  final showScrollButtons = false.obs;
  final _showAudioRecord = false.obs;
  RxString answer = "".obs;
  RxString response = "".obs;

  final _showlast = false.obs;
  final reply = <Map<String, dynamic>>[].obs;
  final _currentlyPlayingAudio = RxString('');

  // Getters
  bool get isSendingMedia => _isSendingMedia.value;
  bool get showScrollButton => _showScrollButton.value;
  bool get showAudioRecord => _showAudioRecord.value;
  bool get hasReply => reply.isNotEmpty;
  String get currentlyPlayingAudio => _currentlyPlayingAudio.value;


  bool get isAtBottom {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    return (maxScroll - currentScroll) < 100; // Seuil de 100px
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================
  @override
  void onInit() {
    super.onInit();
    markMessagesAsRead();
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    _disposeAllAudioPlayers();
    messageController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  void _disposeAllAudioPlayers() {
    for (final player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();
    _currentlyPlayingAudio.value = '';
  }

  // ============================================================================
  // MESSAGE METHODS - CORRECTION: Ajout de sendMediaMessage
  // ============================================================================
  Callapi callapi = Callapi();
  // Future<void> callgpt() async {
  //   String data = await callapi.getOpenRouterResponse(messageController.text);
  //     answer.value = data;
  // }


  /// Envoie un message texte
  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    try {
      final messageData = {
        "id": _uuid.v4(),
        "content": text,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": receiverId,
        "isRead": false,
        "messageType": "text",
      };

      if (reply.isNotEmpty) {
        messageData["itemreply"] = reply.toList();
      }

      await Sms.add(messageData);
      reply.clear();
      response.value= messageController.text;
      messageController.clear();
      print("appel de l ia ");
      if(isOnline==false){
        String data = await callapi.getOpenRouterResponse(response.value);
        answer.value = data;
        print(data);
        print("appel de l ia ");
        final messageData = {
          "id": _uuid.v4(),
          "content": data,
          "timestamp": FieldValue.serverTimestamp(),
          "namesenderId": AppUser.info!.displayName,
          // "senderId": AppUser.info!.googleId,
          // "receiveId": receiverId,
          "senderId":  receiverId,
          "receiveId":  AppUser.info!.googleId,
          "isRead": false,
          "messageType": "text",
        };

        if (reply.isNotEmpty) {
          messageData["itemreply"] = reply.toList();
        }
        await Sms.add(messageData);
      }

      _sendNotificationInBackground(text);
    } catch (e) {
      Get.snackbar('Erreur', 'Échec de l\'envoi du message');
    }
  }

  /// ✅ CORRECTION: Ajout de cette méthode manquante
  /// Envoie un message média (image, vidéo, audio)
  Future<void> sendMediaMessage(String url, String type) async {
    try {
      await Sms.add({
        "id": _uuid.v4(),
        "content": url,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": receiverId,
        "isRead": false,
        "messageType": type,
      });

      // Notification pour les médias
      String notificationMessage = '';
      switch(type) {
        case 'image':
          notificationMessage = '📷 Photo';
          break;
        case 'video':
          notificationMessage = '🎥 Vidéo';
          break;
        case 'audio':
          notificationMessage = '🎤 Message vocal';
          break;
        default:
          notificationMessage = '📎 Fichier';
      }

      OneSignalService.sendNotificationToAll(
        title: AppUser.info!.displayName,
        message: notificationMessage,
        data: {"type": "chat_media", "media_type": type},
      );
    } catch (e) {
      debugPrint("❌ Erreur sendMediaMessage: $e");
      rethrow;
    }
  }

  void _sendNotificationInBackground(String message) {
    Future.microtask(() {
      OneSignalService.sendNotificationToAll(
        title: AppUser.info!.displayName,
        message: message,
        data: {"type": "chat_message"},
      );
    });
  }

  // ============================================================================
  // AUDIO PLAYER MANAGEMENT
  // ============================================================================
  Future<AudioPlayer> getAudioPlayer(String messageId, String url) async {
    if (!_audioPlayers.containsKey(messageId)) {
      final player = AudioPlayer();

      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (_currentlyPlayingAudio.value == messageId) {
            _currentlyPlayingAudio.value = '';
          }
        }
      });

      _audioPlayers[messageId] = player;
    }

    return _audioPlayers[messageId]!;
  }

  void pauseAudio(String messageId) {
    final player = _audioPlayers[messageId];
    if (player != null && player.playing) {
      player.pause();
      _currentlyPlayingAudio.value = '';
    }
  }

  void stopAllAudio() {
    for (final player in _audioPlayers.values) {
      if (player.playing) {
        player.stop();
      }
    }
    _currentlyPlayingAudio.value = '';
  }

  // ============================================================================
  // MEDIA PICKING & UPLOAD
  // ============================================================================

  /// Méthode principale pour sélectionner et envoyer un média
  Future<void> pickAndSendMedia(String type) async {
    XFile? pickedFile;

    try {
      switch (type) {
        case "image":
          pickedFile = await _imagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1024,
            maxHeight: 1024,
            imageQuality: 80,
          );
          break;
        case "video":
          pickedFile = await _imagePicker.pickVideo(
            source: ImageSource.gallery,
            maxDuration: const Duration(minutes: 5),
          );
          break;
        case "audio":
          pickedFile = await _imagePicker.pickMedia();
          break;
      }

      if (pickedFile != null) {
        await _uploadAndSendMedia(pickedFile, type);
      }
    } catch (e) {
      debugPrint("❌ Erreur pickAndSendMedia: $e");
      Get.snackbar('Erreur', 'Impossible de sélectionner le fichier');
    }
  }

  /// Upload et envoi du média
  Future<void> _uploadAndSendMedia(XFile file, String type) async {
    _isSendingMedia.value = true;

    try {
      // Vérifier que le fichier existe
      final filePath = file.path;
      final fileCheck = File(filePath);
      if (!await fileCheck.exists()) {
        throw Exception("Fichier non trouvé");
      }

      final extension = path.extension(filePath).toLowerCase();
      final fileName = '${_uuid.v4()}$extension';

      // Déterminer le dossier selon le type
      String folder = "kogossa_app/chat";
      if (type == "image") folder = "$folder/images";
      else if (type == "video") folder = "$folder/videos";
      else if (type == "audio") folder = "$folder/audio";

      // Upload vers Cloudinary
      final url = await UniversalCloudinaryUploader().uploadAnyFile(
        filePath: filePath,
        folder: folder,
        fileName: fileName,
      );

      if (url != null) {
        await sendMediaMessage(url, type);

        // Nettoyer le fichier temporaire après délai
        _cleanupTempFile(filePath);
      } else {
        throw Exception("Échec de l'upload");
      }
    } catch (e) {
      debugPrint("❌ Erreur upload: $e");
      Get.snackbar('Erreur', "Échec de l'envoi du ${type}");
    } finally {
      _isSendingMedia.value = false;
    }
  }

  void _cleanupTempFile(String path) {
    Future.delayed(const Duration(seconds: 10), () async {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignorer les erreurs de nettoyage
      }
    });
  }

  // ============================================================================
  // AUDIO RECORDING HANDLING
  // ============================================================================
  Future<void> handleAudioSend(String? audioPath) async {
    if (audioPath == null) return;

    _showAudioRecord.value = false;
    _isSendingMedia.value = true;

    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        throw Exception("Fichier audio non trouvé");
      }

      final url = await UniversalCloudinaryUploader().uploadAnyFile(
        filePath: audioPath,
        folder: "kogossa_app/chat/audio",
        fileName: 'audio_${_uuid.v4()}.m4a',
      );

      if (url != null) {
        await sendMediaMessage(url, 'audio');
        _cleanupTempFile(audioPath);
      }
    } catch (e) {
      debugPrint("❌ Erreur handleAudioSend: $e");
      Get.snackbar('Erreur', 'Échec de l\'envoi audio');
    } finally {
      _isSendingMedia.value = false;
    }
  }

  // ============================================================================
  // VIDEO THUMBNAIL
  // ============================================================================
  Future<String?> getVideoThumbnail(String videoUrl) async {
    final videoId = videoUrl.hashCode.toString();

    if (_processingVideos.contains(videoId)) {
      return null;
    }

    _processingVideos.add(videoId);

    try {
      final thumbnail = await ThumbVideo.get(Uri.parse(videoUrl));
      return thumbnail.body;
    } catch (e) {
      debugPrint("❌ Erreur thumbnail: $e");
      return null;
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _processingVideos.remove(videoId);
      });
    }
  }

  // ============================================================================
  // MESSAGE READING
  // ============================================================================
  Future<void> markMessagesAsRead() async {
    try {
      final snapshot = await Sms.where(
        "receiveId",
        isEqualTo: AppUser.info!.googleId,
      ).where("isRead", isEqualTo: false).limit(50).get();

      if (snapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("❌ Erreur markAsRead: $e");
    }
  }

  Future<void> markAudioAsPlayed(String messageId) async {
    try {
      await Sms.doc(messageId).update({'isRead': true});
    } catch (e) {
      debugPrint("❌ Erreur markAudioAsPlayed: $e");
    }
  }

  // ============================================================================
  // PARSING
  // ============================================================================
  List<Messagemodel> parseMessages(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Messagemodel(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        receiveId: data['receiveId'] ?? '',
        messageType: data['messageType'] ?? '',
        content: data['content'] ?? data['text'] ?? '',
        isRead: data['isRead'] ?? false,
        itemreply: data['itemreply'] ?? [],
        timestamp:
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  // ============================================================================
  // UI ACTIONS
  // ============================================================================
  void _onScroll() {
    if (!scrollController.hasClients) return;
    final showButton = scrollController.position.pixels <
        scrollController.position.maxScrollExtent - 200;
    if (showButton != _showScrollButton.value) {
      _showScrollButton.value = showButton;
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


  void scrollmanuel(){
    scrollController.addListener(() {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      _showlast.value = (maxScroll - currentScroll).abs() < 100; // Seuil de 100px
    });
  }

  void toggleAudioRecord() {
    if (_showAudioRecord.value) {
      _showAudioRecord.value = false;
    } else {
      stopAllAudio();
      focusNode.unfocus();
      _showAudioRecord.value = true;
    }
  }

  void hideAudioRecord() {
    if (_showAudioRecord.value) {
      _showAudioRecord.value = false;
    }
  }

  void setReply(String id, String content, String type) {
    reply.value = [
      {"idoc": id, "message": content, "type": type},
    ];
  }

  void clearReply() {
    reply.clear();
  }

  // ============================================================================
  // FULLSCREEN VIEWS
  // ============================================================================
  void openFullscreenVideo(String videoUrl) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: TikTokVideoPlayer(
            id: "",
            start: true,
            videoUrl: videoUrl,
            username: '',
            description: '',
            music: '',
            profileImage: '',
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }

  void openImagePreview(String url) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: url,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            ),
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }
}