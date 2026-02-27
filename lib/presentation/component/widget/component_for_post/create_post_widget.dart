import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../screens/mymember/chatpage.dart';
import '../../../../sevice/controlleur/publish_element/PublishControlleur.dart';

import '../../image_component/image.dart';
import '../cloudinaryvideoplayer.dart';

// Widget pour l'en-tête utilisateur premium
class PremiumUserHeader extends GetWidget<CreatePostPremiumController> {
  const PremiumUserHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingUser.value) {
        return const _LoadingUserHeader();
      }

      if (controller.userData.value != null) {
        return _UserHeaderContent(
          userData: controller.userData.value!,
          isPublic: controller.isPublic.value,
          selectedAudience: controller.selectedAudience.value,
          hasContent: controller.hasContent.value,
          onToggleAudience: controller.toggleAudience,
        );
      }

      return const _DefaultUserHeader();
    });
  }
}

// Widget pour le champ de texte premium
class PremiumTextField extends GetWidget<CreatePostPremiumController> {
  const PremiumTextField({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller.postController,
        focusNode: controller.postFocusNode,
        maxLines: null,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: "Partagez votre inspiration...",
          hintStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 18,
            fontStyle: FontStyle.italic,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          suffixIcon: Padding(
            padding: const EdgeInsets.all(20),
            child: Icon(
              Icons.edit_note_rounded,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget pour la galerie média premium
class PremiumMediaGallery extends GetWidget<CreatePostPremiumController> {
  const PremiumMediaGallery({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.attachedImages.isEmpty &&
          controller.attachedVideos.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.collections,
                    color: Colors.black87,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Média (${controller.attachedImages.length + controller.attachedVideos.length})',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (controller.attachedImages.isNotEmpty)
              _ImageGrid(images: controller.attachedImages),
            if (controller.attachedVideos.isNotEmpty)
              _VideoPreview(videos: controller.attachedVideos),
          ],
        ),
      );
    });
  }
}

// Widget pour les options premium
class PremiumOptions extends GetWidget<CreatePostPremiumController> {
  const PremiumOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Enrichir votre publication',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildOption(
                icon: Icons.photo_camera,
                label: 'Photo',
                onTap: () => controller.addImage(),
                isActive: controller.attachedImages.isNotEmpty,
                activeColor: Colors.green,
              ),
              _buildOption(
                icon: Icons.videocam,
                label: 'Vidéo',
                onTap: () => controller.addVideo(context),
                isActive: controller.attachedVideos.isNotEmpty,
                activeColor: Colors.purple,
              ),
              _buildOption(
                icon: Icons.location_pin,
                label: 'Lieu',
                onTap: controller.toggleLocation,
                isActive: controller.hasLocation.value,
                activeColor: Colors.red,
              ),
              _buildOption(
                icon: Icons.emoji_emotions,
                label: 'Humeur',
                onTap: controller.toggleFeeling,
                isActive: controller.isFeeling.value,
                activeColor: Colors.amber,
              ),
              _buildOption(
                icon: Icons.poll,
                label: 'Sondage',
                onTap: controller.togglePoll,
                isActive: controller.isPoll.value,
                activeColor: Colors.blue,
              ),
              _buildOption(
                icon: Icons.tag,
                label: 'Personnes',
                onTap: () => controller.tagPeople.toggle(),
                isActive: controller.tagPeople.value,
                activeColor: Colors.pink,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
            colors: [activeColor.withOpacity(0.2), activeColor.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? activeColor.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isActive
              ? [
            BoxShadow(
              color: activeColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive
                      ? [activeColor, activeColor.withOpacity(0.8)]
                      : [Colors.grey[700]!, Colors.grey[800]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour le sentiment sélectionné
class SelectedFeeling extends GetWidget<CreatePostPremiumController> {
  const SelectedFeeling({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isFeeling.value || controller.selectedFeeling.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber[200]!),
        ),
        child: Row(
          children: [
            const Text('😊', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous vous sentez ${controller.selectedFeeling.value.toLowerCase()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Partagez votre humeur avec vos amis',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: () => controller.selectedFeeling.value = '',
            ),
          ],
        ),
      );
    });
  }
}

// Widget pour les paramètres avancés
class AdvancedSettings extends StatelessWidget {
  const AdvancedSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: Colors.black, size: 20),
              SizedBox(width: 10),
              Text(
                'Paramètres avancés',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSettingRow(
            icon: Icons.schedule,
            title: 'Programmer la publication',
            value: 'Maintenant',
            onTap: () {},
          ),
          _buildSettingRow(
            icon: Icons.comment,
            title: 'Autoriser les commentaires',
            value: 'Tout le monde',
            onTap: () {},
          ),
          _buildSettingRow(
            icon: Icons.share,
            title: 'Autoriser les partages',
            value: 'Tout le monde',
            onTap: () {},
          ),
          _buildSettingRow(
            icon: Icons.visibility,
            title: 'Statistiques de vue',
            value: 'Activées',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue[700], size: 18),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}

// Widget pour la barre d'action
class ActionBar extends GetWidget<CreatePostPremiumController> {
  const ActionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 0.5.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              controller.load==true
              ? const SendingIndicator()
                : const SizedBox.shrink(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.hasContent.value
                          ? () => controller.publishPost(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: controller.hasContent.value ? 5 : 0,
                      ),
                      child: const Text(
                        'Publier',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

// Widgets privés
class _LoadingUserHeader extends StatelessWidget {
  const _LoadingUserHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey,
        ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              height: 20,
              child: LinearProgressIndicator(),
            ),
            SizedBox(height: 5),
            SizedBox(
              width: 80,
              height: 15,
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ],
    );
  }
}

class _DefaultUserHeader extends StatelessWidget {
  const _DefaultUserHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, color: Colors.white),
        ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisateur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Text(
              'Non connecté',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UserHeaderContent extends StatelessWidget {
  final DocumentSnapshot userData;
  final bool isPublic;
  final String selectedAudience;
  final bool hasContent;
  final VoidCallback onToggleAudience;

  const _UserHeaderContent({
    required this.userData,
    required this.isPublic,
    required this.selectedAudience,
    required this.hasContent,
    required this.onToggleAudience,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: CustomImage(
                type: ImageType.circle,
                source: userData["photoUrl"],
              ),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData["name"] ?? 'Utilisateur',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: onToggleAudience,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPublic ? Icons.public : Icons.lock,
                        size: 14,
                        color: isPublic ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        selectedAudience,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasContent)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.5),
              ),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final RxList<String> images;

  const _ImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: images.length > 1 ? 2 : 1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                CustomImage(
                  source: images[index],
                  type: ImageType.file,
                  width: 200,
                  height: 150,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => images.removeAt(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  final RxList<String> videos;

  const _VideoPreview({required this.videos});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: Stack(
        children: [
          Videoplayerpost(files: File(videos.first.toString())),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.videocam, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}