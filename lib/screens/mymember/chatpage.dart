// lib/presentation/pages/chat_page_tiktok.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:kongossa/presentation/component/style/custum_text.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import '../../config_App/image.dart';
import '../../model/datamodel/user_model.dart';
import '../../main.dart';
import '../../model/datamodel/message_model.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/video_component/tiktok_player_video.dart';
import '../../presentation/component/widget/audio_message.dart';
import '../../presentation/component/widget/record_widget.dart';
import '../../sevice/call_API/zegocloud/interface_call.dart';
import '../../sevice/call_API/zegocloud/zecloud_fonction.dart';
import '../../sevice/controlleur/chat_controlleur/chat_controlleur.dart';
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../sevice/controlleur/thmbvideo/thum_video.dart';

// ============================================================================
// 🎯 WIDGET PRINCIPAL - PURE VIEW (Stateless)
// ============================================================================
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }


@override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Controller initialization with GetX
    final ChatController controller = Get.put(
      ChatController(
        receiverId: widget.receiverId,
        receiverName: widget.receiverName,
        receiverPhoto: widget.receiverPhoto,
        isOnline: widget.isOnline,
        onesignalId: widget.onesignalId,
      ),
      // permanent: true,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _AppBar(controller: controller,receiverId: widget.receiverId,),
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              Expanded(child: _MessagesList(controller: controller)),
              controller.isSendingMedia
                  ? const SendingIndicator()
                  : const SizedBox.shrink(),
              _MessageInput(controller: controller),
            ],
          ),
          controller.showScrollButton
              ? _ScrollButton(controller: controller)
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildBackground() => Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        opacity: 0.1,
        fit: BoxFit.cover,
        image: const AssetImage(Consticon.backgroundsms),
      ),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.grey[900]!, Colors.black],
      ),
    ),
  );
}

// ============================================================================
// 🧱 WIDGETS COMPOSANTS
// ============================================================================

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatController controller;
  final String receiverId;

  const _AppBar({required this.controller, required this.receiverId});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
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
                  source: controller.receiverPhoto!,
                  type: ImageType.circle,
                ),
              ),
              if (controller.isOnline)
                const Positioned(bottom: 2, right: 2, child: OnlineIndicator()),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.receiverName,
                  style:  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp
                  ),
                ),
                Text(
                  controller.isOnline ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    fontSize: 12,
                    color: controller.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(3.0),
            iconSize: 20,
            backgroundColor: Colors.grey.withOpacity(0.5),),
          onPressed: () {

            Call.startCall(receiverId, false);
          },
          child: Icon(Icons.call, color: Colors.green),
        ),
        SizedBox(width: 4.w,),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(3.0),
            iconSize: 20,
            backgroundColor: Colors.grey.withOpacity(0.5),),
          onPressed: () {
            Call.startCall(receiverId, true);
          },
          child: Icon(Icons.video_call, color: Colors.green),
        ),
        SizedBox(width: 4.w,),
      ],
    );
  }
}

class OnlineIndicator extends StatelessWidget {
  const OnlineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final ChatController controller;

  const _MessagesList({required this.controller});

