// lib/screens/profile/premium_profile_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../main.dart';
import '../model/datamodel/profil_model.dart';
import '../presentation/component/widget/avatar_premuim.dart';

import '../sevice/controlleur/thmbvideo/thum_video.dart';
import '../sevice/theme/theme_profil.dart';
import '../sevice/upload/upload_post.dart';
import 'collaboration/friend.dart';
import 'mymember/chatpage.dart';

class PremiumProfileScreen extends StatefulWidget {
  final String? userId;
  final String? id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? mail;

  const PremiumProfileScreen({
    Key? key,
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.id,
    this.mail,
  }) : super(key: key);

  @override
  State<PremiumProfileScreen> createState() => _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends State<PremiumProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  bool isCurrentUser = false;
  int followersCount = 0;
  int followingCount = 0;

  late UserProfileModel userProfile;
  final PostUpdateService service =
  PostUpdateService();

  // Cache pour les miniatures vidéo
  final Map<String, String?> _thumbnailCache = {};
  final Map<String, Future<String?>> _thumbnailFutures = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _setupFollowersListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupFollowersListener() {
    if (widget.userId == null) return;

    Users.where("googleId", isEqualTo: widget.userId).snapshots().listen(
          (QuerySnapshot snapshot) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added ||
              change.type == DocumentChangeType.modified) {
            final data = change.doc.data() as Map<String, dynamic>?;
            if (data != null) {
              final allfollow = data['allfollow'];
              if (allfollow is List) {
                if (mounted) {
                  setState(() {
                    followersCount = allfollow.length;
                  });
                }
                debugPrint("📊 Nombre de followers: ${allfollow.length}");
              }
            }
          }
        }
      },
      onError: (error) {
        debugPrint("❌ Erreur listener followers: $error");
      },
    );
  }

  void _loadUserData() {
    userProfile = UserProfileModel(
      uid: widget.userId ?? '',
      username: '@${widget.displayName ?? 'utilisateur'}',
      displayName: widget.displayName ?? 'Utilisateur',
      avatarUrl: widget.avatarUrl ?? '',
      bio: widget.bio ?? '',
      website: widget.mail ?? '',
      followersCount: 12500,
      followingCount: 850,
      likesCount: 125000,
      postsCount: 42,
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
      posts: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const Scaffold(
        body: Center(child: Text('ID utilisateur non fourni')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: StreamBuilder<QuerySnapshot>(
        stream: Users.where('googleId', isEqualTo: widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDoc = snapshot.data!.docs.first;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildProfileInfo(userDoc)),
              SliverToBoxAdapter(child: _buildStatsRow(userDoc)),
              if (widget.userId != AppUser.info?.googleId)
                SliverToBoxAdapter(child: _buildActionButtons(userDoc)),
              SliverToBoxAdapter(child: _buildStoriesSection(userDoc)),
              SliverToBoxAdapter(child: _buildTabBar()),
              _buildPostsGrid(), // Maintenant retourne directement un Sliver
            ],
          );
        },
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 40.h,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.backgroundColor,
      flexibleSpace: FlexibleSpaceBar(background: _buildHeaderBackground()),
      actions: [
        IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppTheme.backgroundColor.withOpacity(0.9),
              ],
            ),
          ),
          child: Image.network(
            'https://picsum.photos/500/800',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: Colors.grey[300]);
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, AppTheme.backgroundColor],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAvatar(
                userId: data['googleId'] ?? '',
                size: 80,
                hasStory: true,
                isVerified: userProfile.isVerified,
                isLive: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Nom non défini',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${data['email'] ?? 'email@exemple.com'}',
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            userProfile.bio ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          if (userProfile.website != null && userProfile.website!.isNotEmpty)
            InkWell(
              onTap: () {},
              child: Text(
                userProfile.website!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'A rejoint ${_formatDate(userProfile.joinedDate)}',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(QueryDocumentSnapshot<Object?> userDoc) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('postcarduser')
          .where('userData.googleId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        int postsCount = 0;
        int totalLikesRecus = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          postsCount = docs.length;

          for (var doc in docs) {
            final postData = doc.data() as Map<String, dynamic>;
            final allike = postData['postData']?['allike'] as List? ?? [];
            totalLikesRecus += allike.length;
          }
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final followers = userData['allfollow'] as List? ?? [];

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(value: _formatNumber(postsCount), label: 'Posts'),
              _buildStatItem(
                value: _formatNumber(followers.length),
                label: 'Followers',
              ),
              _buildStatItem(
                value: _formatNumber(followingCount),
                label: 'Following',
              ),
              _buildStatItem(
                value: _formatNumber(totalLikesRecus),
                label: 'Likes reçus',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButtons(QueryDocumentSnapshot<Object?> doc) {
    final userData = doc.data() as Map<String, dynamic>;
    final followers = userData['allfollow'] as List? ?? [];
    final isFollowing = followers.contains(AppUser.info?.googleId);

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                service.addfollowuser(postId: widget.userId!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? Colors.transparent
                    : AppTheme.primaryColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isFollowing
                      ? BorderSide(color: AppTheme.dividerColor)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.message_outlined),
              onPressed: () {
                Get.to(
                      () => ChatPageTikTok(
                    receiverId: userData['googleId'] ?? '',
                    receiverName: userData['name'] ?? 'Anonyme',
                    receiverPhoto: userData['photoUrl'] ?? '',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection(QueryDocumentSnapshot<Object?> doc) {
    final userData = doc.data() as Map<String, dynamic>;
    final followers = userData['allfollow'] as List? ?? [];

    if (followers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 8.h,
      // color: Colors.green,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: followers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumAvatar(
                  userId: followers[index].toString(),
                  size: 60,
                  hasStory: index % 3 != 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        indicatorWeight: 3,
        labelColor: AppTheme.textPrimary,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on_outlined, color: Colors.blue)),
          Tab(icon: Icon(Icons.favorite_border, color: Colors.blue)),
          Tab(icon: Icon(Icons.bookmark_border, color: Colors.blue)),
        ],
      ),
    );
  }

  // ==================== FONCTIONS POUR LES POSTS AVEC MINIATURES VIDÉO ====================

  Map<String, dynamic> _getSafeMap(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (e) {
        debugPrint('⚠️ Erreur conversion Map: $e');
        return {};
      }
    }
    return {};
  }

  List<dynamic> _getSafeList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value;
    if (value is List<dynamic>) return value;
    if (value is Iterable) return value.toList();
    return [];
  }

  MediaType _getMediaType(String? type, bool hasImages, bool hasVideos) {
    if (hasVideos) return MediaType.video;
    if (hasImages) return MediaType.image;

    if (type == null) return MediaType.image;

    switch (type.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'image':
        return MediaType.image;
      case 'multiple':
      case 'carousel':
        return MediaType.multiple;
      default:
        return MediaType.image;
    }
  }

  // Fonction pour générer une miniature vidéo avec cache
  Future<String?> _getVideoThumbnail(String videoUrl) async {
    // Vérifier le cache
    if (_thumbnailCache.containsKey(videoUrl)) {
      return _thumbnailCache[videoUrl];
    }

    // Vérifier si une future est déjà en cours
    if (_thumbnailFutures.containsKey(videoUrl)) {
      return _thumbnailFutures[videoUrl];
    }

    // Créer une nouvelle future
    final future = _generateThumbnail(videoUrl);
    _thumbnailFutures[videoUrl] = future;

    final result = await future;

    // Mettre en cache et nettoyer la future
    if (mounted) {
      setState(() {
        _thumbnailCache[videoUrl] = result;
        _thumbnailFutures.remove(videoUrl);
      });
    }

    return result;
  }

  Future<String?> _generateThumbnail(String videoUrl) async {
    try {
      // Vérifier d'abord si la vidéo est en cache
      final fileInfo = await DefaultCacheManager().getFileFromCache(videoUrl);

      String videoPath = videoUrl;
      if (fileInfo != null && fileInfo.file.existsSync()) {
        videoPath = fileInfo.file.path;
      }

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 300,
        maxHeight: 300,
        quality: 75,
      );

      debugPrint('✅ Miniature générée pour: $videoUrl');
      return thumbnailPath;
    } catch (e) {
      debugPrint('❌ Erreur génération miniature: $e');
      return null;
    }
  }

  // Widget pour l'affichage des posts avec miniatures
   _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('postcarduser')
          .where('userData.googleId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return const SliverToBoxAdapter(
        //     child: Center(
        //       child: Padding(
        //         padding: EdgeInsets.all(20),
        //         child: CircularProgressIndicator(),
        //       ),
        //     ),
        //   );
        // }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erreur: ${snapshot.error}'),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucun post pour le moment'),
              ),
            ),
          );
        }

        final documents = snapshot.data!.docs;

        return SliverPadding(
          padding: EdgeInsets.only(
            right: 0.5.w,
            left: 0.5.w,
            bottom: 10.h,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                try {
                  final postDoc = documents[index];
                  final postData = postDoc.data() as Map<String, dynamic>;

                  _getSafeMap(postData['userData']);
                  final postContent = _getSafeMap(postData['postData']);

                  final allike = _getSafeList(postContent['allike']);
                  final commentaires = _getSafeList(postContent['commentaire']);
                  final images = _getSafeList(postContent['imagepost']);
                  final videos = _getSafeList(postContent['videopost']);

                  String mediaUrl = '';
                  bool isVideo = videos.isNotEmpty;

                  if (isVideo) {
                    // C'est une vidéo
                    final firstVideo = videos.first;
                    if (firstVideo is String) {
                      mediaUrl = firstVideo;
                    } else if (firstVideo is Map) {
                      mediaUrl = firstVideo['url'] ?? firstVideo.toString();
                    } else {
                      mediaUrl = firstVideo.toString();
                    }
                  } else if (images.isNotEmpty) {
                    // C'est une image
                    final firstImage = images.first;
                    if (firstImage is String) {
                      mediaUrl = firstImage;
                    } else if (firstImage is Map) {
                      mediaUrl = firstImage['url'] ?? firstImage.toString();
                    } else {
                      mediaUrl = firstImage.toString();
                    }
                  } else {
                    // Fallback
                    mediaUrl = postContent['mediaUrl']?.toString() ??
                        postContent['videoUrl']?.toString() ?? '';
                  }

                  final mediaTypeStr = postContent['mediaType'] as String?;
                  final mediaType = _getMediaType(
                      mediaTypeStr,
                      images.isNotEmpty,
                      videos.isNotEmpty
                  );

                  Timestamp? timestamp;
                  if (postContent['timestamp'] is Timestamp) {
                    timestamp = postContent['timestamp'] as Timestamp;
                  } else if (postData['timestamp'] is Timestamp) {
                    timestamp = postData['timestamp'] as Timestamp;
                  }

                  final post = PostModel(
                    id: postDoc.id,
                    mediaUrl: mediaUrl,
                    commentsCount: commentaires.length,
                    likesCount: allike.length,
                    mediaType: mediaType,
                    timestamp: timestamp?.toDate() ?? DateTime.now(),
                  );

                  return _buildGridItem(post,index);
                } catch (e, stackTrace) {
                  debugPrint('❌ Erreur post $index: $e');
                  debugPrint('📋 StackTrace: $stackTrace');
                  return _buildErrorGridItem();
                }
              },
              childCount: documents.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(PostModel post,index) {
    return GestureDetector(
      onTap: () {
        debugPrint('📱 Post cliqué: ${post.id} (${post.mediaType})');
        if(post.mediaType.toString().contains("video")){
          Get.to(FriendFeedScreen(
            userid: widget.userId!,
            indexed: index,
          ));
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Affichage selon le type
          if (post.mediaType == MediaType.video)
        Thumbvideo(videoUrl: post.mediaUrl,)

          else
            _buildImageThumbnail(post.mediaUrl),

          // Overlay gradient
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMediaTypeIcon(post.mediaType),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.favorite, color: Colors.white, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        _formatNumber(post.likesCount),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (post.mediaType == MediaType.multiple)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.collections, color: Colors.white, size: 16),
            ),

          if (post.mediaType == MediaType.video)
            const Positioned(
              top: 4,
              left: 4,
              child: Icon(Icons.play_circle_filled, color: Colors.white, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String imageUrl) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder(Icons.hide_image, 'Image\nmanquante');
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(
        Icons.broken_image,
        'Image\nindisponible',
      ),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    if (videoUrl.isEmpty) {
      return _buildPlaceholder(Icons.videocam_off, 'Vidéo\nmanquante');
    }

    return FutureBuilder<String?>(
      future: _getVideoThumbnail(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Erreur chargement miniature: $error');
              return _buildVideoPlaceholder();
            },
          );
        } else {
          return _buildVideoPlaceholder();
        }
      },
    );
  }

  Widget _buildPlaceholder(IconData icon, String message) {
    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white54, size: 30),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: Colors.white54, fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _StripesPainter()),
          const Center(
            child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.video:
        return const Icon(Icons.play_circle_outline, color: Colors.white, size: 16);
      case MediaType.multiple:
        return const Icon(Icons.photo_library_outlined, color: Colors.white, size: 16);
      case MediaType.image:
        return const SizedBox(width: 16);
      default:
        return const Icon(Icons.help_outline, color: Colors.white54, size: 16);
    }
  }

  Widget _buildErrorGridItem() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 30),
            SizedBox(height: 4),
            Text(
              'Erreur',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime date) {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Painter pour les lignes (effet vidéo)
class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (i + 1) / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}