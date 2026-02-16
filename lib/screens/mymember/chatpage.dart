// lib/presentation/pages/chat_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kongossa/model/datamodel/user_model.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';
import '../../model/datamodel/message_model.dart';
import '../../presentation/component/widget/message_bulble.dart';
import '../../sevice/controlleur/splashcontrolleur/splashscreen_controlleur.dart';

class ChatPage extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final bool isOnline;

  const ChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
     this.isOnline = true,
    this.receiverPhoto,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  var uuid = const Uuid();

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar avec statut en ligne
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isOnline ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.receiverPhoto != null
                      ? NetworkImage(widget.receiverPhoto!)
                      : null,
                  child: widget.receiverPhoto == null
                      ? Text(
                    widget.receiverName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              ),
              if (widget.isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
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
        IconButton(
          icon: const Icon(Icons.phone_outlined),
          onPressed: () {},
          tooltip: 'Appel audio',
        ),
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () {},
          tooltip: 'Appel vidéo',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            // Gérer les actions du menu
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text('Rechercher'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Effacer la conversation'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Bloquer'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildPremiumAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Sms
                  .where("senderId", whereIn: ['${AppUser.info!.googleId}', '${widget.receiverId}'])
                  .where("receiveId", whereIn: ['${AppUser.info!.googleId}', '${widget.receiverId}'])
                  .orderBy("timestamp", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur : ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Pas de messages'),
                        Text('Commencez la conversation !'),
                      ],
                    ),
                  );
                } else {
                  // ✅ CORRECTION : Convertir correctement les documents en objets Messagemodel
                  final messages = snapshot.data!.docs.map((doc) {
                    // Récupérer les données du document
                    final data = doc.data() as Map<String, dynamic>;

                    // Créer un objet Messagemodel à partir des données
                    return Messagemodel(
                      id: doc.id,

                      senderId: data['senderId'] ?? '',
                      receiveId: data['receiveId'] ?? '',
                      content: data['content'] ?? data['text'] ?? '',
                      timestamp: data['timestamp'] != null
                          ? (data['timestamp'] as Timestamp).toDate()
                          : DateTime.now(),
                      // Ajoutez ici tous les champs nécessaires à votre Messagemodel
                    );
                  }).toList();

                  final messageGroups = MessageService.groupMessagesByDate(messages);

                  return Container(
                    child: ListView.builder(
                      reverse: false,
                      padding: const EdgeInsets.all(16),
                      itemCount: messageGroups.length,
                      itemBuilder: (context, groupIndex) {
                        final group = messageGroups[groupIndex];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  group.title,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Text(data),
                            ...group.messages.map((message) {
                              return MessageBubble(
                                message: message,
                                isMe: message.senderId == AppUser.info!.googleId,
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  );
                }
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final String uniqueId = uuid.v4();
    if (_messageController.text.trim().isEmpty) return;

    Sms.add({
      "id": uniqueId,
      "content": _messageController.text,
      "timestamp": FieldValue.serverTimestamp(),
      "namesenderId": "${AppUser.info!.displayName}",
      "senderId": "${AppUser.info!.googleId}",
      "receiveId": "${widget.receiverId}",
      // "senderId": "${widget.receiverId}",
      // "receiveId": "${AppUser.info!.googleId}",
    });

    _messageController.clear();
  }
}
