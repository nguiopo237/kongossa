// lib/presentation/pages/chat_page_tiktok.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:kongossa/config_App/image.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:uuid/uuid.dart';

import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../model/datamodel/message_model.dart';
import '../../shared/widgets/message_bulble.dart';

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
      debugPrint("🔄 Marking messages from $senderId as read...");

      // Récupérer tous les messages non lus
      QuerySnapshot snapshot = await FirestoreCollectionsService.sms
          .where("senderId", whereIn: [AppUser.info!.googleId, widget.receiverId])
          .where("receiveId", whereIn: [widget.receiverId, AppUser.info!.googleId])
          .where("isRead", isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint("✅ No unread messages from $senderId");
        return;
      }

      debugPrint("📨 ${snapshot.docs.length} unread message(s) found");

      // Utiliser un batch pour mettre à jour tous les documents en une seule opération
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      debugPrint("✅ All messages from $senderId marked as read (batch)");

    } catch (e) {
      debugPrint("❌ Error marking messages as read: $e");
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
                    Colors.black.withValues(alpha: 0.6),
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
                  widget.isOnline ? 'chat.online'.tr : 'chat.offline'.tr,
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
        color:  Theme.of(context).colorScheme.surfaceContainerHighest,
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
      stream: FirestoreCollectionsService.sms
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
                Text('chat.error'.tr, style: TextStyle( color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                      color: Theme.of(context).colorScheme.surfaceContainerHighest!.withValues(alpha: 0.8),
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
            decoration: BoxDecoration( color: Theme.of(context).colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'chat.start_conversation'.tr,
            style: TextStyle( color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'chat.first_message'.tr + '${widget.receiverName}',
            style: TextStyle( color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Input message optimisé
  Widget _buildTikTokMessageInput() {
    return Container(
      padding:  EdgeInsets.symmetric(vertical: 2.h),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildIconButton(Icons.add, _showAttachmentMenu),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        hintText: 'chat.hint'.tr,
                        hintStyle: TextStyle( color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        icon: Icon(icon,  color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
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
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...[{'key': 'chat.menu.search', 'icon': Icons.search, 'isDanger': false}, {'key': 'chat.menu.clear', 'icon': Icons.delete_outline, 'isDanger': false}, {'key': 'chat.menu.block', 'icon': Icons.block, 'isDanger': true}].map((item) => ListTile(
              leading: Icon(
                item['icon'] as IconData,
                color: (item['isDanger'] as bool) ? Colors.red : Colors.white,
              ),
              title: Text(
                (item['key'] as String).tr,
                style: TextStyle(color: (item['isDanger'] as bool) ? Colors.red : Colors.white),
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
                  color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ...[{'key': 'chat.attachment.photo', 'icon': Icons.photo, 'color': Colors.blue}, {'key': 'chat.attachment.video', 'icon': Icons.videocam, 'color': Colors.green}, {'key': 'chat.attachment.audio', 'icon': Icons.mic, 'color': Colors.purple}, {'key': 'chat.attachment.document', 'icon': Icons.description, 'color': Colors.orange}].map((item) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: item['color'] as Color),
              ),
              title: Text((item['key'] as String).tr, style: const TextStyle(color: Colors.white)),
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
      await FirestoreCollectionsService.sms.add({
        "id": uuid.v4(),
        "content": _messageController.text,
        "timestamp": FieldValue.serverTimestamp(),
        "namesenderId": AppUser.info!.displayName,
        "senderId": AppUser.info!.googleId,
        "receiveId": widget.receiverId,
        "isRead": false,
      });

      await FirestoreCollectionsService.notif.add({
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
        SnackBar(content: Text('chat.send_error'.tr), backgroundColor: Colors.red),
      );
    }
  }
}