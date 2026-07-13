// lib/screens/profile/premium_profile_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../config_App/colorsApp.dart';
import '../sevice/controlleur/firestore_collections_service.dart';
import '../utils/transitions.dart';
import '../model/datamodel/profil_model.dart';
import '../shared/widgets/avatar_premuim.dart';
import '../sevice/theme/theme_switcher_provider.dart';
import 'settings/settings_screen.dart';
import 'package:kongossa/sevice/upload/upload.dart';
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
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  bool isCurrentUser = false;
  int followersCount = 0;
  int followingCount = 0;

  late UserProfileModel userProfile;
  final PostUpdateService service = PostUpdateService();

  // Cache pour les miniatures vidéo
  final Map<String, String?> _thumbnailCache = {};
  final Map<String, Future<String?>> _thumbnailFutures = {};

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── Helpers de couleurs adaptatives ──

  /// Couleur de fond de la scène depuis le thème actif.
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;

  /// `ColorScheme.primary` (premiumGold dans les deux thèmes).
  Color get _gold => Theme.of(context).colorScheme.primary;

  /// `onSurface` (texte principal).
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;

  /// `surfaceContainerHighest` (surfaces élevées).
  Color get _surfaceHigh => Theme.of(context).colorScheme.surfaceContainerHighest;

  /// Fond des placeholders media (s'adapte au thème).
  Color get _placeholderBg => _isDark ? Colors.grey[900]! : Colors.grey[200]!;

  /// Texte secondaire/subtil (onSurfaceVariant).
  Color get _subtle => Theme.of(context).colorScheme.onSurfaceVariant;

  /// Thème sombre actif ?
  bool get _isDark => ThemeSwitcherProvider.isDarkMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
    _setupFollowersListener();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupFollowersListener() {
    if (widget.userId == null) return;

    FirestoreCollectionsService.users.where("googleId", isEqualTo: widget.userId).snapshots().listen(
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
      displayName: widget.displayName ?? 'profile.user'.tr,
      avatarUrl: widget.avatarUrl ?? '',
      bio: widget.bio ?? '',
      website: '',
      followersCount: 0,
      followingCount: 0,
      likesCount: 0,
      postsCount: 0,
      isVerified: false,
      joinedDate: DateTime.now(),
      posts: [],
    );
    _loadFollowingCount();
  }

  /// Récupère le nombre d'abonnements (following) depuis Firestore.
  Future<void> _loadFollowingCount() async {
    if (widget.userId == null) return;
    try {
      final result = await FirestoreCollectionsService.users
          .where('allfollow', arrayContains: widget.userId)
          .get();
      if (mounted) {
        setState(() {
          followingCount = result.docs.length;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur comptage following: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return Scaffold(
        body: Center(child: Text('profile.user_id_missing'.tr)),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreCollectionsService.users.where('googleId', isEqualTo: widget.userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('profile.error'.tr + ': ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final userDoc = snapshot.data!.docs.first;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildProfileInfo(context, userDoc)),
              SliverToBoxAdapter(child: _buildStatsRow(userDoc)),
              if (widget.userId != AppUser.info?.googleId)
                SliverToBoxAdapter(child: _buildActionButtons(userDoc)),
              // Section Paramètres (visible uniquement pour le profil de l'utilisateur connecté)
              if (widget.userId == AppUser.info?.googleId)
                SliverToBoxAdapter(child: _buildSettingsSection()),
              SliverToBoxAdapter(child: _buildStoriesSection(userDoc)),
              SliverToBoxAdapter(child: _buildTabBar()),
              _buildPostsGrid(),
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
      backgroundColor: _bg,
      flexibleSpace: FlexibleSpaceBar(background: _buildHeaderBackground()),
      actions: [
        IconButton(
          icon: Icon(Icons.share_outlined, color: _gold),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: _gold),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeaderBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image de couverture avec overlay gradient premium
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _bg.withValues(alpha: 0.95),
              ],
            ),
          ),
          child: Image.network(
            'https://picsum.photos/500/800',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorApp.premiumGoldDark,
                      Colors.black,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
        ),
        // Overlay doré subtil
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _bg,
                ],
              ),
            ),
          ),
        ),
        // Ligne dorée décorative
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _gold.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(BuildContext context, QueryDocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar premium avec halo doré animé
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.3),
                          blurRadius: 15 * _pulseAnimation.value,
                          spreadRadius: 2 * _pulseAnimation.value - 2,
                        ),
                      ],
                    ),
                    child: PremiumAvatar(
                      userId: data['googleId'] ?? '',
                      size: 80,
                      hasStory: true,
                      isVerified: userProfile.isVerified,
                      isLive: true,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom avec gradient doré
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          Color(0xFFD4AF37),
                          Color(0xFFFFF8DC),
                          Color(0xFFD4AF37),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        data['name'] ?? 'profile.name_undefined'.tr,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 12, color: _gold.withValues(alpha: 0.6)),
                        SizedBox(width: 4),
                        Text(                      '${data['email'] ?? 'profile.email_placeholder'.tr}',
                            style: TextStyle(
                              fontSize: 14,
                              color: _gold.withValues(alpha: 0.6),
                            ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Badge premium
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFF0D060)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12.sp, color: Colors.black),
                    SizedBox(width: 1.w),
                    Text(
                      'app.premium'.tr,
                      style: TextStyle(
                        fontSize: 8.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            final bio = data['bio'] as String? ?? '';
            if (bio.isNotEmpty) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, size: 14.sp, color: _gold),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          bio,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: _subtle),
              SizedBox(width: 6),
              Text(
                'profile.joined'.tr + '${_formatDate(userProfile.joinedDate)}',
                style: TextStyle(fontSize: 12, color: _subtle),
              ),
            ],
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
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _gold.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPremiumStatItem(value: _formatNumber(postsCount), label: 'profile.posts'.tr, icon: Icons.article),
                _buildPremiumStatItem(value: _formatNumber(followers.length), label: 'profile.followers'.tr, icon: Icons.people),
                _buildPremiumStatItem(value: _formatNumber(followingCount), label: 'profile.following'.tr, icon: Icons.follow_the_signs),
                _buildPremiumStatItem(value: _formatNumber(totalLikesRecus), label: 'profile.likes'.tr, icon: Icons.favorite),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumStatItem({required String value, required String label, required IconData icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _gold.withValues(alpha: 0.6)),
        SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFFFF8DC)],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _subtle,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Section Paramètres avec bascule dark/light mode
  Widget _buildSettingsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gold.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _gold.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(Icons.settings_outlined, size: 16, color: _gold),
                SizedBox(width: 2.w),
                Text(
                  'profile.settings'.tr,
                  style: TextStyle(
                    color: _onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            // Lien vers l'écran de réglages complet
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => AppTransitions.toPremium(const SettingsScreen()),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h),
                child: Row(
                  children: [
                    Icon(Icons.open_in_new_rounded, size: 16, color: _gold),
                    SizedBox(width: 3.w),
                    Text(
                      'profile.all_settings'.tr,
                      style: TextStyle(
                        color: _gold,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: _gold.withValues(alpha: 0.6)),
                  ],
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Divider(height: 1, color: (ThemeSwitcherProvider.isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            SizedBox(height: 1.h),
            // Sélecteur de thème : Sombre / Système / Clair
            Obx(() {
              final currentMode = ThemeSwitcherProvider.currentMode;
              final isDark = ThemeSwitcherProvider.isDarkMode;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentMode == ThemeMode.light
                            ? Icons.light_mode_outlined
                            : currentMode == ThemeMode.system
                                ? Icons.brightness_auto_outlined
                                : Icons.dark_mode_outlined,
                        size: 20,
                        color: _gold,
                      ),
                      SizedBox(width: 3.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.theme'.tr,
                            style: TextStyle(
                              color: _onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ThemeSwitcherProvider.currentLabel,
                            style: TextStyle(
                              color: _subtle,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('profile.dark'),
                          icon: Icon(Icons.dark_mode_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('profile.system'),
                          icon: Icon(Icons.brightness_auto_outlined, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('profile.light'),
                          icon: Icon(Icons.light_mode_outlined, size: 18),
                        ),
                      ],
                      selected: {currentMode},
                      onSelectionChanged: (Set<ThemeMode> selected) {
                        ThemeSwitcherProvider.setThemeMode(selected.first);
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _gold.withValues(alpha: 0.2);
                          }
                          return Colors.transparent;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _gold;
                          }
                          return _subtle;
                        }),
                        side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                          if (states.contains(WidgetState.selected)) {
                            return BorderSide(color: _gold.withValues(alpha: 0.5));
                          }
                          return BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1));
                        }),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        padding: WidgetStateProperty.all(
                          EdgeInsets.symmetric(vertical: 1.h),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
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
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isFollowing
                    ? null
                    : const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFF0D060)],
                ),
                boxShadow: isFollowing
                    ? null
                    : [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  service.addfollowuser(postId: widget.userId!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing
                      ? Colors.transparent
                      : Colors.transparent,
                  foregroundColor: _onSurface,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isFollowing
                        ? BorderSide(color: _gold.withValues(alpha: 0.5))
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFollowing ? Icons.check : Icons.person_add,
                      size: 18,
                      color: isFollowing ? _gold : Colors.black,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isFollowing ? 'profile.following_btn'.tr : 'profile.follow'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFollowing ? _gold : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  _gold.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.message_outlined, color: _gold),
              onPressed: () {
                AppTransitions.toChat(ChatPageTikTok(
                    receiverId: userData['googleId'] ?? '',
                    receiverName: userData['name'] ?? 'app.anonymous'.tr,
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
        border: Border(
          bottom: BorderSide(color: _gold.withValues(alpha: 0.2)),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: _gold,
        indicatorWeight: 3,
        labelColor: _gold,
        unselectedLabelColor: _subtle,
        tabs: [
          Tab(icon: Icon(Icons.grid_on_outlined, color: _gold)),
          Tab(icon: Icon(Icons.favorite_border, color: _gold)),
          Tab(icon: Icon(Icons.bookmark_border, color: _gold)),
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
      case 'video': return MediaType.video;
      case 'image': return MediaType.image;
      case 'multiple':
      case 'carousel': return MediaType.multiple;
      default: return MediaType.image;
    }
  }

  Future<String?> _getVideoThumbnail(String videoUrl) async {
    if (_thumbnailCache.containsKey(videoUrl)) {
      return _thumbnailCache[videoUrl];
    }
    if (_thumbnailFutures.containsKey(videoUrl)) {
      return _thumbnailFutures[videoUrl];
    }
    final future = _generateThumbnail(videoUrl);
    _thumbnailFutures[videoUrl] = future;
    final result = await future;
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
      return thumbnailPath;
    } catch (e) {
      return null;
    }
  }

  _buildPostsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('postcarduser')
          .where('userData.googleId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('${'profile.error'.tr}: ${snapshot.error}', style: TextStyle(color: _subtle)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined, size: 48, color: _gold.withValues(alpha: 0.3)),
                  SizedBox(height: 2.h),
                  Text(
                    'profile.no_posts'.tr,
                    style: TextStyle(
                      color: _subtle,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
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
                  final userData = _getSafeMap(postData['userData']);
                  final postContent = _getSafeMap(postData['postData']);
                  final allike = _getSafeList(postContent['allike']);
                  final commentaires = _getSafeList(postContent['commentaire']);
                  final images = _getSafeList(postContent['imagepost']);
                  final videos = _getSafeList(postContent['videopost']);

                  String mediaUrl = '';
                  bool isVideo = videos.isNotEmpty;

                  if (isVideo) {
                    final firstVideo = videos.first;
                    mediaUrl = firstVideo is String ? firstVideo :
                        firstVideo is Map ? (firstVideo['url'] ?? firstVideo.toString()) : firstVideo.toString();
                  } else if (images.isNotEmpty) {
                    final firstImage = images.first;
                    mediaUrl = firstImage is String ? firstImage :
                        firstImage is Map ? (firstImage['url'] ?? firstImage.toString()) : firstImage.toString();
                  } else {
                    mediaUrl = postContent['mediaUrl']?.toString() ?? postContent['videoUrl']?.toString() ?? '';
                  }

                  final mediaTypeStr = postContent['mediaType'] as String?;
                  final mediaType = _getMediaType(mediaTypeStr, images.isNotEmpty, videos.isNotEmpty);

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

                  return _buildGridItem(post, index);
                } catch (e, stackTrace) {
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

  Widget _buildGridItem(PostModel post, index) {
    return GestureDetector(
      onTap: () {
        if(post.mediaType.toString().contains("video")){
          AppTransitions.to(FriendFeedScreen(
            userid: widget.userId!,
            indexed: index,
          ));
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (post.mediaType == MediaType.video)
            _buildVideoThumbnail(post.mediaUrl)
          else
            _buildImageThumbnail(post.mediaUrl),

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
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMediaTypeIcon(post.mediaType),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite, color: _gold, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        _formatNumber(post.likesCount),
                        style: TextStyle(
                          color: _gold,
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
            Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.collections, color: _gold, size: 16),
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
      return _buildPlaceholder(Icons.hide_image, 'profile.image_missing'.tr);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: _placeholderBg,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_gold),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(Icons.broken_image, 'profile.image_unavailable'.tr),
    );
  }

  Widget _buildVideoThumbnail(String videoUrl) {
    if (videoUrl.isEmpty) {
      return _buildPlaceholder(Icons.videocam_off, 'profile.video_missing'.tr);
    }

    return FutureBuilder<String?>(
      future: _getVideoThumbnail(videoUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: _placeholderBg,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_gold),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildVideoPlaceholder(),
          );
        } else {
          return _buildVideoPlaceholder();
        }
      },
    );
  }

  Widget _buildPlaceholder(IconData icon, String message) {
    return Container(
      color: _placeholderBg,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: _gold.withValues(alpha: 0.5), size: 30),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(color: _subtle, fontSize: 8),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      color: _placeholderBg,
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
        return Icon(Icons.play_circle_outline, color: _gold, size: 16);
      case MediaType.multiple:
        return Icon(Icons.photo_library_outlined, color: _gold, size: 16);
      case MediaType.image:
        return const SizedBox(width: 16);
      default:
        return Icon(Icons.help_outline, color: _gold.withValues(alpha: 0.5), size: 16);
    }
  }

  Widget _buildErrorGridItem() {
    return Container(
      color: _placeholderBg,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: _gold, size: 30),
            SizedBox(height: 4),
            Text('profile.error'.tr, style: TextStyle(color: _subtle, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    else if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatDate(DateTime date) {
    final locale = Get.locale?.languageCode ?? 'fr';
    return DateFormat.yMMMM(locale).format(date);
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (i + 1) / 6;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
