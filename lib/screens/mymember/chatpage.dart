// lib/presentation/pages/chat_page_tiktok.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kongossa/presentation/component/style/custum_text.dart';
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
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';
import '../../sevice/controlleur/thmbvideo/thum_video.dart';
import '../../sevice/upload/select_image.dart';
import '../../sevice/upload/upload_cloud.dart';

// ============================================================================
// 🎯 WIDGET PRINCIPAL - État minimal + callbacks pré-initialisés
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
  // ✅ Controllers - final pour éviter recreation
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();

  // ✅ État MINIMAL - seulement ce qui nécessite un rebuild UI
  bool _isSendingMedia = false;
  bool _showScrollButton = false;
  bool _showAudioRecord = false;
  bool _isreply = false;

  // ✅ Callbacks pré-initialisés dans initState (évite recreation à chaque build)
  late final VoidCallback _onMicPress;
  late final VoidCallback _onAttachPress;
  late final VoidCallback _onSendPress;
  late final VoidCallback _onTextFieldTap;

  // ✅ Constantes pour éviter recreation
  static const _quickReactions = [
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
    _initializeCallbacks();
    markMessagesAsRead(widget.receiverId);
    // Optionnel: _scrollController.addListener(_onScroll);
  }

  // ✅ Initialisation des callbacks - exécutée UNE SEULE FOIS
  void _initializeCallbacks() {
    _onMicPress = () {
      if (_showAudioRecord) {
        setState(() => _showAudioRecord = false);
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        setState(() => _showAudioRecord = true);
      }
    };

    _onAttachPress = () => _showMediaSelectionSheet();

    _onSendPress = _sendMessage;

    _onTextFieldTap = () {
      if (_showAudioRecord) {
        setState(() => _showAudioRecord = false);
      }
    };
  }

  // ✅ Scroll optimisé - setState uniquement si changement réel
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final showButton =
        _scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200;
    if (showButton != _showScrollButton) {
      setState(() => _showScrollButton = showButton);
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

  // ============================================================================
  // 🎨 BUILD - Structure légère, widgets extraits en méthodes privées
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              Expanded(child: _buildMessagesList()),
              if (_isSendingMedia) const _SendingIndicator(),
              _buildMessageInput(),
            ],
          ),
          if (_showScrollButton) _buildScrollButton(),
        ],
      ),
    );
  }

  // ============================================================================
  // 🧩 WIDGETS EXTRAITS (méthodes privées - même fichier)
  // ============================================================================

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

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    title: _AppBarTitle(
      name: widget.receiverName,
      photo: widget.receiverPhoto,
      isOnline: widget.isOnline,
    ),
  );

  Widget _buildMessagesList() => StreamBuilder<QuerySnapshot>(
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
      if (snapshot.hasError) return const _ChatErrorState();
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return _EmptyChat(receiverName: widget.receiverName);
      }

      // ✅ Conversion en liste - hors du builder pour éviter recreation
      final messages = _parseMessages(snapshot.data!.docs);
      final doc = snapshot.data!.docs;

      // ✅ Scroll uniquement après premier build
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      return ListView.builder(
        controller: _scrollController,
        // onScroll: _onScroll, // Décommenter si besoin du scroll button
        padding: EdgeInsets.only(
          top: AppBar().preferredSize.height + 20,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        itemCount: messages.length,
        cacheExtent: 1000,
        // ✅ Pré-rendu pour performance
        itemBuilder: (context, index) {
          final message = messages[index];
          final isMe = message.senderId == AppUser.info!.googleId;
          final id = snapshot.data!.docs[index].id;

          // ✅ ValueKey stable pour préserver l'état des widgets
          return Dismissible(
            direction: DismissDirection.horizontal,

            onDismissed: (direction) {
              // 👈 4. VÉRIFIER LA DIRECTION POUR L'ACTION
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
              s.reply.value = [
                {"idoc": id, "message": message.content, "type": "text"},
              ];

              print("_reply.first");
              print(s.reply.first["message"]);
              print("_reply.first");
              return false;
            },

            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.replay_5, color: Colors.white),
            ),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            key: ValueKey('msg_${message.id}'),

            child: _MessageItem(
              key: ValueKey('msg_${message.id}'),
              message: message,
              isMe: isMe,
              onAudioPlayed: message.isRead == false
                  ? () => _markAudioAsPlayed(message.id!)
                  : null,
            ),
          );
        },
      );
    },
  );

  // ✅ Parsing des messages - extrait du build pour éviter recreation
  List<Messagemodel> _parseMessages(List<QueryDocumentSnapshot> docs) {
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Messagemodel(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        receiveId: data['receiveId'] ?? '',
        messageType: data['messageType'] ?? '',
        content: data['content'] ?? data['text'] ?? '',
        isRead: data['isRead'] ?? false,
        itemreply: List.from(data['itemreply'] ?? []),
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  Widget _buildMessageInput() => _MessageInput(
    receiverId: widget.receiverId,
    controller: _messageController,
    focusNode: _focusNode,
    showAudioRecord: _showAudioRecord,
    onMicPress: _onMicPress,
    onAttachPress: _onAttachPress,
    onSend: _onSendPress,
    onTextFieldTap: _onTextFieldTap,
  );

  Widget _buildScrollButton() => Positioned(
    bottom: 100,
    right: 16,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.9),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        onPressed: _scrollToBottom,
      ),
    ),
  );

  // ============================================================================
  // 📡 LOGIQUE MÉTIER - Extraite du build
  // ============================================================================

  Future<void> markMessagesAsRead(String senderId) async {
    try {
      final snapshot = await Sms.where(
        "receiveId",
        isEqualTo: AppUser.info!.googleId,
      ).where("isRead", isEqualTo: false).get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint("❌ Erreur markAsRead: $e");
    }
  }

  Future<void> _handleAudioSend(String? audioPath) async {
    if (audioPath == null) return;

    // ✅ setState minimal - uniquement les flags nécessaires
    setState(() {
      _showAudioRecord = false;
      _isSendingMedia = true;
    });

    try {
      final url = await UniversalCloudinaryUploader().uploadAnyFile(
        filePath: audioPath,
        folder: "kogossa_app/chat/audio",
        fileName: 'audio_${_uuid.v4()}.m4a',
      );

      if (url != null && mounted) {
        await _sendMediaMessage(url, 'audio');
        final file = File(audioPath);
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      if (mounted) Get.snackbar('Erreur', 'Échec de l\'envoi audio');
    } finally {
      if (mounted) setState(() => _isSendingMedia = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await Sms.add({
        "id": _uuid.v4(),
        "content": text,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": widget.receiverId,
        "isRead": false,
        "messageType": "text",
        if (s.reply.isNotEmpty) "itemreply": s.reply,
      });
      s.reply.clear();
      OneSignalService.sendNotificationToAll(
        title: AppUser.info!.displayName,
        message: text,
        data: {"type": "chat_message"},
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi')),
        );
      }
    }
  }

  Future<void> _sendMediaMessage(String url, String type) async {
    await Sms.add({
      "id": _uuid.v4(),
      "content": url,
      "timestamp": FieldValue.serverTimestamp(),
      "namesenderId": AppUser.info!.displayName,
      "senderId": AppUser.info!.googleId,
      "receiveId": widget.receiverId,
      "isRead": false,
      "messageType": type,
    });
  }

  Future<void> _markAudioAsPlayed(String messageId) async {
    await Sms.doc(messageId).update({'isRead': true});
  }

  Future<void> _pickImage(String type) async {
    XFile? pickedFile;
    switch (type) {
      case "image":
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 80,
        );
        break;
      case "video":
        pickedFile = await _imagePicker.pickVideo(source: ImageSource.gallery);
        break;
      case "Audio":
        pickedFile = await _imagePicker.pickMedia();
        break;
    }

    if (pickedFile != null && mounted) {
      setState(() => _isSendingMedia = true);
      final extension = path.extension(pickedFile.path).toLowerCase();

      try {
        final url = await UniversalCloudinaryUploader().uploadAnyFile(
          filePath: pickedFile.path,
          folder: "kogossa_app/chat",
          fileName: '${_uuid.v4()}${extension}',
        );
        if (url != null && mounted) {
          await _sendMediaMessage(url, type);
        }
      } finally {
        if (mounted) setState(() => _isSendingMedia = false);
      }
    }
  }

  void _showMediaSelectionSheet() {
    Get.bottomSheet(
      _MediaSelectionSheet(onSelect: _pickImage),
      isScrollControlled: true,
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
          child: TikTokVideoPlayer(
            id: "",
            start: true,
            videoUrl: videoUrl,
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

// ============================================================================
// 🧱 WIDGETS SECONDAIRES (const + Stateless pour éviter rebuilds)
// ============================================================================

// ────────────────────────────────────────────────────────────────────────────
// AppBar Title - extrait + const
// ────────────────────────────────────────────────────────────────────────────
class _AppBarTitle extends StatelessWidget {
  final String name;
  final String? photo;
  final bool isOnline;

  const _AppBarTitle({
    required this.name,
    required this.photo,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CustomImage(source: photo!, type: ImageType.circle),
            ),
            if (isOnline)
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
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  fontSize: 12,
                  color: isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Message Input - extrait + callbacks en params (pas de recreation)
// ────────────────────────────────────────────────────────────────────────────
class _MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showAudioRecord;
  final String receiverId;
  final VoidCallback onMicPress;
  final VoidCallback onAttachPress;
  final VoidCallback onSend;

  final VoidCallback onTextFieldTap;

  const _MessageInput({
    required this.controller,
    required this.focusNode,
    required this.receiverId,
    required this.showAudioRecord,
    required this.onMicPress,
    required this.onAttachPress,
    required this.onSend,

    required this.onTextFieldTap,
  });

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  bool see = false;

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
            if (s.reply!.isNotEmpty)
              Container(
                color: Colors.black.withOpacity(0.3),
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => _TextMessage(
                        message: Messagemodel(
                          // id: "1",
                          id: s.reply!.first["idoc"],
                          content: s.reply!.first["message"],
                          isRead: false,
                          messageType: "text",
                          receiveId: widget.receiverId,
                          timestamp: DateTime.now(),
                        ),
                        isMe: false,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // widget.reply!.clear();
                        s.reply.clear();
                      },
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _MessageTextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    onTap: widget.onTextFieldTap,
                  ),
                ),
                const SizedBox(width: 8),
                _Sendingfile(receiverId: widget.receiverId),
                _SendButtonmedia(
                  see: see,
                  onPressed: () {
                    if (see == true) {
                      setState(() {
                        see = false;
                      });
                    } else {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() {
                        see = true;
                      });
                    }
                  },
                ),
                _SendButton(onPressed: widget.onSend),
              ],
            ),
            SendVoice(see: see, receiverId: widget.receiverId),
          ],
        ),
      ),
    );
  }
}

