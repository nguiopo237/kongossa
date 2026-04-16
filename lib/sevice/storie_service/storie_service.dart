// lib/services/story_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../model/datamodel/storyModels.dart';
import '../../model/datamodel/user_model.dart';


class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _storiesCollection =>
      _firestore.collection('stories');

  CollectionReference get _usersCollection =>
      _firestore.collection('users');

  // Ajouter une story pour un utilisateur
  Future<void> addStory(StoryModel story) async {
    try {
      final userId =  AppUser.info?.googleId;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // await _storiesCollection
      //     .doc(userId)
      //     .collection('user_stories')
      //     .doc(story.id)
      //     .set(story.toMap());
      //
      // await _usersCollection.doc(userId).update({
      //   'lastStoryTimestamp': FieldValue.serverTimestamp(),
      // });
      final state =  await Story.add(story.toMap());
      print(state.id) ;
      print(story.timestamp) ;
      print(story.stories.first.id) ;

      print('✅ Story ajoutée avec succès: ${story.id}');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout de la story: $e');
      rethrow;
    }
  }

  // Récupérer toutes les stories des utilisateurs suivis
  Stream<List<StoryModel>> getFollowingStories() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    // Récupérer la liste des utilisateurs suivis
    return _usersCollection
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      final List<String> followingIds = followingSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      if (followingIds.isEmpty) return [];

      // Ajouter l'utilisateur courant
      followingIds.add(currentUserId);

      // Récupérer les stories de tous ces utilisateurs
      final List<StoryModel> allStories = [];

      for (String userId in followingIds) {
        final stories = await getUserStories(userId);
        if (stories != null && stories.stories.isNotEmpty) {
          allStories.add(stories);
        }
      }

      // Trier par date de dernière story
      allStories.sort((a, b) {
        final aDate = a.timestamp!=null ? a.timestamp : DateTime.now();
        final bDate = b.timestamp!=null ? b.timestamp : DateTime.now();
        return bDate.compareTo(aDate);
      });

      return allStories;
    });
  }

  // Récupérer les stories d'un utilisateur spécifique
  Future<StoryModel?> getUserStories(String userId) async {
    try {
      // Récupérer les infos de l'utilisateur
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;

      // Récupérer les stories de l'utilisateur (moins de 24h)
      final storiesSnapshot = await _storiesCollection
          .doc(userId)
          .collection('user_stories')
          .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
          .orderBy('timestamp', descending: false)
          .get();

      final List<StoryItem> storyItems = storiesSnapshot.docs
          .map((doc) => StoryItem.fromMap(doc.data()))
          .toList();

      if (storyItems.isEmpty) return null;

      // Vérifier si l'utilisateur courant a vu ces stories
      final currentUserId = _auth.currentUser?.uid;
      bool isViewed = false;

      if (currentUserId != null) {
        final viewDoc = await _storiesCollection
            .doc(userId)
            .collection('views')
            .doc(currentUserId)
            .get();

        isViewed = viewDoc.exists;
      }

      return StoryModel(
        id: userId,
        userName: userData['userName'] ?? 'Unknown',
        userAvatar: userData['userAvatar'] ?? '',
        stories: storyItems,
        isViewed: isViewed,
      );
    } catch (e) {
      print('❌ Erreur lors de la récupération des stories: $e');
      return null;
    }
  }

  // Version simplifiée sans StreamGroup
  Stream<List<StoryModel>> getStoriesStream() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    // Écouter les changements dans la liste des abonnements
    return _usersCollection
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .asyncExpand((followingSnapshot) async* {
      final List<String> userIds = followingSnapshot.docs
          .map((doc) => doc.id)
          .toList();
      userIds.add(currentUserId);

      // Récupérer toutes les stories à chaque changement
      final List<StoryModel> allStories = [];

      for (String userId in userIds) {
        final stories = await getUserStories(userId);
        if (stories != null && stories.stories.isNotEmpty) {
          allStories.add(stories);
        }
      }

      // Trier par date
      allStories.sort((a, b) {
        final aDate = a.timestamp!=null ? a.timestamp : DateTime.now();
        final bDate = b.timestamp!=null ? b.timestamp : DateTime.now();
        return bDate.compareTo(aDate);
      });

      yield allStories;
    });
  }

  // Marquer une story comme vue
  Future<void> markStoryAsViewed(String userId, String storyId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) throw Exception('Utilisateur non connecté');

      await _storiesCollection
          .doc(userId)
          .collection('views')
          .doc(currentUserId)
          .set({
        'viewedAt': FieldValue.serverTimestamp(),
        'lastStoryId': storyId,
      }, SetOptions(merge: true));

      print('✅ Story marquée comme vue: $storyId');
    } catch (e) {
      print('❌ Erreur lors du marquage de la story: $e');
      rethrow;
    }
  }

  // Supprimer les stories expirées (plus de 24h)
  Future<void> deleteExpiredStories() async {
    try {
      final expiryDate = DateTime.now().subtract(const Duration(hours: 24));

      // Récupérer tous les utilisateurs
      final usersSnapshot = await _usersCollection.get();

      for (var userDoc in usersSnapshot.docs) {
        final expiredStories = await _storiesCollection
            .doc(userDoc.id)
            .collection('user_stories')
            .where('timestamp', isLessThan: expiryDate)
            .get();

        final batch = _firestore.batch();
        for (var storyDoc in expiredStories.docs) {
          batch.delete(storyDoc.reference);
        }

        await batch.commit();
      }

      print('✅ Stories expirées supprimées');
    } catch (e) {
      print('❌ Erreur lors de la suppression des stories expirées: $e');
      rethrow;
    }
  }

  // Supprimer une story spécifique
  Future<void> deleteStory(String userId, String storyId) async {
    try {
      await _storiesCollection
          .doc(userId)
          .collection('user_stories')
          .doc(storyId)
          .delete();

      print('✅ Story supprimée: $storyId');
    } catch (e) {
      print('❌ Erreur lors de la suppression de la story: $e');
      rethrow;
    }
  }

  // Ajouter un item à une story existante
  Future<void> addStoryItem(String userId, StoryItem storyItem) async {
    try {
      await _storiesCollection
          .doc(userId)
          .collection('story')
          .doc(storyItem.id)
          .set(storyItem.toMap());
      // await Story.add(data)
      await Story.add(storyItem.toMap());

    } catch (e) {
      print('❌ Erreur lors de l\'ajout du story item: $e');
      rethrow;
    }
  }
}