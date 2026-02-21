import 'dart:math';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config_App/colorsApp.dart';
import '../../../model/datamodel/user_model.dart';
import '../../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../../sevice/upload/upload_post.dart';
import '../image_component/image.dart';

class WidgetComponent {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  PostUpdateService service = PostUpdateService();


  static getmodal({Widget? sectionview, states,isScrollControlled=true}) {

   Get.bottomSheet(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
       isScrollControlled: isScrollControlled,
        backgroundColor: Colors.transparent,
       Material(
         shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.only(
                 topLeft: Radius.circular(20), topRight: Radius.circular(20))),
         child: BackdropFilter(
           filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
           child: StatefulBuilder(
             builder: (context, states) {
               return Container(
                 decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(10)),
                 child: SingleChildScrollView(
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       sectionview!,
                     ],
                   ),
                 ),
               );
             },
           ),
         ),
       ));


  }


  static void showNotification(String message, Color color,context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }


 static getdialog({Widget? sectionview, states, barrierDismissible}) {
   return Get.dialog(
       barrierDismissible:
       barrierDismissible == null ? false : barrierDismissible,
       Dialog(
         child: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               sectionview!,
             ],
           ),
         ),
       ));
 }

  void _toggleLike(item,index,videoId) {

    service.toggleLikecomment(commentId: item['id'],postId: videoId,like: item['likes'] );

  }

 static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
        Iterable.generate(
            length,
                (_) => chars.codeUnitAt(random.nextInt(chars.length))
        )
    );
  }

  Future<void> addComments(videoId) async {
    if (_commentController.text.trim().isEmpty) return;

    print(videoId);

    try {
      DocumentReference postRef = FirebaseFirestore.instance
          .collection('postcarduser')
          .doc(videoId);

      DocumentSnapshot snapshot = await postRef.get();

      if (!snapshot.exists) {
        print("❌ Le document n'existe pas: ${videoId}");
        await postRef.set({
          'postData': {
            'commentaire': [],
            'persolike': [],
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
          '${now.millisecondsSinceEpoch}_${AppUser.info!.uid}_${generateRandomString(6)}';

      final newComment = {
        'id': uniqueId,
        'userId': AppUser.info!.uid,
        'username': AppUser.info!.displayName,
        'avatar': AppUser.info!.photoUrl,
        'comment': _commentController.text,
        'time': now.toIso8601String(),
        'likes': 0,
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

 Widget buildCommentItem(item, int index,videoId) {

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
                     item['username'],
                     style: const TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                     ),
                   ),
                   const SizedBox(width: 8),
                   Text(
                     timeago.format(s.getSafeDateTime(item['time'])
                     ),
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.grey[600],
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 4),
               Text(
                 item['comment'],
                 style: const TextStyle(fontSize: 14),
               ),
             ],
           ),
         ),

         // Bouton like
         GestureDetector(
           onTap: () => _toggleLike(item,index,videoId),
           child: Column(
             children: [
               Icon(
                 item['isLiked'] ? Icons.favorite : Icons.favorite_border,
                 color: item['isLiked'] ? Colors.red : Colors.grey,
                 size: 20,
               ),
               const SizedBox(height: 4),
               Text(
                 item['likes'].toString(),
                 style: TextStyle(
                   fontSize: 12,
                   color: Colors.grey[700],
                 ),
               ),
             ],
           ),
         ),
       ],
     ),
   );
 }

 Widget buildEmptyComments() {
   return Center(
     child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       children: [
         Icon(
           Icons.comment_outlined,
           size: 80,
           color: Colors.grey[400],
         ),
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
           style: TextStyle(
             fontSize: 14,
             color: Colors.grey[500],
           ),
         ),
       ],
     ),
   );
 }

 Widget buildCommentInput({videoId}) {
   return Container(
     padding: const EdgeInsets.all(16),
     decoration: BoxDecoration(
       color: ColorApp.primary,
       border: Border(
         top: BorderSide(color: Colors.grey[200]!),
       ),
     ),
     child: Row(
       children: [
         // Avatar de l'utilisateur connecté
         const CircleAvatar(
           radius: 20,
           backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=7'),
         ),

         const SizedBox(width: 12),

         // Champ de texte
         Expanded(
           child: TextField(
             controller: _commentController,
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
             onSubmitted: (_) => addComments(videoId),
           ),
         ),

         const SizedBox(width: 8),

         // Bouton d'envoi
         GestureDetector(
           onTap: () => addComments(videoId),
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
   );
 }

}