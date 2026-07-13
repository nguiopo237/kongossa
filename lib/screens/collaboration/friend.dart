import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../presentation/component/video_component/tiktok_player_video.dart';

class FriendFeedScreen extends StatefulWidget {

  // Données statiques pour le développement (à commenter en production)
  FriendFeedScreen( {this.userid ="",this.indexed=0 });

  final String userid ;
  final int indexed ;

  @override
  State<FriendFeedScreen> createState() => _FriendFeedScreenState();
}

class _FriendFeedScreenState extends State<FriendFeedScreen> {
  final String url = "";

  final  String urls = "";

  late PageController _pageController;



  int _currentPage = 0;

  // Méthode unique pour récupérer les vidéos depuis Firestore
  Stream<List<Map<String, dynamic>>> getVideosFromFirestore({String? userId}) {
    return _buildVideosStream(userId: userId);
  }

  Stream<List<Map<String, dynamic>>> _buildVideosStream({String? userId}) {
    Query query = FirestoreCollectionsService.posts
        .where("postData.videopost", isNotEqualTo: []);

    if (userId != null && userId.isNotEmpty) {
      query = query.where("userData.googleId", isEqualTo: userId);
    }

    return query
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
        final videoData = doc['postData'];
        if (videoData == null) return false;
        final videoUrl = videoData['videopost'];
        return videoUrl != null && videoUrl.toString().isNotEmpty;
      })
          .map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final postData = data['postData'] as Map<String, dynamic>? ?? {};
        final userData = data['userData'] as Map<String, dynamic>? ?? {};

        final comment = postData['commentaire'] != null
            ? List.from(postData['commentaire'])
            : <dynamic>[];
        final alllike = postData['allike'] != null
            ? List.from(postData['allike'])
            : <dynamic>[];

        return {
          'videoUrl': postData['videopost'] ?? '',
          'posttitle': postData['posttitle'] ?? '',
          'username': userData['name'] ?? 'Utilisateur',
          'email': userData['email'] ?? '',
          'bio': userData['bio'] ?? '',
          'uid': userData['googleId'] ?? '',
          'description': postData['posttitle'] ?? 'description',
          'music': data['music'] ?? 'Son original',
          'likes': postData['likes'] ?? 0,
          'islike': postData['islike'] ?? false,
          'comments': postData['comments'] ?? 0,
          'shares': postData['shares'] ?? 0,
          'profileImage': userData['photoUrl'] ?? '',
          'postId': doc.id,
          'timestamp': data['timestamp'],
          'comment': comment,
          'alllike': alllike,
        };
      }).toList();
    });
  }
  bool _isPageViewReady = false;


  String get restorationId => 'video_gallery';



  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Initialiser le controller SANS initialPage
    _pageController = PageController();

    // Attendre que le widget soit complètement construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Marquer que le PageView est prêt
        setState(() {
          _isPageViewReady = true;
        });

        // Attendre un frame supplémentaire pour être sûr
        Future.delayed(Duration(milliseconds: 100), () {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(widget.indexed);
            debugPrint("✅ Jumped to page ${widget.indexed}");
          } else {
            debugPrint("⚠️ PageView not ready yet");
          }
        });
      }
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
        stream: getVideosFromFirestore(userId: widget.userid.isNotEmpty ? widget.userid : null),     // Commentez en production
        builder: (context, snapshot) {
          // Gestion des états de chargement
          debugPrint('🔥 StreamBuilder rebuild at ${DateTime.now().millisecondsSinceEpoch}');
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
                    'friend.loading_error'.tr,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Recharger
                    },
                    child: Text('app.retry'.tr),
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
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 70,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'friend.no_videos'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'friend.videos_here'.tr,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            controller:_pageController,
            restorationId: restorationId,

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
                  shares: widget.indexed,
                  profileImage: video['profileImage'] ?? '',
                  uid :video['uid'],
                  mail :video['email'],
                  bio :video['bio'],

                ),
              );
            },
          );
        },
      ),
    );
  }
}