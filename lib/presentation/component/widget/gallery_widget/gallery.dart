// screens/full_screen_image_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../model/datamodel/gallery_model.dart';
import '../../../../sevice/gallery_service/GalleryService.dart';


class FullScreenImageScreen extends StatefulWidget {
  final List<ImageItem> images;
  final int initialIndex;
  final bool allowSave;
  final bool allowShare;

  const FullScreenImageScreen({
    Key? key,
    required this.images,
    required this.initialIndex,
    this.allowSave = true,
    this.allowShare = true,
  }) : super(key: key);

  @override
  _FullScreenImageScreenState createState() => _FullScreenImageScreenState();
}

class _FullScreenImageScreenState extends State<FullScreenImageScreen> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrentImage() async {
    // final image = widget.images[currentIndex];
    // bool success;
    //
    // if (image.localPath != null) {
    //   success = await GalleryService.saveImageFromFile(File(image.localPath!));
    // } else {
    //   success = await GalleryService.saveImageFromUrl(image.url);
    // }
    //
    // if (success && mounted) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Image sauvegardée avec succès'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    // }
  }

  Future<void> _shareCurrentImage() async {
    final image = widget.images[currentIndex];

    if (image.localPath != null) {
      await Share.shareXFiles([XFile(image.localPath!)]);
    } else {
      // final file = await GalleryService.downloadImage(image.url);
      // if (file != null) {
      //   await Share.shareXFiles([XFile(file.path)]);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${currentIndex + 1}/${widget.images.length}'),
        actions: [
          if (widget.allowSave)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCurrentImage,
            ),
          if (widget.allowShare)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareCurrentImage,
            ),
        ],
      ),
      body: PhotoViewGallery.builder(
        pageController: pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        builder: (context, index) {
          final image = widget.images[index];
          return PhotoViewGalleryPageOptions(
            imageProvider: image.localPath != null
                ? FileImage(File(image.localPath!))
                : NetworkImage(image.url) as ImageProvider,
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(tag: image.id),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
      ),
    );
  }
}