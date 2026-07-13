import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/shared/widgets/widgets.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../config_App/colorsApp.dart';
import '../../model/datamodel/user_model.dart';
import '../../shared/widgets/appbar.dart';
import '../../shared/widgets/component_for_post/option_card.dart';
import '../../shared/widgets/component_for_post/postcard.dart';
import '../../utils/transitions.dart';
import '../profil_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Cache pour éviter les reconstructions inutiles
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: PremiumParticleBackground(
        config: ParticleThemes.gold,
        showGradient: true,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // AppBar fixe en haut
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                ),
                child: SafeArea(
                  bottom: false,
                  child: const ProfessionalAppBar(),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 0.5.h)),
            // Section des posts
            SliverFillRemaining(
              hasScrollBody: true,
              child: StreamBuilder<QuerySnapshot>(
                stream: _getPostsStream(),
                builder: (context, snapshot) {
                  return _buildPostsContent(snapshot);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Séparation de la logique de stream pour plus de clarté
  Stream<QuerySnapshot> _getPostsStream() {
    try {
      return FirestoreCollectionsService.posts.orderBy("timestamp", descending: true).snapshots();
    } catch (e) {
      debugPrint('Error creating stream: $e');
      return const Stream.empty();
    }
  }

  // Widget pour le contenu des posts avec gestion d'états complète
  Widget _buildPostsContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    // État de chargement
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ColorApp.premiumGold,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'home.loading'.tr,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    // Gestion des erreurs
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: ColorApp.premiumGold.withValues(alpha: 0.6)),
            SizedBox(height: 2.h),
            Text(
              'home.error_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'home.error_subtitle'.tr,
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 2.h),              ElevatedButton(
              onPressed: () {
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorApp.premiumGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: ColorApp.premiumGold.withValues(alpha: 0.3),
              ),
              child: Text('app.retry'.tr),
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
            Icon(Icons.post_add, size: 48.sp, color: ColorApp.premiumGold.withValues(alpha: 0.4)),
            SizedBox(height: 2.h),
            Text(
              'home.empty_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'home.empty_subtitle'.tr,
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      );
    }

    // Affichage des posts avec gestion sécurisée des données
    try {
      final documents = snapshot.data!.docs;


      return ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 0.5.h),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final item = documents[index];
          // debugPrint(documents[0]["postData"].toString());
          return _buildPostCard(item);
        },
      );
    } catch (e) {
      debugPrint('Error building posts: $e');
      return Center(                      child: Text(
                        'home.display_error'.tr,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }
  }

  // Widget de carte post avec validation des données
  Widget _buildPostCard(QueryDocumentSnapshot item) {
    List<dynamic> comments = [];
    List<dynamic> alllike = [];
    // Extraction sécurisée des données avec valeurs par défaut
    final userData = _getSafeMap(item['userData']);
    final postData = _getSafeMap(item['postData']);

    // Gestion sécurisée du timestamp
    DateTime dateTime = _getSafeDateTime(item['timestamp']);

    // Gestion sécurisée des images
    String? postImage = _getSafeImageUrl(postData['imagepost']);
    String? postVideo = _getSafeVideoUrl(postData['videopost']);

    // Accéder au tableau commentaire dans postData

    if (postData['commentaire'] != null) {
      comments = List.from(postData['commentaire']);
    }
    if (postData['allike'] != null) {
      alllike = List.from(postData['allike']);
    }

    // if (data['postData'] != null &&
    //     data['postData']['commentaire'] != null) {
    //   comments = List.from(data['postData']['commentaire']);
    // }
    return Padding(
      padding: EdgeInsets.symmetric(
        // horizontal: 2.w,
        vertical: 0.h,
      ),

      child: PremiumPostcard(
        id: item.id,
        name: userData['name']?.toString() ?? 'app.user'.tr,
        bio: timeago.format(dateTime, locale: 'fr'),
        image: userData['photoUrl']?.toString(),
        postImage: postImage,
        postVideo: postVideo,
        likes: alllike.length,
        alllike: alllike,
        comments: comments.length,
        content: postData['posttitle']?.toString() ?? '',
        onProfileTap: () {
          AppTransitions.toProfile(PremiumProfileScreen (
            userId: userData['googleId']?.toString() ,
            avatarUrl: userData['photoUrl']?.toString(),
            displayName: userData['name']?.toString() ?? 'Utilisateur',
            username: userData['name']?.toString() ?? 'Utilisateur',
            mail: userData['email']?.toString(),
            bio: "${userData['bio']?.toString() ??'tiktok.bio'.tr}  📩 ${userData['email']}",

          ));
        },
        onMore: () {
          WidgetComponent.getmodal(
            isScrollControlled: true,
            sectionview: SizedBox(
              height: Get.height / 1.26,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PostOptionsMenu(
                    postId: item.id,
                    onDelete: () {
                      FirestoreCollectionsService.posts.doc(item.id).delete().then(
                        (value) {
                          Get.back();
                          WidgetComponent.showNotification(
                            'post.deleted_success'.tr,
                            Colors.green,
                            context,
                          );
                        },
                      );
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
    );
  }

  // Méthodes utilitaires pour la gestion sécurisée des données
  Map<String, dynamic> _getSafeMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    return {};
  }

  DateTime _getSafeDateTime(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
    } catch (e) {
      debugPrint('Timestamp conversion error: $e');
    }
    return DateTime.now();
  }

  String? _getSafeImageUrl(dynamic imageData) {
    try {
      if (imageData != null) {
        if (imageData is List && imageData.isNotEmpty) {
          return imageData[0]?.toString();
        } else if (imageData is String) {
          return imageData;
        }
      }
    } catch (e) {
      debugPrint('Image loading error: $e');
    }
    return null;
  }

  String? _getSafeVideoUrl(dynamic videoData) {
    try {
      if (videoData != null) {
        if (videoData is List && videoData.isNotEmpty) {
          return videoData[0]?.toString();
        } else if (videoData is String) {
          return videoData;
        }
      }
    } catch (e) {
      debugPrint('Video loading error: $e');
    }
    return null;
  }

  int _getSafeLikes(dynamic likes) {
    try {
      if (likes is int) {
        return likes;
      } else if (likes is String) {
        return int.tryParse(likes) ?? 0;
      }
    } catch (e) {
      debugPrint('Likes conversion error: $e');
    }
    return 0;
  }
}
