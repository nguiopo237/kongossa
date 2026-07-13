import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../controlleur/firestore_collections_service.dart';
import '../../model/datamodel/user_model.dart';
import 'package:kongossa/shared/widgets/widgets.dart';


class PostUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;    // final String collectionName = 'posts'; // Adjust to your collection name

  // ============================================
  // 1. UPDATE TEXT CONTENT
  // ============================================
  Future<void> updatePostTitle(String postId, String newTitle) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.posttitle": newTitle,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "postData.isEdited": true,
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Post title updated");
    } catch (e) {
      debugPrint("❌ Error update title: $e");
      rethrow;
    }
  }

  // ============================================
  // 2. UPDATE IMAGES
  // ============================================
  Future<void> updatePostImages(String postId, List<String> newImages) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.imagepost": newImages,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Post images updated");
    } catch (e) {
      debugPrint("❌ Error update images: $e");
      rethrow;
    }
  }

  // Add an image
  Future<void> addImageToPost(String postId, String imageUrl) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.imagepost": FieldValue.arrayUnion([imageUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Image added to post");
    } catch (e) {
      debugPrint("❌ Error adding image: $e");
      rethrow;
    }
  }

  // Remove an image
  Future<void> removeImageFromPost(String postId, String imageUrl) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.imagepost": FieldValue.arrayRemove([imageUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Image removed from post");
    } catch (e) {
      debugPrint("❌ Error removing image: $e");
      rethrow;
    }
  }

  // ============================================
  // 3. UPDATE VIDEOS
  // ============================================
  Future<void> updatePostVideos(String postId, List<String> newVideos) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.videopost": newVideos,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Post videos updated");
    } catch (e) {
      debugPrint("❌ Error update videos: $e");
      rethrow;
    }
  }

  // Add a video
  Future<void> addVideoToPost(String postId, String videoUrl) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.videopost": FieldValue.arrayUnion([videoUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Video added to post");
    } catch (e) {
      debugPrint("❌ Error adding video: $e");
      rethrow;
    }
  }

  // ============================================
  // 4. UPDATE LIKES
  // ============================================
  Future<void> toggleLike({
    required String postId,
    bool? isLiked,
    required int like
  }) async {
    try {
      DocumentReference postRef = _firestore
          .collection('postcarduser')
          .doc(postId);

      DocumentSnapshot snapshot = await postRef.get();

      if (!snapshot.exists) {
        debugPrint("Document does not exist");
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;
      debugPrint('Post data: ${data['postData']}');

      // Récupérer l'utilisateur actuel
      String? currentUserId = AppUser.info?.googleId;
      String? currentUserName = AppUser.info?.displayName;
      String? currentUserAvatar = AppUser.info?.photoUrl;

      if (currentUserId == null) {
        debugPrint("User not logged in");
        return;
      }

      // Get the list of people who liked the POST (not comments)
      // Based on your Firebase structure, it's 'allike' in postData
      List<dynamic> allike = [];

      // Check if postData exists and contains allike
      if (data['postData'] != null) {
        Map<String, dynamic> postData = data['postData'] as Map<String, dynamic>;

        if (postData['allike'] != null && postData['allike'] is List) {
          allike = List.from(postData['allike']);
        }
      }

      debugPrint('Liste des likes avant: $allike');

      // Check if user already liked
      bool alreadyLiked = allike.contains(currentUserId);

      if (!alreadyLiked) {
        // Ajouter le like
        allike.add(currentUserId);
        debugPrint("👍 Like added for user: $currentUserId");
      } else {
        // Retirer le like
        allike.remove(currentUserId);
        debugPrint("👎 Like removed for user: $currentUserId");
      }

      debugPrint('Likes list after: $allike');

      // Mettre à jour le document
      await postRef.update({
        'postData.allike': allike,
        'postData.likes': allike.length, // Also update counter
      });

      debugPrint('✅ Like toggled: ${!alreadyLiked ? "👍" : "👎"} (${allike.length} likes)');

    } catch (e) {
      debugPrint('❌ Erreur toggleLike: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }


  Future<void> addfollowuser({
    required String postId,
  }) async {
    try {
      // 1. Check target user
      QuerySnapshot targetUserQuery = await FirestoreCollectionsService.users
          .where('googleId', isEqualTo: postId.trim())
          .limit(1)
          .get();

      if (targetUserQuery.docs.isEmpty) {
        debugPrint("❌ Target user not found");
        return;
      }

      // 2. Check current user
      String? currentUserId = AppUser.info?.googleId;
      if (currentUserId == null) {
        debugPrint("❌ User not logged in");
        return;
      }

      if (currentUserId == postId.trim()) {
        debugPrint("⚠️ Cannot follow self");
        return;
      }

      // 3. Get target document
      final targetDoc = targetUserQuery.docs.first;
      final targetData = targetDoc.data() as Map<String, dynamic>;

      // 4. Manage follower list
      List<String> followers = [];

      // Get existing list
      if (targetData.containsKey('allfollow') && targetData['allfollow'] != null) {
        if (targetData['allfollow'] is List) {
          followers = List<String>.from(targetData['allfollow'].map((e) => e.toString()));
        }
      }

      // 5. Check and update
      bool isFollowing = followers.contains(currentUserId);

      if (isFollowing) {
        followers.remove(currentUserId);
      } else {
        followers.add(currentUserId);
      }

      // 6. Update Firestore
      await FirestoreCollectionsService.users.doc(targetDoc.id).update({
        'allfollow': followers,
        'followersCount': followers.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      debugPrint(isFollowing
          ? "👎 Vous ne suivez plus cet utilisateur"
          : "👍 Vous suivez maintenant cet utilisateur");

    } catch (e, stackTrace) {
      debugPrint('❌ Erreur: $e');

    }
  }






  final String uniqueId =
      '${DateTime.now().millisecondsSinceEpoch}_${AppUser.info?.uid??"0"}_${WidgetComponent.generateRandomString(6)}';


  Future<void> toggleLikecomment({
    required String postId,
    String? commentId,
    // bool? isLiked,
    required int like,
  }) async

  {
    try {
      DocumentReference postRef = _firestore
          .collection('postcarduser')
          .doc(postId);

      DocumentSnapshot snapshot = await postRef.get();

      if (!snapshot.exists) {
        debugPrint("Document does not exist");
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;

      // Get comments
      List<dynamic> comments = List.from(
          data['postData']?['commentaire'] ?? []
      );

      // Trouver l'index du commentaire
      int index = comments.indexWhere((c) => c['id'] == commentId);

      if (index == -1) {
        debugPrint("Comment not found");
        return;
      }

      // Récupérer l'utilisateur actuel
      String? currentUserId = AppUser.info?.googleId;
      String? currentUserName = AppUser.info?.displayName;
      String? currentUserAvatar = AppUser.info?.photoUrl;

      if (currentUserId == null) {
        debugPrint("User not logged in");
        return;
      }

      // Create a mutable copy of the comment
      Map<String, dynamic> currentComment =
      Map<String, dynamic>.from(comments[index]);

      // Get the list of people who liked
      List<dynamic> allpersonnelike = [];
      if (currentComment['allpersonnelike'] != null) {
        allpersonnelike = List.from(currentComment['allpersonnelike']);
      }

      // Create user object for the like
      final likeUser = {
        'idperson': AppUser.info?.googleId,
        'userId': AppUser.info?.googleId,
        'username': currentUserName ?? 'Utilisateur',
        'avatar': currentUserAvatar ?? '',
        'likedAt': DateTime.now().toIso8601String(),
      };

      // Update likes list (without FieldValue)
        bool alreadyLiked = allpersonnelike.any((u) => u['userId'] == currentUserId);
        if (!alreadyLiked) {
          allpersonnelike.add(likeUser);
          debugPrint("j ajoute");
          debugPrint("j ajoute");
        }else{
          allpersonnelike.removeWhere((u) => u['userId'] == currentUserId);
          debugPrint("jenleve");
          debugPrint("jenleve");
        }


      // Update comment
      // currentComment['isLiked'] = isLiked ?? false;
      currentComment['likes'] = allpersonnelike.length;
      currentComment['allpersonnelike'] = allpersonnelike;

      // Remplacer l'ancien commentaire
      comments[index] = currentComment;

      // Update document (without FieldValue in array)
      await postRef.update({
        'postData.commentaire': comments,
      });

      debugPrint('✅ Like toggled: ${ allpersonnelike.any((u) => u['userId'] == currentUserId) == false ?  "👍" : "👎"} (${allpersonnelike.length} likes)');

    } catch (e) {
      debugPrint('❌ Erreur toggleLikecomment: $e');
    }
  }
  // ============================================
  // 5. UPDATE COMMENTS
  // ============================================
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    try {
      final commentWithMeta = {
        ...comment,
        "commentId": FirestoreCollectionsService.posts.doc().id,
        "userId": AppUser.info!.googleId,
        "userName": AppUser.info!.displayName,
        "userPhoto": AppUser.info!.photoUrl,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.commentaire": FieldValue.arrayUnion([commentWithMeta]),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Comment added");
    } catch (e) {
      debugPrint("❌ Error adding comment: $e");
      rethrow;
    }
  }

  Future<void> removeComment(String postId, String commentId) async {
    try {
      // Récupérer le post pour trouver le commentaire spécifique
      final data = await FirestoreCollectionsService.posts.doc(postId).get();
      final postData = data?['postData'] as Map<String, dynamic>?;
      final comments = List.from(postData?['commentaire'] ?? []);
      // final comments = List.from(doc.data()?['postData']['commentaire'] ?? []);

      final updatedComments = comments.where((c) => c['commentId'] != commentId).toList();

      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.commentaire": updatedComments,
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Comment removed");
    } catch (e) {
      debugPrint("❌ Error removing comment: $e");
      rethrow;
    }
  }

  // ============================================
  // 6. UPDATE STATUS
  // ============================================
  Future<void> updatePostStatus(String postId, String newStatus) async {
    try {
      await FirestoreCollectionsService.posts.doc(postId).update({
        "postData.status": newStatus,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      debugPrint("✅ Post status updated: $newStatus");
    } catch (e) {
      debugPrint("❌ Error updating status: $e");
      rethrow;
    }
  }

  // ============================================
  // 7. COMPLETE POST UPDATE
  // ============================================
  Future<void> updateFullPost(String postId, {
    String? newTitle,
    List<String>? newImages,
    List<String>? newVideos,
    String? newStatus,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (newTitle != null) {
        updates["postData.posttitle"] = newTitle;
      }
      if (newImages != null) {
        updates["postData.imagepost"] = newImages;
      }
      if (newVideos != null) {
        updates["postData.videopost"] = newVideos;
      }
      if (newStatus != null) {
        updates["postData.status"] = newStatus;
      }

      updates["postData.updatedAt"] = FieldValue.serverTimestamp();
      updates["timestamp"] = FieldValue.serverTimestamp();
      updates["postData.isEdited"] = true;

      await FirestoreCollectionsService.posts.doc(postId).update(updates);
      debugPrint("✅ Post fully updated");
    } catch (e) {
      debugPrint("❌ Error full update: $e");
      rethrow;
    }
  }

  // ============================================
  // 8. BATCH UPDATE (MULTIPLE OPERATIONS)
  // ============================================
  Future<void> updatePostWithBatch(String postId, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      final postRef = FirestoreCollectionsService.posts.doc(postId);

      // Post update
      batch.update(postRef, {
        ...updates,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Add history entry
      final historyRef = postRef.collection('history').doc();
      batch.set(historyRef, {
        "userId": AppUser.info!.googleId,
        "userName": AppUser.info!.displayName,
        "changes": updates,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await batch.commit();
      debugPrint("✅ Post updated with batch and history");
    } catch (e) {
      debugPrint("❌ Error batch update: $e");
      rethrow;
    }
  }
}