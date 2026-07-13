import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../model/datamodel/live_model.dart';
import '../../model/datamodel/user_model.dart';
import '../videosdk/videosdk_service.dart';
import 'firestore_collections_service.dart';

/// Contrôleur des Lives.
///
/// ⚠️ Index Firestore requis :
/// Pour que les requêtes `.where('status', isEqualTo: 'live').orderBy('startedAt', descending: true)`
/// fonctionnent, créez un index composite sur la collection `lives` :
///   - Champ 1 : `status` (ordre : asc)
///   - Champ 2 : `startedAt` (ordre : desc)
/// L'index se crée automatiquement via un lien dans les logs Firestore.
class LiveController extends GetxController {
  static LiveController get to => Get.find();

  final RxList<LiveModel> activeLives = <LiveModel>[].obs;
  final RxList<LiveModel> pastLives = <LiveModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLive = false.obs;
  final RxString currentLiveId = ''.obs;
  final RxInt viewerCount = 0.obs;

  StreamSubscription? _activeLivesSub;
  StreamSubscription? _pastLivesSub;

  @override
  void onInit() {
    super.onInit();
    _listenActiveLives();
    _listenPastLives();
  }

  void _listenActiveLives() {
    _activeLivesSub = FirestoreCollectionsService.lives
        .where('status', isEqualTo: 'live')
        .orderBy('startedAt', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      activeLives.value = snapshot.docs
          .map((doc) => LiveModel.fromFirestore(doc))
          .toList();
    });
  }

  void _listenPastLives() {
    _pastLivesSub = FirestoreCollectionsService.lives
        .where('status', isEqualTo: 'ended')
        .orderBy('startedAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      pastLives.value = snapshot.docs
          .map((doc) => LiveModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Démarrer un nouveau live avec une room VideoSDK.
  ///
  /// Returns `{liveId, roomId}` on success, `null` on failure.
  Future<Map<String, String>?> startLive({
    required String title,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      final user = AppUser.info;
      if (user == null) return null;

      // 1. Create a VideoSDK room
      final roomId = await VideoSdkService.to.createRoom();

      // 2. Save the Firestore live doc
      final live = LiveModel(
        id: '',
        hostId: user.googleId,
        hostName: user.displayName,
        hostAvatar: user.photoUrl ?? '',
        title: title,
        description: description ?? '',
        status: LiveStatus.live,
        streamUrl: 'videosdk://$roomId',
        startedAt: DateTime.now(),
        viewerIds: [user.googleId],
      );

      final docRef = await FirestoreCollectionsService.lives.add(live.toFirestore());
      currentLiveId.value = docRef.id;
      isLive.value = true;

      await _updateViewerCount(docRef.id, 1);

      return {
        'liveId': docRef.id,
        'roomId': roomId,
      };
    } catch (e) {
      debugPrint('❌ startLive error: $e');
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Terminer un live en cours.
  Future<void> endLive(String liveId) async {
    try {
      await FirestoreCollectionsService.lives.doc(liveId).update({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      });
      isLive.value = false;
      currentLiveId.value = '';
    } catch (e) {
      debugPrint('❌ endLive error: $e');
    }
  }

  /// Rejoindre un live (incrémente le compteur si pas déjà dedans).
  Future<void> joinLive(String liveId) async {
    try {
      final user = AppUser.info;
      if (user == null) return;

      final doc = await FirestoreCollectionsService.lives.doc(liveId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final viewerIds = List<String>.from(data['viewerIds'] ?? []);
      if (viewerIds.contains(user.googleId)) return;

      viewerIds.add(user.googleId);
      await FirestoreCollectionsService.lives.doc(liveId).update({
        'viewerIds': viewerIds,
        'viewers': viewerIds.length,
      });
    } catch (e) {
      debugPrint('❌ joinLive error: $e');
    }
  }

  Future<void> leaveLive(String liveId) async {
    try {
      final user = AppUser.info;
      if (user == null) return;

      final doc = await FirestoreCollectionsService.lives.doc(liveId).get();
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;

      final viewerIds = List<String>.from(data['viewerIds'] ?? []);
      viewerIds.remove(user.googleId);
      await FirestoreCollectionsService.lives.doc(liveId).update({
        'viewerIds': viewerIds,
        'viewers': viewerIds.length,
      });
    } catch (e) {
      debugPrint('❌ leaveLive error: $e');
    }
  }

  Future<void> _updateViewerCount(String liveId, int delta) async {
    await FirestoreCollectionsService.lives.doc(liveId).update({
      'viewers': FieldValue.increment(delta),
    });
  }

  /// Envoyer un message dans le chat du live.
  Future<void> sendMessage(String liveId, String message) async {
    if (message.trim().isEmpty) return;
    try {
      final user = AppUser.info;
      if (user == null) return;

      await FirestoreCollectionsService.lives
          .doc(liveId)
          .collection('messages')
          .add({
        'userId': user.googleId,
        'userName': user.displayName,
        'userAvatar': user.photoUrl ?? '',
        'message': message.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ sendMessage error: $e');
    }
  }

  /// Stream des messages du chat.
  Stream<QuerySnapshot> messagesStream(String liveId) {
    return FirestoreCollectionsService.lives
        .doc(liveId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  @override
  void onClose() {
    _activeLivesSub?.cancel();
    _pastLivesSub?.cancel();
    super.onClose();
  }
}
