// lib/presentation/component/comment_modal.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/config_App/colorsApp.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../main.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../../sevice/upload/upload_post.dart';
import '../image_component/image.dart';

import 'package:uuid/uuid.dart';

import '../widget/widget_component.dart';

class CommentModal extends StatefulWidget {
  final String videoId;
  final String videoTitle;
  final int initialCommentCount;

  const CommentModal({
    Key? key,
    required this.videoId,
    required this.videoTitle,
    this.initialCommentCount = 0,
  }) : super(key: key);

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final List<Map<String, dynamic>> _comments = [];
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  PostUpdateService service = PostUpdateService();

  @override
  void dispose() {
    _animationController.dispose();
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  bool _isLiked = false;

  void _toggleLike(item, index) {
    // setState(() {
    print(index);
    _isLiked = !item['isLiked'];
    // item['likes'] +=item['isLiked'] ? 1 : -1;
    // });
    service.toggleLikecomment(
      commentId: item['id'],
      postId: widget.videoId,
      // isLiked: _isLiked,
      like: item['likes'],
    );
  }

  List<dynamic> comments = [];

  sendcomment() async {
    final comment = {
      'username': AppUser.info!.displayName,
      'avatar': AppUser.info!.photoUrl,
      'comment': 'Quelle est la musique de fond ? 🎵',
      'time': DateTime.now(),
      'likes': 0,
      'isLiked': false,
    };

    final postdata = {
      "postData.commentaire": FieldValue.arrayUnion([comment]),
    };

    final postDocument = {
      // "userData": userData,
      "postData": postdata,
      // "timestamp": FieldValue.serverTimestamp(),
    };

    DocumentReference docRef = await Posts.add(postDocument);
    print("✅ Post créé avec ID: ${docRef.id} ${docRef.path}");
  }

  var uuid = const Uuid();

  Future<void> addComment1() async {
    if (_commentController.text.trim().isEmpty) return;

    print(widget.videoId);

    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('postcarduser')
          .doc(widget.videoId);

      // Vérifier si le document existe
      DocumentSnapshot snapshot = await postRef.get();

      if (!snapshot.exists) {
        print("❌ Le document n'existe pas: ${widget.videoId}");
        await postRef.set({
          'postData': {
            'commentaire': [],
            'allpersonlike': [],
            'createdAt': FieldValue.serverTimestamp(),
            'likes': 0,
            'posttitle': '',
            'status': 'published',
          },
          'userData': {
            'email': AppUser.info?.email,
            'name': AppUser.info?.displayName,
            'photoUrl': AppUser.info?.photoUrl,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("✅ Document créé avec succès");
      }

      // ✅ GÉNÉRATION D'UN ID UNIQUE AVEC UUID
      final String uniqueId = uuid
          .v4(); // Ex: "123e4567-e89b-12d3-a456-426614174000"

      final newComment = {
        'id': uniqueId, // ID unique garanti
        'userId': AppUser.info!.uid,
        'username': AppUser.info!.displayName,
        'avatar': AppUser.info!.photoUrl,
        'comment': _commentController.text,
        'time': DateTime.now().toIso8601String(),
        'likes': 0,
        'isLiked': false,
        'createdAt': FieldValue.serverTimestamp(), // Optionnel
      };

      await postRef.update({
        'postData.commentaire': FieldValue.arrayUnion([newComment]),
      });

      print("✅ Commentaire ajouté avec ID: $uniqueId");
      _commentController.clear();
    } catch (e) {
      print('❌ Erreur: $e');
      Get.snackbar('Erreur', 'Impossible d\'ajouter le commentaire');
    }
  }

  Future<void> addComments() async {
    if (_commentController.text.trim().isEmpty) return;

    print(widget.videoId);

    FocusManager.instance.primaryFocus?.unfocus();
    Get.back();
    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('postcarduser')
          .doc(widget.videoId);

      DocumentSnapshot snapshot = await postRef.get();

      if (!snapshot.exists) {
        print("❌ Le document n'existe pas: ${widget.videoId}");
        await postRef.set({
          'postData': {
            'commentaire': [],
            'allpersonnelike': [],
            'createdAt': FieldValue.serverTimestamp(),
            'likes': 0,
            'posttitle': '',
            'status': 'published',
          },
          'userData': {
            'email': AppUser.info?.email,
            'name': AppUser.info?.displayName,
            'photoUrl': AppUser.info?.photoUrl,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("✅ Document créé avec succès");
      }

      // ✅ GÉNÉRATION D'UN ID UNIQUE COMPOSITE
      final now = DateTime.now();
      final String uniqueId =
          '${now.millisecondsSinceEpoch}_${AppUser.info!.uid}_${_generateRandomString(6)}';

      final newComment = {
        'id': uniqueId,
        'userId': AppUser.info!.uid,
        'username': AppUser.info!.displayName,
        'avatar': AppUser.info!.photoUrl,
        'comment': _commentController.text,
        'time': now.toIso8601String(),
        'likes': 0,
        // 'allpersonnelike': [],
        'isLiked': false,
      };

      await postRef.update({
        'postData.commentaire': FieldValue.arrayUnion([newComment]),
      });

      print("✅ Commentaire ajouté avec ID: $uniqueId");
      _commentController.clear();
    } catch (e) {
      print('❌ Erreur: $e');
      Get.snackbar('Erreur', 'Impossible d\'ajouter le commentaire');
    }
  }

  // Fonction pour générer une chaîne aléatoire
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  bool view = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30)
      ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 0.2.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ColorApp.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // En-tête
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('postcarduser')
                    .doc(widget.videoId)
                    .snapshots(),
                builder: (context, snapshot) {
                  // Gestion des états de chargement
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Gestion des erreurs
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Vérifier si le document existe
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return _buildEmptyComments();
                  }

                  // Récupérer les données
                  var data = snapshot.data!.data() as Map<String, dynamic>;

                  // Accéder au tableau commentaire dans postData

                  if (data['postData'] != null &&
                      data['postData']['commentaire'] != null) {
                    comments = List.from(data['postData']['commentaire']);
                  }

                  // Trier par date (du plus récent au plus ancien)
                  comments.sort((a, b) {
                    DateTime dateA = DateTime.parse(a['time'] ?? '1970-01-01');
                    DateTime dateB = DateTime.parse(b['time'] ?? '1970-01-01');
                    return dateB.compareTo(dateA); // Plus récent d'abord
                  });

                  if (comments.isEmpty) {
                    return _buildEmptyComments();
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0.2.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Commentaires (${comments.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _closeModal,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final item = comments[index];
                            return _buildCommentItem(item, index);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 2.h),
        child: _buildCommentInput(),
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

  Widget _buildCommentItem(item, int index) {
    // Récupérer la liste des personnes qui ont liké pour CE commentaire
    List<dynamic> commentLikes = [];
    if (item['allpersonnelike'] != null && item['allpersonnelike'] is List) {
      commentLikes = List.from(item['allpersonnelike']);
    }

    // Récupérer l'ID de l'utilisateur connecté
    String? currentUserId = AppUser.info?.googleId;

    // Vérifier si l'utilisateur a liké CE commentaire précis
    bool isLikedByCurrentUser = false;

    if (currentUserId != null) {
      isLikedByCurrentUser = commentLikes.any((likeUser) {
        // Vérifier toutes les possibilités d'ID
        return likeUser['userId'] == currentUserId;
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CustomImage(
            source: item['avatar'],
            type: ImageType.circle,
            height: 4.h,
          ),

          const SizedBox(width: 12),

          // Contenu du commentaire
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item['username'] ?? 'Utilisateur inconnu',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(_getSafeDateTime(item['time'])),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item['comment'] ?? "",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Bouton like
          GestureDetector(
            onTap: () => _toggleLike(item, index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLikedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                  color: isLikedByCurrentUser ? Colors.red : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  commentLikes.length.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isLikedByCurrentUser ? Colors.red : Colors.grey[700],
                    fontWeight: isLikedByCurrentUser
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.comment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun commentaire',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à commenter !',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    // FocusManager.instance.primaryFocus?.unfocus();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorApp.BlackColor,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Avatar de l'utilisateur connecté
          s.buildUserProfile(),

          const SizedBox(width: 12),

          // Champ de texte
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _focusNode,
              readOnly: true,

              onTap: () {
                Future.microtask(() {
                  WidgetComponent.getmodal(
                    isScrollControlled: true,
                    sectionview: Container(
                      decoration: BoxDecoration(
                        color: ColorApp.BlackColor,
                        border: Border(
                          top: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Row(
                          children: [
                            s.buildUserProfile(),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                autofocus: true,
                                // focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Ajouter un commentaire...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: null,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => addComments(),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            GestureDetector(
                              onTap: addComments,
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _commentController.text.isNotEmpty
                                      ? Colors.blue
                                      : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.send,
                                  color: _commentController.text.isNotEmpty
                                      ? Colors.white
                                      : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
              decoration: InputDecoration(
                hintText: 'Ajouter un commentairess...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => addComments(),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton d'envoi
        ],
      ),
    );
  }

}


