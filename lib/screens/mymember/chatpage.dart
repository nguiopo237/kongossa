import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kongossa/presentation/component/widget/widget_component.dart';
import 'package:photo_view/photo_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import 'package:kongossa/config_App/image.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:voice_message_package/voice_message_package.dart';
import '../../main.dart';
import '../../model/datamodel/message_model.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/video_component/tiktok_player_video.dart';
import '../../presentation/component/widget/audio_message.dart';
import '../../presentation/component/widget/message_bulble.dart';
import '../../presentation/component/widget/record_widget.dart';
import '../../sevice/controlleur/notification/chat_notificationservice/one_signalservice.dart';
import '../../sevice/controlleur/thmbvideo/thum_video.dart';
import '../../sevice/upload/select_image.dart';
import '../../sevice/upload/upload_cloud.dart';

class ChatPageTikTok extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final bool isOnline;
  final String? onesignalId;

  const ChatPageTikTok({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.isOnline = true,
    this.receiverPhoto,
    this.onesignalId,
  }) : super(key: key);

  @override
  State<ChatPageTikTok> createState() => _ChatPageTikTokState();
}

class _ChatPageTikTokState extends State<ChatPageTikTok> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final uuid = const Uuid();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSendingImage = false;
  bool _isScrollToBottomVisible = false;

  List<String> _attachedImages = [];
  List<String> _attachedVideos = [];

  final List<Map<String, dynamic>> _quickReactions = [
    {'emoji': '❤️', 'color': Colors.red},
    {'emoji': '😂', 'color': Colors.yellow},
    {'emoji': '😮', 'color': Colors.orange},
    {'emoji': '😢', 'color': Colors.blue},
    {'emoji': '😡', 'color': Colors.red},
    {'emoji': '👍', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    markMessagesAsRead(widget.receiverId);
    // _scrollController.addListener(_onScroll);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _scrollToBottom();
    // });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final showButton =
          _scrollController.position.pixels <
          _scrollController.position.maxScrollExtent - 200;
      if (showButton != _isScrollToBottomVisible) {
        setState(() {
          _isScrollToBottomVisible = showButton;
        });
      }
    }
  }

  Future<void> markMessagesAsRead(String senderId) async {
    try {
      QuerySnapshot snapshot = await Sms.where(
        "receiveId",
        isEqualTo: AppUser.info!.googleId,
      ).where("isRead", isEqualTo: false).get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print("❌ Erreur: $e");
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  bool see =false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                opacity: 0.1,
                fit: BoxFit.cover,
                image: AssetImage(Consticon.backgroundsms),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey[900]!, Colors.black],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(child: _buildMessagesList()),
              if (_isSendingImage) _buildImageSendingIndicator(),
              _buildMessageInput(),
              Padding(
                padding:  EdgeInsets.only(bottom: 3.h,right: 3.w),
                child: AudioRecordButton(
                  see: see,
                  onSendAudio: (audioPath) async {

                    if( audioPath!=null){
                    setState(() {
                      see =false;
                      _isSendingImage =true;
                    });
                    }
                    try {
                      // Upload vers Cloudinary
                      final url = await UniversalCloudinaryUploader().uploadAnyFile(
                        filePath: audioPath,
                        folder: "kogossa_app/chat/audio",
                        fileName: 'audio_${uuid.v4()}.m4a',
                      );

                      if (url != null) {
                        await _sendMediaMessage(url, 'audio');
                        setState(() {
                          _isSendingImage =false;
                        });
                        print("media send ");

                        // Supprimer le fichier temporaire
                        final file = File(audioPath);
                        if (await file.exists()) {
                          await file.delete();
                        }
                      }
                    } catch (e) {
                      Get.snackbar('Erreur', 'Échec de l\'envoi audio');
                    }
                  },
                  onCancel: () {
                    Get.snackbar('Annulé', 'Enregistrement annulé');
                  },
                ),
              ),

            ],
          ),
          if (_isScrollToBottomVisible)
            Positioned(
              bottom: 100,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  onPressed: _scrollToBottom,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CustomImage(
                  source: widget.receiverPhoto!,
                  type: ImageType.circle,
                ),
              ),
              // CircleAvatar(
              //   radius: 20,
              //   backgroundColor: Colors.grey[900],
              //   backgroundImage: widget.receiverPhoto != null
              //       ? NetworkImage(widget.receiverPhoto!)
              //       : null,
              //   child: widget.receiverPhoto == null
              //       ? Text(
              //     widget.receiverName[0].toUpperCase(),
              //     style: const TextStyle(color: Colors.white),
              //   )
              //       : null,
              // ),
              if (widget.isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          Sms.where(
                "senderId",
                whereIn: [AppUser.info!.googleId, widget.receiverId],
              )
              .where(
                "receiveId",
                whereIn: [widget.receiverId, AppUser.info!.googleId],
              )
              .orderBy("timestamp", descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyChat();
        }

        final messages = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Messagemodel(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            receiveId: data['receiveId'] ?? '',
            messageType: data['messageType'] ?? '',
            content: data['content'] ?? data['text'] ?? '',
            isRead: data['isRead'] ??false,
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: AppBar().preferredSize.height + 20,
            bottom: 20,
            left: 16,
            right: 16,
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == AppUser.info!.googleId;

            if (message.messageType == 'image') {
              return _buildImageMessage(message, isMe);
            }
            if (message.messageType == 'video') {
              return Text("yello");
              return _buildVideoMessage(message, isMe);
            }
            if (message.messageType == 'audio') {
              // return Text("yello");
              return _buildVoiceMessage(message, isMe);
            }
            else {
              return _buildTextMessage(message, isMe);
            }
          },
        );
      },
    );
  }

  Widget _buildImageMessage(Messagemodel message, bool isMe) {
    return InkWell(
      onTap: () {
        WidgetComponent.getmodal(
          sectionview: Container(
            height: Get.height,
            width: Get.width,
          child: Scaffold(
            appBar: AppBar(

            ),
            body:  Stack(
              fit: StackFit.expand,
              children: [
                CustomImage(
                  source: message.content!,
                  type: ImageType.cachedNetwork,
                  height: 40.h,
                  width: 70.w,
                  fit: BoxFit.cover,
                ),
              //  IconButton(onPressed: () => Get.back(), icon: Icon(Icons.close,color: Colors.black,))
              ],
            ),
          ),
          ),
        );
      },
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          constraints: BoxConstraints(maxWidth: 70.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe
                  ? Colors.pink.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomImage(
              source: message.content!,
              type: ImageType.cachedNetwork,
              height: 40.h,
              width: 70.w,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildVideoMessage(Messagemodel message, bool isMe) {
    return InkWell(
      onTap: () {
        _openFullscreenVideo(message.content!);
      },
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          width: 70.w, // ✅ Largeur fixe
          constraints: BoxConstraints(
            maxHeight: 300, // ✅ Hauteur maximale
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe
                  ? Colors.pink.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9, // ✅ RATIO STANDARD POUR VIDÉO
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Thumbvideo(
                    videoUrl: message.content!,
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.2),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Ajoutez cette méthode utilitaire si vous avez la durée
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  Widget _buildTextMessage(Messagemodel message, bool isMe) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        constraints: BoxConstraints(maxWidth: 70.w),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(colors: [Colors.pink, Colors.purple])
              : null,
          color: isMe ? null : Colors.grey[900],
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isMe
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content!,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            FittedBox(
              child: Row(
                children: [
                  Text(
                    // timeago.format(message.timestamp!, locale: 'fr_short'),
                    "${message.timestamp!.hour.toString().padLeft(2, '0')}:${message.timestamp!.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  SizedBox(width: 1.w,),
                  Icon(message.isRead==false?Icons.check_sharp:Icons.checklist,color: message.isRead==true? Colors.blue:Colors.grey,)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 40, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Erreur de connexion',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            '👋 Commencez la conversation',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            'Envoyez votre premier message à\n${widget.receiverName}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickReactions.map((reaction) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: reaction['color'].withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  reaction['emoji'],
                  style: const TextStyle(fontSize: 24),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSendingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[900],
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          ),
          const SizedBox(width: 12),
          Text('Envoi en cours...', style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.grey[900],
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onTap: () {
                        setState(() {
                          see = false;
                        });
                      },
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file, color: Colors.grey[400]),
                    // onPressed: _pickImage,
                    onPressed: () {
                      void _showMediaSelectionSheet() {
                        Get.bottomSheet(
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(top: Radius
                                  .circular(20)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Handle bar (optionnel)
                                Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(height: 16),

                                // Titre
                                Text(
                                  'Choisir le type de message',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 20),

                                // Options
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildMediaOption(
                                      icon: Icons.audiotrack,
                                      label: 'Audio',
                                      color: Colors.blue,

                                      onTap: () {
                                        _pickImage("Audio");
                                      },
                                      // onTap: _sendAudio,
                                    ),
                                    _buildMediaOption(
                                      icon: Icons.videocam,
                                      label: 'Vidéo',
                                      color: Colors.red,
                                      onTap: () {
                                        _pickImage("video");
                                      },
                                      // onTap: _sendVideo,
                                    ),
                                    _buildMediaOption(
                                      icon: Icons.image,
                                      label: 'image',
                                      color: Colors.green,
                                      onTap: () {
                                        // _sendMessage();
                                        _pickImage("image");
                                      }, // Votre méthode existante
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),

                                // Bouton annuler
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: Text(
                                    'Annuler',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

// Widget pour chaque option


// Méthodes à implémenter
                      void _sendAudio() {
                        // Logique pour envoyer un message audio
                        print("🎤 Envoi d'un message audio");
                        // TODO: Implémenter l'enregistrement audio ou la sélection
                      }

                      void _sendVideo() {
                        // Logique pour envoyer une vidéo
                        print("📹 Envoi d'une vidéo");
                        // TODO: Implémenter la sélection vidéo
                      }
                      _showMediaSelectionSheet();
                    },
                  ),
                  IconButton(
                    icon: Icon( see==true?Icons.mic_off:Icons.mic, color: Colors.grey[400]),

                    onPressed: () {

                      if(see==true){
                        setState(() {
                          see = false;
                        });
                      }else{
                        FocusManager.instance.primaryFocus?.unfocus();
                        setState(() {
                          see = true;
                        });
                      }


                    },
                    onLongPress: () {

                    },
                  ),
                ],
              ),
            ),
          ),


          const SizedBox(width: 8),
          Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Colors.pink,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    XFile? pickedFile;
    if(type=="image"){
     pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    }
    if(type=="video"){
      pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        // maxWidth: 1024,
        // maxHeight: 1024,
        // imageQuality: 80,
      );
    }
    if(type=="Audio"){
      pickedFile = await _imagePicker.pickMedia(
        // maxWidth: 1024,
        // maxHeight: 1024,
        // imageQuality: 80,
      );
    }
    if (pickedFile != null) {
      setState(() => _isSendingImage = true);
      final extension = path.extension(pickedFile.path).toLowerCase();
      final mimeType = lookupMimeType(pickedFile.path);

      print('🔍 Détection: extension=$extension, mimeType=$mimeType');
      try {
        final url = await UniversalCloudinaryUploader().uploadAnyFile(
          filePath: pickedFile.path,
          folder: "kogossa_app/chat",
          fileName: '${uuid.v4()}${extension}',
        );
        if (url != null) {
          await _sendMediaMessage(url, type);
        }
      } finally {
        setState(() => _isSendingImage = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await Sms.add({
        "id": uuid.v4(),
        "content": _messageController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": widget.receiverId,
        "isRead": false,
        "messageType": "text",
      });

      OneSignalService.sendNotificationToAll(
        title: AppUser.info!.displayName,
        message: _messageController.text,
        data: {"type": "chat_message"},
      );

      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi')));
    }
  }

  Future<void> _sendMediaMessage(String url, String type) async {
    await Sms.add({
      "id": uuid.v4(),
      "content": url,
      "timestamp": FieldValue.serverTimestamp(),
      "namesenderId": AppUser.info!.displayName,
      "senderId": AppUser.info!.googleId,
      "receiveId": widget.receiverId,
      "isRead": false,
      "messageType": type,
    });
  }




  Widget _buildVoiceMessage(Messagemodel message, bool isMe) {
    return Container(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AudioMessage(
        key: ValueKey('audio_${message.id}'),
        audioUrl: message.content!,
        isMe: isMe,
        messageId: message.id,
        onPlayed: () {
          if (message.isRead == false) {
            _markAudioAsPlayed(message.id!);
          }
        },
        // onStop: () {
        //   print("🛑 Audio arrêté manuellement");
        //   // Optionnel: faire quelque chose quand l'audio s'arrête
        // },
      ),
    );
  }

// Marquer l'audio comme écouté
  Future<void> _markAudioAsPlayed(String messageId) async {
    await Sms.doc(messageId).update({'isRead': true});
  }


  Widget _buildMediaOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Get.back(); // Fermer le bottom sheet
        onTap(); // Appeler la méthode
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenVideo(String videoUrl) {
    Get.to(
          () => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Get.back(),
          ),
        ),
        body: Center(
          child:  TikTokVideoPlayer(

            id: "1",
            start: true,
            videoUrl: videoUrl!,
            username: '',
            description: '',
            music: '',
            profileImage: '',
          ),
        ),
      ),
      transition: Transition.fade,
    );
  }
  }