class _MessageTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTap;

  const _MessageTextField({
    required this.controller,
    required this.focusNode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTap: onTap,
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

class _SendButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SendButton({required this.onPressed});

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
        onPressed: onPressed,
      ),
    );
  }
}

class _SendButtonmedia extends StatefulWidget {
  final VoidCallback onPressed;
  bool see;

  _SendButtonmedia({required this.onPressed, this.see = false});

  @override
  State<_SendButtonmedia> createState() => _SendButtonmediaState();
}

class _SendButtonmediaState extends State<_SendButtonmedia> {
  // bool see =false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        widget.see == true ? Icons.mic_off : Icons.mic,
        color: Colors.grey[400],
      ),

      onPressed: widget.onPressed,
      onLongPress: () {},
    );
  }
}

class SendVoice extends StatefulWidget {
  bool see;
  final String receiverId;

  SendVoice({super.key, required this.see, required this.receiverId});

  @override
  State<SendVoice> createState() => _SendVoiceState();
}

class _SendVoiceState extends State<SendVoice> {
  final uuid = const Uuid();

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

  @override
  Widget build(BuildContext context) {
    return AudioRecordButton(
      see: widget.see,
      onSendAudio: (audioPath) async {
        if (audioPath != null) {
          setState(() {
            widget.see = false;
            // _isSendingImage =true;
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
            // setState(() {
            //   _isSendingImage =false;
            // });
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
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Message Item - Dispatcheur avec ValueKey pour préserver l'état
// ────────────────────────────────────────────────────────────────────────────
class _MessageItem extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;
  final VoidCallback? onAudioPlayed;

  const _MessageItem({
    Key? key,
    required this.message,
    required this.isMe,
    this.onAudioPlayed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (message.messageType) {
      case 'image':
        return _ImageMessage(message: message, isMe: isMe);
      case 'video':
        return _VideoMessage(message: message, isMe: isMe);
      case 'audio':
        return AudioMessage(
          key: ValueKey('audio_${message.id}'),
          // ✅ Clé stable pour AudioMessage
          audioUrl: message.content!,
          isMe: isMe,
          messageId: message.id,
          onPlayed: onAudioPlayed,
        );
      default:
        return _TextMessage(message: message, isMe: isMe);
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Text Message - const widget
// ────────────────────────────────────────────────────────────────────────────
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.itemreply?.isNotEmpty ?? false)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: isMe ? Colors.pink : Colors.purple,
                      width: 3,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(8.0),
                child: CustomText(
                  message.itemreply!.first["message"],
                  type: TextType.headlineSmall,
                  style: TextStyle(color: Colors.white),
                ),
                // child: Text(
                //   message.itemreply!.first["message"],
                //   style: TextStyle(
                //     fontSize: 16.sp,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ),
            SizedBox(height: 1.h,),
            Text(
              message.content!,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            FittedBox(
              child: Row(
                children: [
                  Text(
                    "${message.timestamp!.hour.toString().padLeft(2, '0')}:${message.timestamp!.minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead == false
                        ? Icons.check_sharp
                        : Icons.checklist,
                    color: message.isRead == true ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Image Message - const widget + onTap extrait
// ────────────────────────────────────────────────────────────────────────────
class _ImageMessage extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;

  const _ImageMessage({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openImagePreview(message.content!),
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

  void _openImagePreview(String url) {
    WidgetComponent.getmodal(
      sectionview: Container(
        height: Get.height,
        width: Get.width,
        child: Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: Stack(
            fit: StackFit.expand,
            children: [
              CustomImage(
                source: url,
                type: ImageType.cachedNetwork,
                height: 40.h,
                width: 70.w,
                fit: BoxFit.cover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Video Message - const widget
// ────────────────────────────────────────────────────────────────────────────
class _VideoMessage extends StatelessWidget {
  final Messagemodel message;
  final bool isMe;

  const _VideoMessage({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openVideoPreview(message.content!),
      child: Container(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
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
            child: InkWell(
              onTap: () {
                _openFullscreenVideo(message.content!);
              },
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Thumbvideo(videoUrl: message.content!),
                    Container(color: Colors.black.withOpacity(0.2)),
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
      ),
    );
  }

  void _openVideoPreview(String url) {
    // À implémenter selon votre logique
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
          child: TikTokVideoPlayer(
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

// ────────────────────────────────────────────────────────────────────────────
// Media Selection Sheet - extrait + const options
// ────────────────────────────────────────────────────────────────────────────
class _MediaSelectionSheet extends StatelessWidget {
  final Function(String) onSelect;

  const _MediaSelectionSheet({required this.onSelect});

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
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
                  onSelect("Audio");
                },
              ),
              _MediaOption(
                icon: Icons.videocam,
                label: 'Vidéo',
                color: Colors.red,
                onTap: () {
                  Get.back();
                  onSelect("video");
                },
              ),
              _MediaOption(
                icon: Icons.image,
                label: 'Image',
                color: Colors.green,
                onTap: () {
                  Get.back();
                  onSelect("image");
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

// ────────────────────────────────────────────────────────────────────────────
// Sending Indicator - const widget
// ────────────────────────────────────────────────────────────────────────────
class _SendingIndicator extends StatelessWidget {
  const _SendingIndicator();

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

class _Sendingfile extends StatefulWidget {
  final String receiverId;

  const _Sendingfile({required this.receiverId});

  @override
  State<_Sendingfile> createState() => _SendingfileState();
}

class _SendingfileState extends State<_Sendingfile> {
  bool see = false;
  final uuid = const Uuid();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSendingImage = false;
  final TextEditingController _messageController = TextEditingController();

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
    print("widget.receiverId");
    print(widget.receiverId);
    print("widget.receiverId");
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

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.attach_file, color: Colors.grey[400]),
      // onPressed: _pickImage,
      onPressed: () {
        void _showMediaSelectionSheet() {
          Get.bottomSheet(
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }

  Future<void> _pickImage(String type) async {
    XFile? pickedFile;
    if (type == "image") {
      pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    }
    if (type == "video") {
      pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        // maxWidth: 1024,
        // maxHeight: 1024,
        // imageQuality: 80,
      );
    }
    if (type == "Audio") {
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
}

// ────────────────────────────────────────────────────────────────────────────
// Empty Chat & Error State - const widgets
// ────────────────────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  final String receiverName;

  const _EmptyChat({required this.receiverName});

  static const _quickReactions = [
    {'emoji': '❤️', 'color': Colors.red},
    {'emoji': '😂', 'color': Colors.yellow},
    {'emoji': '😮', 'color': Colors.orange},
    {'emoji': '😢', 'color': Colors.blue},
    {'emoji': '😡', 'color': Colors.red},
    {'emoji': '👍', 'color': Colors.green},
  ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _quickReactions.map((reaction) {
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
          ),
        ],
      ),
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
            onPressed: () {}, // À gérer selon votre logique
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
