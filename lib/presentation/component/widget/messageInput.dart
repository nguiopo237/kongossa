// lib/presentation/component/widget/message_input.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final Function(String) onPickMedia;
  final bool see; // Pour le bouton microphone
  final VoidCallback onToggleMic;
  final VoidCallback onLongPressMic;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSendMessage,
    required this.onPickMedia,
    required this.see,
    required this.onToggleMic,
    required this.onLongPressMic,
  }) : super(key: key);

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  @override
  Widget build(BuildContext context) {
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
                      controller: widget.controller,
                      onTap: () {
                        widget.onToggleMic(); // Pour cacher le microphone
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
                    onPressed: _showMediaSelectionSheet,
                  ),
                  IconButton(
                    icon: Icon(
                      widget.see == true ? Icons.mic_off : Icons.mic,
                      color: Colors.grey[400],
                    ),
                    onPressed: widget.onToggleMic,
                    onLongPress: widget.onLongPressMic,
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
              onPressed: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  widget.onSendMessage(widget.controller.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMediaSelectionSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            const Text(
              'Choisir le type de message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  icon: Icons.audiotrack,
                  label: 'Audio',
                  color: Colors.blue,
                  onTap: () => widget.onPickMedia('audio'),
                ),
                _buildMediaOption(
                  icon: Icons.videocam,
                  label: 'Vidéo',
                  color: Colors.red,
                  onTap: () => widget.onPickMedia('video'),
                ),
                _buildMediaOption(
                  icon: Icons.image,
                  label: 'Image',
                  color: Colors.green,
                  onTap: () => widget.onPickMedia('image'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bouton annuler
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                'Annuler',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
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
}