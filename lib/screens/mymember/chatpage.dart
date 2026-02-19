// lib/presentation/pages/chat_page_tiktok.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kongossa/config_App/image.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';
import '../../model/datamodel/message_model.dart';
import '../../presentation/component/widget/message_bulble.dart';
import '../../sevice/controlleur/notification/fcm_service.dart';

class ChatPageTikTok extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final bool isOnline;

  const ChatPageTikTok({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.isOnline = true,
    this.receiverPhoto,
  }) : super(key: key);

  @override
  State<ChatPageTikTok> createState() => _ChatPageTikTokState();
}

class _ChatPageTikTokState extends State<ChatPageTikTok> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final uuid = const Uuid();

  late AnimationController _sendButtonAnimation;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    markMessagesAsRead(widget.receiverId);
    _sendButtonAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _messageController.addListener(_onTextChanged);

    // Scroll initial après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onTextChanged() {
    final hasText = _messageController.text.isNotEmpty;
    if (hasText != _isTyping) {
      // setState(() => _isTyping = hasText);
      if (hasText) {
        // _sendButtonAnimation.forward();
      } else {
        // _sendButtonAnimation.reverse();
      }
    }
  }



  Future<void> markMessagesAsRead(String senderId) async {
    try {
      print("🔄 Marquage des messages de $senderId comme lus...");

      // Récupérer tous les messages non lus de cet expéditeur
      QuerySnapshot snapshot = await Sms
          .where("senderId", whereIn: [AppUser.info!.googleId, widget.receiverId])
          .where("receiveId", whereIn: [widget.receiverId, AppUser.info!.googleId])
          .where("isRead", isEqualTo: false)
          .orderBy("timestamp", descending: false)

          .get();

      if (snapshot.docs.isEmpty) {
        print("✅ Aucun message non lu de $senderId");
        return;
      }

      print("📨 ${snapshot.docs.length} message(s) non lu(s) trouvé(s)");

      // Mettre à jour chaque document
      for (var doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
        print("  ✓ Message ${doc.id} marqué comme lu");
      }

      print("✅ Tous les messages de $senderId ont été marqués comme lus");

    } catch (e) {
      print("❌ Erreur lors du marquage des messages: $e");
    }
  }



  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonAnimation.dispose();
    super.dispose();
  }

  // Une seule fonction de scroll
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildTikTokAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage(Consticon.backgroundsms),
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: _buildMessagesList(),
            ),
          ),

          _buildTikTokMessageInput(),
          SizedBox(height: 2.h,)
        ],
      ),
    );
  }

  // AppBar simplifiée
  PreferredSizeWidget _buildTikTokAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[900],
                backgroundImage: widget.receiverPhoto != null
                    ? NetworkImage(widget.receiverPhoto!)
                    : null,
                child: widget.receiverPhoto == null
                    ? Text(
                  widget.receiverName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
                    : null,
              ),
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
      actions: [
        _buildActionButton(Icons.phone_outlined),
        _buildActionButton(Icons.videocam_outlined),
        _buildActionButton(Icons.more_horiz, onPressed: _showTikTokMenu),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed ?? () {},
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Liste des messages optimisée
  Widget _buildMessagesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: Sms
          .where("senderId", whereIn: [AppUser.info!.googleId, widget.receiverId])
          .where("receiveId", whereIn: [widget.receiverId, AppUser.info!.googleId])
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.pink));
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[400]),
                const SizedBox(height: 8),
                Text('Erreur de chargement', style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          );
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
            content: data['content'] ?? data['text'] ?? '',
            timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        }).toList();

        // Scroll automatique quand de nouveaux messages arrivent
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        final messageGroups = MessageService.groupMessagesByDate(messages);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messageGroups.length,
          itemBuilder: (context, groupIndex) {
            final group = messageGroups[groupIndex];

            return Column(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[900]!.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      group.title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...group.messages.map((message) => MessageBubble(
                  message: message,
                  isMe: message.senderId == AppUser.info!.googleId,
                )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(color: Colors.grey[900], shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            '👋 Commencez la conversation',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Envoyez votre premier message à ${widget.receiverName}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Input message optimisé
  Widget _buildTikTokMessageInput() {
    return Container(
      padding:  EdgeInsets.symmetric(vertical: 2.h),
      color: Colors.grey[900],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildIconButton(Icons.add, _showAttachmentMenu),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(

                      controller: _messageController,
                      // focusNode: _focusNode,
                      style: const TextStyle(color: Colors.black),
                      maxLines: 5,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  _buildIconButton(Icons.emoji_emotions_outlined, null),
                  _buildIconButton(Icons.attach_file, null),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: _isTyping
                      ? const LinearGradient(colors: [Colors.pink, Colors.purple])
                      : null,
                  color: _isTyping ? null : Colors.grey[850],
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isTyping ? Icons.send : Icons.mic,
                    color: _isTyping ? Colors.white : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: _isTyping ? _sendMessage : _startVoiceRecording,
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onPressed) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.grey[400], size: 20),
        onPressed: onPressed ?? () {},
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _showTikTokMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...['Rechercher', 'Effacer', 'Bloquer'].map((label) => ListTile(
              leading: Icon(
                label == 'Rechercher' ? Icons.search :
                label == 'Effacer' ? Icons.delete_outline : Icons.block,
                color: label == 'Bloquer' ? Colors.red : Colors.white,
              ),
              title: Text(
                label,
                style: TextStyle(color: label == 'Bloquer' ? Colors.red : Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...[
              {'icon': Icons.photo, 'label': 'Photo', 'color': Colors.blue},
              {'icon': Icons.videocam, 'label': 'Vidéo', 'color': Colors.green},
              {'icon': Icons.mic, 'label': 'Audio', 'color': Colors.purple},
              {'icon': Icons.description, 'label': 'Document', 'color': Colors.orange},
            ].map((item) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              title: Text(item['label'] as String, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _startVoiceRecording() {}

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
      });

      await notif.add({
        "id": uuid.v4(),
        "content": _messageController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": widget.receiverId,
        "isRead": false,
        "type": "message",
        "photo": widget.receiverPhoto,
      });

      _messageController.clear();
      // _focusNode.unfocus();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'envoi'), backgroundColor: Colors.red),
      );
    }
  }
}