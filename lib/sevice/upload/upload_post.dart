import 'package:cloud_firestore/cloud_firestore.dart';

import '../../main.dart';
import '../../model/datamodel/user_model.dart';
import '../../presentation/component/widget/widget_component.dart';
import '../controlleur/splashcontrolleur/splashscreen_controlleur.dart';


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
        print("Document n'existe pas");
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;
      print('Données du post: ${data['postData']}');

      // Récupérer l'utilisateur actuel
      String? currentUserId = AppUser.info?.googleId;
      String? currentUserName = AppUser.info?.displayName;
      String? currentUserAvatar = AppUser.info?.photoUrl;

      if (currentUserId == null) {
        print("Utilisateur non connecté");
        return;
      }

      // Récupérer la liste des personnes qui ont liké le POST (pas les commentaires)
      // D'après votre structure Firebase, c'est 'allike' dans postData
      List<dynamic> allike = [];

      // Vérifier si postData existe et contient allike
      if (data['postData'] != null) {
        Map<String, dynamic> postData = data['postData'] as Map<String, dynamic>;

        if (postData['allike'] != null && postData['allike'] is List) {
          allike = List.from(postData['allike']);
        }
      }

      print('Liste des likes avant: $allike');

      // Vérifier si l'utilisateur a déjà liké
      bool alreadyLiked = allike.contains(currentUserId);

      if (!alreadyLiked) {
        // Ajouter le like
        allike.add(currentUserId);
        print("👍 Like ajouté pour l'utilisateur: $currentUserId");
      } else {
        // Retirer le like
        allike.remove(currentUserId);
        print("👎 Like retiré pour l'utilisateur: $currentUserId");
      }

      print('Liste des likes après: $allike');

      // Mettre à jour le document
      await postRef.update({
        'postData.allike': allike,
        'postData.likes': allike.length, // Mettre à jour aussi le compteur
      });

      print('✅ Like mis à jour: ${!alreadyLiked ? "👍" : "👎"} (${allike.length} likes)');

    } catch (e) {
      print('❌ Erreur toggleLike: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }


  final String uniqueId =
      '${DateTime.now().millisecondsSinceEpoch}_${AppUser.info!.uid}_${WidgetComponent.generateRandomString(6)}';


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
        print("Document n'existe pas");
        return;
      }

      var data = snapshot.data() as Map<String, dynamic>;

      // Récupérer les commentaires
      List<dynamic> comments = List.from(
          data['postData']?['commentaire'] ?? []
      );

      // Trouver l'index du commentaire
      int index = comments.indexWhere((c) => c['id'] == commentId);

      if (index == -1) {
        print("Commentaire non trouvé");
        return;
      }

      // Récupérer l'utilisateur actuel
      String? currentUserId = AppUser.info?.googleId;
      String? currentUserName = AppUser.info?.displayName;
      String? currentUserAvatar = AppUser.info?.photoUrl;

      if (currentUserId == null) {
        print("Utilisateur non connecté");
        return;
      }

      // Créer une copie modifiable du commentaire
      Map<String, dynamic> currentComment =
      Map<String, dynamic>.from(comments[index]);

      // Récupérer la liste des personnes qui ont liké
      List<dynamic> allpersonnelike = [];
      if (currentComment['allpersonnelike'] != null) {
        allpersonnelike = List.from(currentComment['allpersonnelike']);
      }

      // Créer l'objet utilisateur pour le like
      final likeUser = {
        'idperson': AppUser.info?.googleId,
        'userId': AppUser.info?.googleId,
        'username': currentUserName ?? 'Utilisateur',
        'avatar': currentUserAvatar ?? '',
        'likedAt': DateTime.now().toIso8601String(),
      };

      // Mettre à jour la liste des likes (sans FieldValue)

        // Ajouter l'utilisateur s'il n'est pas déjà dans la liste
        bool alreadyLiked = allpersonnelike.any((u) => u['userId'] == currentUserId);
        if (!alreadyLiked) {
          allpersonnelike.add(likeUser);
          print("j ajoute");
          print("j ajoute");
        }else{
          allpersonnelike.removeWhere((u) => u['userId'] == currentUserId);
          print("jenleve");
          print("jenleve");
        }


      // Mettre à jour le commentaire
      // currentComment['isLiked'] = isLiked ?? false;
      currentComment['likes'] = allpersonnelike.length;
      currentComment['allpersonnelike'] = allpersonnelike;

      // Remplacer l'ancien commentaire
      comments[index] = currentComment;

      // Mettre à jour le document (sans FieldValue dans le tableau)
      await postRef.update({
        'postData.commentaire': comments,
      });

      print('✅ Like mis à jour: ${ allpersonnelike.any((u) => u['userId'] == currentUserId) == false ?  "👍" : "👎"} (${allpersonnelike.length} likes)');

    } catch (e) {
      print('❌ Erreur toggleLikecomment: $e');
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