  Stream<QuerySnapshot> getstream() {
    final item =
        Sms.where(
              "senderId",
              whereIn: [AppUser.info!.googleId, controller.receiverId],
            )
            .where(
              "receiveId",
              whereIn: [controller.receiverId, AppUser.info!.googleId],
            )
            .orderBy("timestamp", descending: false)
            .snapshots();

    item.listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final messageData = change.doc.data() as Map<String, dynamic>;
          final senderId = messageData['senderId'] as String?;
          final isFromMe = senderId == AppUser.info?.googleId;

          // ✅ Scroll automatique UNIQUEMENT si :
          // 1. Le message vient de l'utilisateur OU l'utilisateur est déjà en bas
          // 2. L'utilisateur n'a pas scrollé manuellement vers le haut
          if (controller.isAtBottom || isFromMe) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.scrollToBottom();
            });
          } else {
            // ✅ Afficher le bouton "scroll to bottom" si nouveau message en arrière-plan
            controller.showScrollButtons.value = true;
          }
        }
      }
    });

    return item;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: getstream(),
      builder: (context, snapshot) {
        // ✅ Gestion intelligente du chargement
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pink),
          );
        }

        if (snapshot.hasError) {
          return const _ChatErrorState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptyChat(receiverName: controller.receiverName);
        }

        final messages = controller.parseMessages(snapshot.data!.docs);

        // Dans _MessagesList.build(), remplacez le ListView.builder par :
        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            // ✅ Masquer le bouton scroll si l'utilisateur revient en bas
            if (controller.isAtBottom) {
              controller.showScrollButtons.value = false;
            }
            return true;
          },
          child: ListView.builder(
            key: const PageStorageKey('chat_list'),
            controller: controller.scrollController,
            padding: EdgeInsets.only(
              top: AppBar().preferredSize.height + 20,
              bottom: 20,
              left: 16,
              right: 16,
            ),
            itemCount: messages.length,
            cacheExtent: 500,
            reverse: false,
            // Gardez false pour un chat normal (messages anciens en haut)
            itemBuilder: (context, index) {
              final message = messages[index];
              final isMe = message.senderId == AppUser.info!.googleId;
              final id = snapshot.data!.docs[index].id;
              return Column(
                children: [
                  // Text((message.itemreply?.length??0).toString(),style: TextStyle(color: Colors.orange),),
                  Dismissible(
                    key: ValueKey('msg_${message.id}_${message.timestamp}'),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        // Glissé vers la DROITE

                        // Sms.doc(id).update({'isRead': true});
                        Sms.doc(id).delete();
                        print("Action gauche: supprimer");
                      } else if (direction == DismissDirection.endToStart) {
                        // Glissé vers la GAUCHE - LE SECOND BACKGROUND EST UTILISÉ ICI

                        // Sms.doc(id).delete();
                        print("Action droite: archiver/marquer comme lu");
                      }
                      // deleteMessage(id);
                    },
                    confirmDismiss: (direction) async {
                      controller.reply.value = [
                        {
                          "idoc": id,
                          "message": message.content,
                          "type": message.messageType,
                          "isMe": isMe,
                        },
                      ];

                      print("_reply.first");
                      print(controller.reply.first["message"]);
                      print("_reply.first");
                      return false;
                    },
                    direction: DismissDirection.horizontal,
                    child: _MessageItem(
                      key: ValueKey('msg_${message.id}_${message.timestamp}'),
                      message: message,
                      isMe: isMe,
                      controller: controller,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;
  final ChatController controller;

  const _MessageItem({
    Key? key,
    required this.message,
    required this.isMe,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (message.messageType) {
      case 'image':
        return Column(
          children: [
            _ImageMessage(
              message: message,
              isMe: isMe,
              onTap: () => controller.openImagePreview(message.content!),
            ),
          ],
        );
      case 'video':
        return _VideoMessage(
          message: message,
          isMe: isMe,
          onTap: () => controller.openFullscreenVideo(message.content!),
          // controller: controller,
        );
      case 'audio':
        return AudioMessage(
          key: ValueKey('audio_${message.id}'),
          audioUrl: message.content ?? "",
          isMe: isMe,
          messageId: message.id ?? "0",
          onPlayed: message.isRead == false
              ? () => controller.markAudioAsPlayed(message.id!)
              : null,
          // controller: controller,
        );
      default:
        return _TextMessage(message: message, isMe: isMe);
    }
  }
}

class _TextMessage extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;

  const _TextMessage({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
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
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // if(message.itemreply!=null&&message.itemreply!.isNotEmpty)
            //   _MessageItem(
            //     message: Messagemodel(content: message.itemreply!.first["message"]),
            //     isMe: isMe,
            //     controller: ChatController(receiverId: '', receiverName: ''),
            //   ),
            // if (message.itemreply != null && message.itemreply!.isNotEmpty)
            //   Text(
            //     message.itemreply!.first["message"],
            //     style: const TextStyle(color: Colors.white, fontSize: 15),
            //   ),
            if (message.itemreply != null && message.itemreply!.isNotEmpty)
              _MessageItem(
                message: Messagemodel(
                  content: message.itemreply!.first["message"],
                  messageType: message.itemreply!.first["type"],
                ),
                isMe: message.itemreply!.first["isMe"] ?? false,
                controller: ChatController(receiverId: '', receiverName: ''),

                //message.itemreply!.first["message"],
              ),

            //  AudioMessage(audioUrl: message.itemreply!.first["message"], isMe: message.itemreply!.first["isMe"],),
            if (message.itemreply != null && message.itemreply!.isNotEmpty)
              Divider(
                height: 1,
                // ✅ Réduit la hauteur (espace vertical)
                thickness: 0.5,
                // ✅ Réduit l'épaisseur du trait
                indent: 20,
                // Espace à gauche
                endIndent: 20,
                // Espace à droite
                color: Colors.grey.withOpacity(0.3),
              ),
            Text(
              message.content ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            _MessageStatus(message: message),
          ],
        ),
      ),
    );
  }
}

class _MessageStatus extends StatelessWidget {
  final Messagemodel message;

  const _MessageStatus({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${message.timestamp?.hour.toString().padLeft(2, '0')}:${message.timestamp?.minute.toString().padLeft(2, '0')}",
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Icon(
          message.isRead == false ? Icons.check : Icons.done_all,
          size: 16,
          color: message.isRead == true ? Colors.blue : Colors.grey,
        ),
      ],
    );
  }
}

