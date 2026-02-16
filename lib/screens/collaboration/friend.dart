import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../main.dart';
import '../../presentation/component/video_component/tiktok_player_video.dart';

class FriendFeedScreen extends StatelessWidget {
  // Données statiques pour le développement (à commenter en production)


  String url = "";
  String urls = "";

  // Méthode pour récupérer les vidéos depuis Firestore
  Stream<List<Map<String, dynamic>>> _getVideosFromFirestore() {
    List<dynamic> comment = [];
    List<dynamic> alllike = [];
    return
        Posts.where("postData.videopost", isNotEqualTo: [])
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
        // Vérifier si le document a une vidéo valide
        final videoData = doc['postData'];
        if (videoData == null) return false;

        final videoUrl = videoData['videopost'];
        return videoUrl != null && videoUrl.toString().isNotEmpty;
      })
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final postData = data['postData'] as Map<String, dynamic>? ?? {};
        final userData = data['userData'] as Map<String, dynamic>? ?? {};

        if (postData!= null &&
            postData['commentaire'] != null) {
          comment = List.from(postData['commentaire']);
        }
        if (postData!= null &&
            postData['allike'] != null) {
          alllike = List.from(postData['allike']);
        }

        return {
          'videoUrl': postData['videopost'] ?? '',
          'posttitle': postData['posttitle'] ?? '',
          'username': userData['name'] ?? 'Utilisateur',
          'description': postData['posttitle'] ?? 'description',
          'music': data['music'] ?? 'Son original',
          'likes': postData['likes'] ?? 0,
          'islike': postData['islike'] ?? false,
          'comments': postData['comments'] ?? 0,
          'shares': postData['shares'] ?? 0,
          'profileImage': userData['photoUrl'] ?? '',
          'postId': doc.id,
          'timestamp': data['timestamp'],
          'comment':comment,
          'alllike':alllike,
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body:  StreamBuilder<List<Map<String, dynamic>>>(
        // Utiliser les données mockées en développement, Firestore en production
        // stream: _getVideosFromFirestore(), // Décommentez pour Firestore
        stream: _getVideosFromFirestore(), // Commentez en production
        builder: (context, snapshot) {
          // Gestion des états de chargement
          print('🔥 StreamBuilder rebuild à ${DateTime.now().millisecondsSinceEpoch}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          // Gestion des erreurs
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Recharger
                    },
                    child: Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Vérifier si les données existent
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    color: Colors.white.withOpacity(0.7),
                    size: 70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune vidéo disponible',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les vidéos apparaîtront ici',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Récupérer les vidéos filtrées
          final videos = snapshot.data!;



          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            controller: PageController(initialPage: 0),
            itemBuilder: (context, index) {
              final video = videos[index];


              return Padding(
                padding:  EdgeInsets.only(bottom: 10.h),
                child: TikTokVideoPlayer(
                  id: video['postId'].toString(),
                  videoUrl:  video['videoUrl'].toString(),
                  username: video['username'] ?? '',
                  description: video['description'] ?? '',
                  music: video['music'] ?? 'Son original',
                  likes: List.from(video['alllike']).length,
                  isLiked: video['islike'],
                  comments: List.from(video['comment']).length,
                  alllike:  List.from(video['alllike']),
                  shares: video['shares'] ?? 0,
                  profileImage: video['profileImage'] ?? '',
                ),
              );
            },
          );
        },
      ),
    );
  }
}