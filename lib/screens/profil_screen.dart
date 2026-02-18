// lib/screens/profile/premium_profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../main.dart';
import '../model/datamodel/profil_model.dart';
import '../presentation/component/widget/avatar_premuim.dart';
import '../sevice/theme/theme_profil.dart';
import 'mymember/chatpage.dart';

class PremiumProfileScreen extends StatefulWidget {
  final String? userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? mail;

  PremiumProfileScreen({
    Key? key,
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.mail,
  }) : super(key: key);

  @override
  State<PremiumProfileScreen> createState() => _PremiumProfileScreenState();
}

class _PremiumProfileScreenState extends State<PremiumProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  bool isCurrentUser = false; // À définir selon l'utilisateur connecté

  // Données mockées pour l'exemple
  late UserProfileModel userProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    // Simuler le chargement des données
    userProfile = UserProfileModel(
      uid: widget.userId!,
      username: '@${widget.displayName}',
      displayName: '${widget.displayName}',
      avatarUrl: '${widget.avatarUrl}',
      bio: '${widget.bio}',
      website: '${widget.mail}',
      followersCount: 12500,
      followingCount: 850,
      likesCount: 125000,
      postsCount: 42,
      isVerified: true,
      joinedDate: DateTime.now().subtract(const Duration(days: 365)),
      posts: List.generate(
        12,
        (index) => PostModel(
          id: 'post_$index',
          mediaUrl: 'https://picsum.photos/300/400?random=$index',
          mediaType: index % 3 == 0 ? MediaType.video : MediaType.image,
          likesCount: 1500 + index * 100,
          commentsCount: 85 + index,
          timestamp: DateTime.now().subtract(Duration(days: index)),
        ),
      ),
    );
  }

  Stream watchUserPostCount() {
    return Posts.where(
      'userData.googleId',
      isEqualTo: widget.userId,
    ).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar personnalisée
          SliverAppBar(
            expandedHeight: 40.h,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),

          // Informations du profil
          SliverToBoxAdapter(child: _buildProfileInfo()),

          // Statistiques
          SliverToBoxAdapter(child: _buildStatsRow()),

          // Boutons d'action
          if (widget.userId != AppUser.info!.googleId)
            SliverToBoxAdapter(child: _buildActionButtons()),

          // Stories
          SliverToBoxAdapter(child: _buildStoriesSection()),

          // Tab Bar
          SliverToBoxAdapter(child: _buildTabBar()),

          // Grille des posts
          SliverPadding(
            padding: EdgeInsets.only(right: 0.5.w, left: 0.5, bottom: 10.h),
            sliver: _buildPostsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image de couverture
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
          ),
        ),

        // Overlay gradient
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

  Widget _buildProfileInfo() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PremiumAvatar(
                // imageUrl: userProfile.avatarUrl,
                userId: widget.userId,
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
                      userProfile.displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userProfile.username,
                      style: TextStyle(fontSize: 14, color: Colors.blue),
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
          if (userProfile.website != null)
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

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('postcarduser')
          .where('userData.googleId', isEqualTo: widget.userId) // Posts de l'utilisateur
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        // Statistiques pour les posts de l'utilisateur
        final docs = snapshot.data!.docs;
        int postsCount = docs.length;
        int totalLikesRecus = 0; // Likes sur SES posts

        for (var doc in docs) {
          Map<String, dynamic> postData = doc.data() as Map<String, dynamic>;
          List<dynamic> allike = postData["postData"]['allike'] ?? [];
          // if (allike.contains(widget.userId))
          if (allike.isNotEmpty) {
            totalLikesRecus += 1;
            print('📝 Post ${doc.id}: Liké par cet utilisateur');
            print(totalLikesRecus);
          } else {
            print('📝 Post ${doc.id}: Non liké par cet utilisateur');
          }
          print('📝 Post ${doc.id}: ${allike.length} likes reçus }');
        }
        print("totalLikesRecus");
        print(totalLikesRecus);
        print("totalLikesRecus");

        // Pour compter les likes DONNÉS par l'utilisateur (sur les posts des autres)
        int likesDonnes = 0;
        // Il faudra une autre requête pour ça
        // Je vous montre après

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(value: postsCount.toString(), label: 'Posts'),
              _buildStatItem(
                value: _formatNumber(userProfile.followersCount),
                label: 'Followers',
              ),
              _buildStatItem(
                value: _formatNumber(userProfile.followingCount),
                label: 'Following',
              ),
              _buildStatItem(
                value: totalLikesRecus.toString(), // 👍 Likes REÇUS
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

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isFollowing = !isFollowing;
                });
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
                  ChatPage(
                    receiverId: widget.userId!,
                    receiverName: widget.displayName ?? "anonyme",
                    receiverPhoto: widget.avatarUrl,
                    // isOnline: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 3.w),
            child: Column(
              children: [
                PremiumAvatar(
                  imageUrl: 'https://i.pravatar.cc/150?img=${index + 1}',
                  size: 60,
                  hasStory: index % 3 != 0,
                ),
                const SizedBox(height: 4),
                Text(
                  'Story ${index + 1}',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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

  Widget _buildPostsGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = userProfile.posts?[index];
        return _buildGridItem(post);
      }, childCount: userProfile.posts?.length ?? 0),
    );
  }

  Widget _buildGridItem(PostModel? post) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image/Video thumbnail
        Image.network(post?.mediaUrl ?? '', fit: BoxFit.cover),

        // Overlay gradient
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (post?.mediaType == MediaType.video)
                  const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      _formatNumber(post?.likesCount ?? 0),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
