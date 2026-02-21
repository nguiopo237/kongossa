import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kongossa/presentation/component/style/custum_text.dart';
import 'package:kongossa/presentation/component/widget/appbar.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:kongossa/screens/home/part_of_home/tending_section.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';

import '../../config_App/colorsApp.dart';
import '../../main.dart';
import '../../model/datamodel/membermodel.dart';
import '../../model/datamodel/user_model.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/video_component/comment_video.dart';
import '../../presentation/component/video_component/tiktok_player_video.dart';
import '../../presentation/component/widget/collaboration.dart';
import '../../presentation/component/widget/component_for_post/option_card.dart';
import '../../sevice/controlleur/thmbvideo/thum_video.dart';
import '../../sevice/upload/upload_post.dart';
import '../profil_screen.dart';

class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  // Variables pour les stories
  final List<Map<String, dynamic>> stories = [
    {'name': 'Votre story', 'image': null, 'isAdd': true},
    {'name': 'Marie', 'image': 'assets/avaters/Avatar 1.jpg', 'hasStory': true},
    {
      'name': 'Thomas',
      'image': 'assets/avaters/Avatar 2.jpg',
      'hasStory': true,
    },
    {
      'name': 'Sophie',
      'image': 'assets/avaters/Avatar 3.jpg',
      'hasStory': true,
    },
    {
      'name': 'Lucas',
      'image': 'assets/avaters/Avatar 4.jpg',
      'hasStory': false,
    },
  ];

  // Variables pour les shorts
  final List<Map<String, dynamic>> shorts = [
    {
      'title': 'Tendances du jour',
      'thumbnail': 'assets/short1.jpg',
      'views': '1.2M',
    },
    {
      'title': 'Nouveau challenge',
      'thumbnail': 'assets/short2.jpg',
      'views': '856K',
    },
    {'title': 'Tuto rapide', 'thumbnail': 'assets/short3.jpg', 'views': '2.1M'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(pinned: true, flexibleSpace: ProfessionalAppBar()),

              // AppBar moderne avec recherche
              SliverToBoxAdapter(child: _buildStoriesSection()),

              // Barre d'onglets
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.blue,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Pour vous'),
                      Tab(text: 'Shorts'),
                      Tab(text: 'Abonnements'),
                      Tab(text: 'Tendances'),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // Fil d'actualité principal
              _buildFeedTab(),

              // Section Shorts
              _buildShortsTab(),

              // Abonnements
              _buildSubscriptionsTab(),

              // Tendances
              // _buildTrendingTab(),
              PremiumTrendsSection()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(1.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Kongossa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(width: 2.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 16.sp, color: Colors.blue),
              SizedBox(width: 1.w),
              Text(
                'Publier',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 12.h,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return _buildStoryItem(story);
        },
      ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> story) {
    return Container(
      width: 18.w,
      margin: EdgeInsets.symmetric(horizontal: 1.w, vertical: 1.h),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 14.w,
                height: 14.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: story['hasStory'] == true
                      ? const LinearGradient(
                          colors: [Colors.purple, Colors.orange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: story['hasStory'] == true
                      ? Border.all(width: 2, color: Colors.transparent)
                      : Border.all(width: 1, color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: story['image'] != null
                        ? AssetImage(story['image'])
                        : null,
                    child: story['isAdd'] == true
                        ? Container(
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              if (story['isAdd'] == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(0.5.w),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_circle,
                      color: Colors.blue,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            story['name'],
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: story['isAdd'] == true
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: Posts.orderBy("timestamp", descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyFeed();
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            return _buildModernPostCard(doc);
          },
        );
      },
    );
  }

  PostUpdateService service = PostUpdateService();

  Widget _buildModernPostCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final userData = data['userData'] as Map<String, dynamic>? ?? {};
    final postData = data['postData'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 0.1.w, vertical: 1.h),
      elevation: 2,
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du post
          ListTile(
            onTap: () {
              Get.to(
                () => PremiumProfileScreen(
                  userId: userData["googleId"],
                  avatarUrl: userData["photoUrl"],
                  displayName: userData["name"],
                  username: userData["name"],
                  mail: userData["email"],
                  bio:
                      userData["email"] ??
                      "Créateur de contenu | Digital Creator ✨\nCollaborations ",
                ),
              );
            },
            leading: CustomImage(
              source: userData['photoUrl'].toString(),
              type: ImageType.avatar,
              width: 12.w,
              height: 16.h,
            ),
            title: Text(
              userData['name'] ?? 'Utilisateur',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              timeago.format(_getSafeDateTime(data['timestamp']), locale: 'fr'),
            ),

            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () {
                WidgetComponent.getmodal(
                  isScrollControlled: true,
                  sectionview: SizedBox(
                    height: Get.height / 1.26,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PostOptionsMenu(
                          postId: doc.id,
                          onDelete: () {
                            Posts.doc(doc.id).delete().then((value) {
                              Get.back();
                              WidgetComponent.showNotification(
                                "Post supprimer avec succes",
                                Colors.green,
                                context,
                              );
                            });
                          },

                          isCurrentUser:
                              userData['googleId'] == AppUser.info?.googleId
                              ? true
                              : false,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Contenu du post
          if (postData['posttitle'] != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: CustomText(postData['posttitle'],type: TextType.titleMedium,),
              // child: Text(
              //   postData['posttitle'],
              //   style: TextStyle(fontSize: 15.sp),
              // ),
            ),
          SizedBox(height: 1.h,),

          // Image/Vidéo du post
          if (List.from(postData['imagepost']).isNotEmpty)
            _buildPostMedia(
              List.from(postData['imagepost']).first.toString(),
              doc.id,
            ),
          if (List.from(postData['videopost']).isNotEmpty)
            _buildPostvideo(
              List.from(postData['videopost']).first.toString(),
              doc.id,
            ),

          // Statistiques
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              children: [
                _buildReactionIcons(
                  count: List.from(postData['allike']).length,
                ),
                Spacer(),
                Text(
                  '${postData['commentaire']?.length ?? 0} commentaires',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // Barre d'actions
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                icon:
                    List.from(
                      postData['allike'],
                    ).contains(AppUser.info!.googleId)
                    ? Icons.thumb_up_alt_rounded
                    : Icons.thumb_up_outlined,
                color:
                    List.from(
                      postData['allike'],
                    )!.contains(AppUser.info!.googleId)
                    ? Colors.red
                    : Colors.grey.shade700,
                label: "J\'aime",
                onpress: () {
                  service.toggleLike(postId: doc.id);
                },
              ),
              _buildActionButton(
                icon: Icons.mode_comment_outlined,
                label: "Commenter",

                onpress: () {
                  Future.microtask(() {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      // ou true avec hauteur
                      // fixe
                      builder: (context) => ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        child: SizedBox(
                          height: Get.height / 1.3,
                          child: CommentModal(videoId: doc.id, videoTitle: ''),
                        ),
                      ),
                    );
                  });
                },
              ),
              _buildActionButton(
                icon: Icons.share_outlined,
                label: "Partager",
                onpress: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostMedia(dynamic media, id) {
    return ClipRRect(
      // borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: media!,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 40.h,
              color: Colors.grey[100],
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(ColorApp.primary1.withOpacity(0.5)),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 40.h,
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 40.sp, color: Colors.grey[400]),
                  SizedBox(height: 1.h),
                  Text(
                    'Image non disponible',
                    style: GoogleFonts.poppins(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 2.w,
            right: 2.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.photo_rounded, color: Colors.white, size: 14.sp),
                  SizedBox(width: 1.w),
                  Text(
                    "1/1 • HD",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostvideo(dynamic media, id) {
    return Container(
      height: 50.h,

      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 1.h),
      color: Colors.grey.shade300,
      child: ClipRRect(
        child: TikTokVideoPlayer(
          id: id,
          videoUrl: media!,
          username: '',
          description: '',
          music: '',
          profileImage: '',
        ),
      ),
    );
  }

  Widget _buildReactionIcons({count = 0}) {
    return Row(
      children: [
        if (count == 0) SizedBox(),
        if (count != 0)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.thumb_up, size: 12, color: Colors.white),
          ),
        if (count == 0) SizedBox(),
        if (count != 0)
          Container(
            margin: const EdgeInsets.only(left: 2),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, size: 12, color: Colors.white),
          ),

        SizedBox(width: 2.w),
        if (count == 0) SizedBox(),
        if (count != 0)
          Text('${count}', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    String? label,
    VoidCallback? onpress,
    Color? color = Colors.grey,
  }) {
    return TextButton.icon(
      onPressed: onpress,
      icon: Icon(icon, size: 18.sp),
      label: Text(label!, style: TextStyle(fontSize: 13.sp)),
      style: TextButton.styleFrom(foregroundColor: color),
    );
  }

  Stream<List<Map<String, dynamic>>> getVideosFromFirestores() {
    List<dynamic> comment = [];
    List<dynamic> alllike = [];
    return Posts.where(
      "postData.videopost",
      isNotEqualTo: [],
    ).orderBy("timestamp", descending: true).snapshots().map((snapshot) {
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

            if (postData != null && postData['commentaire'] != null) {
              comment = List.from(postData['commentaire']);
            }
            if (postData != null && postData['allike'] != null) {
              alllike = List.from(postData['allike']);
            }

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
          })
          .toList();
    });
  }

  Widget _buildShortsTab() {
    return StreamBuilder(
      stream: getVideosFromFirestores(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        final short = snapshot.data!;
        return GridView.builder(
          padding: EdgeInsets.all(2.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.w,
          ),
          itemCount: short.length,
          itemBuilder: (context, index) {
            final item = short[index];
            return _buildShortCard(item);
          },
        );
      },
    );
  }

  Widget _buildShortCard(Map<String, dynamic> short) {
    return InkWell(
      onTap: () {
        WidgetComponent.getmodal(
          sectionview: Container(
            height: Get.height,
            width: Get.width,
            color: Colors.transparent,
            child: Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: TikTokVideoPlayer(
                id: short['postId'].toString(),
                videoUrl: short['videoUrl'].toString(),
                start: true,
                username: '',
                description: '',
                music: '',
                profileImage: '',

                // username: short['username'] ?? '',
                // description: short['description'] ?? '',
                // music: short['music'] ?? 'Son original',
                // likes: List.from(short['alllike']).length,
                // isLiked: short['islike'],
                // comments: List.from(short['comment']).length,
                // alllike:  List.from(short['alllike']),
                // // shares: docs.,
                // profileImage: short['profileImage'] ?? '',
                // uid :short['uid'],
                // mail :short['email'],
                // bio :short['bio'],
              ),
            ),
          ),
        );
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/Backgrounds/up2.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),

              child: Stack(
                fit: StackFit.expand,
                children: [
                  Thumbvideo(
                    videoUrl: List.from(short['videoUrl']).first.toString(),
                  ),
                  Icon(Icons.play_arrow, color: Colors.white),
                ],
              ),
            ),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    short['description'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        ' ${List.from(short['alllike']).length} vues',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SHORT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:Users
          .where("googleId", isNotEqualTo: AppUser.info?.googleId)
          .snapshots(),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          );
        }

        // Gestion des erreurs
        if (snapshot.hasError) {
          print('Erreur StreamBuilder: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vérifie ta connexion',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        // Vérification des données
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucun membre trouvé',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Conversion des données en liste de MemberModel
        final members = snapshot.data!.docs
            .map((doc) => MemberModel.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: EdgeInsets.all(2.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.6,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.w,
          ),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final item = members[index];
            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Collaboratecard(
                initialStatus: 4,
                isSearch: false,
                user: UserCollaborationModel(
                  id: item.googleId,
                  fullname: item.username,
                  competences: [],
                  username: item.username,
                  countCollaborator: item.followersCount,
                  countFollowing: item.followingCount,
                  countFollowers: item.followersCount,
                  isVerified: false,
                  photoUrl: item.photoUrl ?? '',
                  email: item.email ?? '',
                ),
                showStats: true,
                photoUrl: item.photoUrl ?? '',
                username: item.username,
              ),
            );
          },
        );
      },
    );
  }
}


Widget _buildEmptyFeed() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.feed_outlined, size: 48.sp, color: Colors.grey.shade400),
        SizedBox(height: 2.h),
        Text(
          'Bienvenue sur Kongossa',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Découvrez du contenu qui vous intéresse',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
          ),
          child: const Text('Explorer'),
        ),
      ],
    ),
  );
}

DateTime _getSafeDateTime(dynamic timestamp) {
  try {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
  } catch (e) {
    print('Erreur de conversion timestamp: $e');
  }
  return DateTime.now();
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