class _ImageMessage extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;
  final VoidCallback onTap;

  const _ImageMessage({
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (message.itemreply != null && message.itemreply!.isNotEmpty)
              _MessageItem(
                message: Messagemodel(
                  content: message.itemreply!.first["message"],
                  messageType: message.itemreply!.first["type"],
                ),
                isMe: message.itemreply!.first["isMe"],
                controller: ChatController(receiverId: '', receiverName: ''),

                //message.itemreply!.first["message"],
              ),
            Container(
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
                  source: message.content ?? "",
                  type: ImageType.cachedNetwork,
                  height: 40.h,
                  width: 70.w,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoMessage extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;
  final VoidCallback onTap;

  const _VideoMessage({
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            if (message.itemreply != null && message.itemreply!.isNotEmpty)
              _MessageItem(
                message: Messagemodel(
                  content: message.itemreply!.first["message"],
                  messageType: message.itemreply!.first["type"],
                ),
                isMe: message.itemreply!.first["isMe"],
                controller: ChatController(receiverId: '', receiverName: ''),

                //message.itemreply!.first["message"],
              ),
            Container(
              width: 70.w,
              constraints: const BoxConstraints(maxHeight: 300),
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
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Thumbvideo(videoUrl: message.content!),
                      Container(color: Colors.black.withOpacity(0.2)),
                      const _PlayButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final ChatController controller;

  const _MessageInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        color: Colors.grey[900],
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          8 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            if (controller.hasReply) _ReplyPreview(controller: controller),
            Row(
              children: [
                Expanded(child: _MessageTextField(controller: controller)),
                const SizedBox(width: 8),
                _AttachButton(controller: controller),
                _MicToggleButton(controller: controller),
                _SendButton(controller: controller),
              ],
            ),
            if (controller.showAudioRecord)
              _AudioRecorder(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final ChatController controller;

  const _ReplyPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CustomText(controller.reply.first["isMe"]==true?"Moi":controller.
                  //   receiverName, style: TextStyle(color: Colors.white),),
                  _MessageItem(
                    message: Messagemodel(
                      timestamp: DateTime.now(),
                      messageType: controller.reply.first["type"],
                      isRead: false,
                      content: controller.reply.first["message"],
                      id: controller.reply.first["idoc"],
                    ),

                    isMe: controller.reply.first["isMe"] == true ? true : false,
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: controller.clearReply,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  final ChatController controller;

  const _MessageTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller.messageController,
        focusNode: controller.focusNode,
        onTap: controller.hideAudioRecord,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          hintText: 'Message...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _MicToggleButton extends StatelessWidget {
  final ChatController controller;

  const _MicToggleButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IconButton(
        icon: Icon(
          controller.showAudioRecord ? Icons.mic_off : Icons.mic,
          color: Colors.grey[400],
        ),
        onPressed: controller.toggleAudioRecord,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final ChatController controller;

  const _SendButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        color: Colors.pink,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.send, color: Colors.white, size: 20),
        onPressed: controller.sendTextMessage,
      ),
    );
  }
}

class _AttachButton extends StatelessWidget {
  final ChatController controller;

  const _AttachButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.attach_file, color: Colors.grey[400]),
      onPressed: () => _showMediaSelectionSheet(controller),
    );
  }

  void _showMediaSelectionSheet(ChatController controller) {
    Get.bottomSheet(
      _MediaSelectionSheet(controller: controller),
      isScrollControlled: true,
    );
  }
}

class _AudioRecorder extends StatelessWidget {
  final ChatController controller;

  const _AudioRecorder({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AudioRecordButton(
      see: true,
      onSendAudio: controller.handleAudioSend,
      onCancel: () => Get.snackbar('Annulé', 'Enregistrement annulé'),
    );
  }
}

class _MediaSelectionSheet extends StatelessWidget {
  final ChatController controller;

  const _MediaSelectionSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const SizedBox(height: 16),
          const Text(
            'Choisir le type de message',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _MediaOption(
                icon: Icons.audiotrack,
                label: 'Audio',
                color: Colors.blue,
                onTap: () {
                  Get.back();
                  controller.pickAndSendMedia("Audio");
                },
              ),
              _MediaOption(
                icon: Icons.videocam,
                label: 'Vidéo',
                color: Colors.red,
                onTap: () {
                  Get.back();
                  controller.pickAndSendMedia("video");
                },
              ),
              _MediaOption(
                icon: Icons.image,
                label: 'Image',
                color: Colors.green,
                onTap: () {
                  Get.back();
                  controller.pickAndSendMedia("image");
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _MediaOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class SendingIndicator extends StatelessWidget {
  const SendingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[900],
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          ),
          SizedBox(width: 12),
          Text('Envoi en cours...', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ScrollButton extends StatelessWidget {
  final ChatController controller;

  const _ScrollButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.pink.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          onPressed: controller.scrollToBottom,
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  final String receiverName;

  const _EmptyChat({required this.receiverName});

  @override
  Widget build(BuildContext context) {
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
            'Envoyez votre premier message à\n$receiverName',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 30),
          _QuickReactions(),
        ],
      ),
    );
  }
}

class _QuickReactions extends StatelessWidget {
  final List<Map<String, dynamic>> reactions = const [
    {'emoji': '❤️', 'color': Colors.red},
    {'emoji': '😂', 'color': Colors.yellow},
    {'emoji': '😮', 'color': Colors.orange},
    {'emoji': '😢', 'color': Colors.blue},
    {'emoji': '😡', 'color': Colors.red},
    {'emoji': '👍', 'color': Colors.green},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: reactions.map((reaction) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (reaction['color'] as Color).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            reaction['emoji'] as String,
            style: const TextStyle(fontSize: 24),
          ),
        );
      }).toList(),
    );
  }
}

class _ChatErrorState extends StatelessWidget {
  const _ChatErrorState();

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {}, // Retry logic here
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
