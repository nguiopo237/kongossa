import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../model/datamodel/user_model.dart';


class PostUpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String collectionName = 'posts'; // Adaptez selon votre nom de collection

  // ============================================
  // 1. UPDATE DU CONTENU TEXTE
  // ============================================
  Future<void> updatePostTitle(String postId, String newTitle) async {
    try {
      await Posts.doc(postId).update({
        "postData.posttitle": newTitle,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "postData.isEdited": true,
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Titre du post mis à jour");
    } catch (e) {
      print("❌ Erreur update titre: $e");
      rethrow;
    }
  }

  // ============================================
  // 2. UPDATE DES IMAGES
  // ============================================
  Future<void> updatePostImages(String postId, List<String> newImages) async {
    try {
      await Posts.doc(postId).update({
        "postData.imagepost": newImages,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Images du post mises à jour");
    } catch (e) {
      print("❌ Erreur update images: $e");
      rethrow;
    }
  }

  // Ajouter une image
  Future<void> addImageToPost(String postId, String imageUrl) async {
    try {
      await Posts.doc(postId).update({
        "postData.imagepost": FieldValue.arrayUnion([imageUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Image ajoutée au post");
    } catch (e) {
      print("❌ Erreur ajout image: $e");
      rethrow;
    }
  }

  // Supprimer une image
  Future<void> removeImageFromPost(String postId, String imageUrl) async {
    try {
      await Posts.doc(postId).update({
        "postData.imagepost": FieldValue.arrayRemove([imageUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Image supprimée du post");
    } catch (e) {
      print("❌ Erreur suppression image: $e");
      rethrow;
    }
  }

  // ============================================
  // 3. UPDATE DES VIDEOS
  // ============================================
  Future<void> updatePostVideos(String postId, List<String> newVideos) async {
    try {
      await Posts.doc(postId).update({
        "postData.videopost": newVideos,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Vidéos du post mises à jour");
    } catch (e) {
      print("❌ Erreur update vidéos: $e");
      rethrow;
    }
  }

  // Ajouter une vidéo
  Future<void> addVideoToPost(String postId, String videoUrl) async {
    try {
      await Posts.doc(postId).update({
        "postData.videopost": FieldValue.arrayUnion([videoUrl]),
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Vidéo ajoutée au post");
    } catch (e) {
      print("❌ Erreur ajout vidéo: $e");
      rethrow;
    }
  }

  // ============================================
  // 4. UPDATE DES LIKES
  // ============================================
  Future<void> toggleLike(String postId, bool isLiked) async {
    try {
      await Posts.doc(postId).update({
        "postData.likes": FieldValue.increment(isLiked ? 1 : -1),
        "postData.islike": isLiked ? true : false,
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Like ${isLiked ? 'ajouté' : 'retiré'}");
    } catch (e) {
      print("❌ Erreur toggle like: $e");
      rethrow;
    }
  }

  // ============================================
  // 5. UPDATE DES COMMENTAIRES
  // ============================================
  Future<void> addComment(String postId, Map<String, dynamic> comment) async {
    try {
      final commentWithMeta = {
        ...comment,
        "commentId": Posts.doc().id,
        "userId": AppUser.info!.googleId,
        "userName": AppUser.info!.displayName,
        "userPhoto": AppUser.info!.photoUrl,
        "createdAt": FieldValue.serverTimestamp(),
      };

      await Posts.doc(postId).update({
        "postData.commentaire": FieldValue.arrayUnion([commentWithMeta]),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Commentaire ajouté");
    } catch (e) {
      print("❌ Erreur ajout commentaire: $e");
      rethrow;
    }
  }

  Future<void> removeComment(String postId, String commentId) async {
    try {
      // Récupérer le post pour trouver le commentaire spécifique
      final data = await Posts.doc(postId).get();
      final postData = data?['postData'] as Map<String, dynamic>?;
      final comments = List.from(postData?['commentaire'] ?? []);
      // final comments = List.from(doc.data()?['postData']['commentaire'] ?? []);

      final updatedComments = comments.where((c) => c['commentId'] != commentId).toList();

      await Posts.doc(postId).update({
        "postData.commentaire": updatedComments,
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Commentaire supprimé");
    } catch (e) {
      print("❌ Erreur suppression commentaire: $e");
      rethrow;
    }
  }

  // ============================================
  // 6. UPDATE DU STATUT
  // ============================================
  Future<void> updatePostStatus(String postId, String newStatus) async {
    try {
      await Posts.doc(postId).update({
        "postData.status": newStatus,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });
      print("✅ Statut du post mis à jour: $newStatus");
    } catch (e) {
      print("❌ Erreur update statut: $e");
      rethrow;
    }
  }

  // ============================================
  // 7. UPDATE COMPLET DU POST
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

      await Posts.doc(postId).update(updates);
      print("✅ Post mis à jour complètement");
    } catch (e) {
      print("❌ Erreur update complet: $e");
      rethrow;
    }
  }

  // ============================================
  // 8. UPDATE AVEC BATCH (PLUSIEURS OPÉRATIONS)
  // ============================================
  Future<void> updatePostWithBatch(String postId, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      final postRef = Posts.doc(postId);

      // Mise à jour du post
      batch.update(postRef, {
        ...updates,
        "postData.updatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      // Ajouter une entrée dans l'historique
      final historyRef = postRef.collection('history').doc();
      batch.set(historyRef, {
        "userId": AppUser.info!.googleId,
        "userName": AppUser.info!.displayName,
        "changes": updates,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await batch.commit();
      print("✅ Post mis à jour avec batch et historique");
    } catch (e) {
      print("❌ Erreur batch update: $e");
      rethrow;
    }
  }
}