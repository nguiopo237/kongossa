import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../main.dart';
import '../../model/datamodel/user_model.dart';
import '../../presentation/component/widget/appbar.dart';
import '../../presentation/component/widget/component_for_post/option_card.dart';
import '../../presentation/component/widget/component_for_post/postcard.dart';
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
      backgroundColor: Colors.grey.shade200,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar professionnelle
          SliverAppBar(
            expandedHeight: 3.h,
            floating: true,
            pinned: true,
            snap: true,
            stretch: true,
            backgroundColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.grey.shade50],
                  ),
                ),
                child: SafeArea(
                  bottom: true,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: const ProfessionalAppBar(),
                  ),
                ),
              ),
            ),
          ),

          // Section des posts
          SliverFillRemaining(
            hasScrollBody: true,
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPostsStream(),
              builder: (context, snapshot) {
                // Gestion des différents états
                return _buildPostsContent(snapshot);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Séparation de la logique de stream pour plus de clarté
  Stream<QuerySnapshot> _getPostsStream() {
    try {
      return Posts.orderBy("timestamp", descending: true).snapshots();
    } catch (e) {
      print('Erreur lors de la création du stream: $e');
      return const Stream.empty();
    }
  }

  // Widget pour le contenu des posts avec gestion d'états complète
  Widget _buildPostsContent(AsyncSnapshot<QuerySnapshot> snapshot) {
    // État de chargement
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    // Gestion des erreurs
    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red.shade300),
            SizedBox(height: 2.h),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Vérifiez votre connexion',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Force le rebuild pour réessayer
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
            Icon(Icons.post_add, size: 48.sp, color: Colors.grey.shade400),
            SizedBox(height: 2.h),
            Text(
              'Aucun post pour le moment',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Soyez le premier à publier !',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
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
      print('Erreur lors de la construction des posts: $e');
      return Center(
        child: Text(
          'Erreur d\'affichage des posts',
          style: TextStyle(color: Colors.red.shade400),
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
    // var data = item.data as Map<String, dynamic>;

    // Accéder au tableau commentaire dans postData

    if (postData != null && postData['commentaire'] != null) {
      comments = List.from(postData['commentaire']);
    }
    if (postData != null && postData['allike'] != null) {
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
        name: userData['name']?.toString() ?? 'Utilisateur',
        bio: timeago.format(dateTime, locale: 'fr'),
        image: userData['photoUrl']?.toString(),
        postImage: postImage,
        postVideo: postVideo,
        likes: alllike.length,
        alllike: alllike,
        comments: comments.length,
        content: postData['posttitle']?.toString() ?? '',
        onProfileTap: () {
          Get.to(PremiumProfileScreen (
            userId: userData['googleId']?.toString() ,
            avatarUrl: userData['photoUrl']?.toString(),
            displayName: userData['name']?.toString() ?? 'Utilisateur',
            username: userData['name']?.toString() ?? 'Utilisateur',
            mail: userData['email']?.toString(),
            bio: "${userData['bio']?.toString() ??"Créateur de contenu | Digital Creator ✨\nCollaborations"}  📩 ${userData['email']}",

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
                      Posts.doc(item.id).delete().then(
                        (value) {
                          Get.back();
                          WidgetComponent.showNotification(
                            "Post supprimer avec succes",
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
      print('Erreur de conversion timestamp: $e');
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
      print('Erreur de chargement image: $e');
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
      print('Erreur de chargement vidéo: $e');
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
      print('Erreur de conversion likes: $e');
    }
    return 0;
  }
}
