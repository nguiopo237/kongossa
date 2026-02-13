// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:foap/helper/imports/common_import.dart';
// import 'package:get/get.dart';
// import 'package:kongossa/config_App/colorsApp.dart';
// import '../../components/live_tv_player.dart';
// import '../../model/post_gallery.dart';
// import '../../presentation/component/widget/carousel_slider/carousel_slider.dart';
//
// class PostMediaFullScreen extends StatefulWidget {
//   final List<PostGallery> gallery;
//   final int? startIndex;
//
//   const PostMediaFullScreen({super.key, required this.gallery, this.startIndex});
//
//   @override
//   State<PostMediaFullScreen> createState() => _PostMediaFullScreenState();
// }
//
// class _PostMediaFullScreenState extends State<PostMediaFullScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return AppScaffold(
//       backgroundColor: ColorApp.backgroundDark,
//       body: Stack(
//         children: [
//           WKCarouselSlider(
//             items: mediaList(),
//             initialPage: widget.startIndex ?? 0,
//             enlargeCenterPage: false,
//             enableInfiniteScroll: false,
//             height: double.infinity,
//             viewportFraction: 1,
//           ),
//           appBar()
//         ],
//       ),
//     );
//   }
//
//   List<Widget> mediaList() {
//     return widget.gallery.map((item) {
//       if (item.isVideoPost == true) {
//         return videoPostTile(item);
//       } else {
//         return photoPostTile(item);
//       }
//     }).toList();
//   }
//
//   Widget videoPostTile(PostGallery media) {
//     return Center(
//       child: SocialifiedVideoPlayer(
//         url: media.filePath,
//         // isLocalFile: false,
//         play: false,
//         orientation: MediaQuery.of(context).orientation,
//       ),
//     );
//   }
//
//   Widget photoPostTile(PostGallery media) {
//     return CachedNetworkImage(
//       imageUrl: media.filePath,
//       fit: BoxFit.contain,
//       width: Get.width,
//       placeholder: (context, url) => AppUtil.addProgressIndicator(size: 100),
//       errorWidget: (context, url, error) => const Icon(Icons.error),
//     ).addPinchAndZoom();
//   }
//
//   Widget appBar() {
//     return Positioned(
//       child: SizedBox(
//         height: 150.0,
//         width: Get.width,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             ThemeIconWidget(
//               ThemeIcon.backArrow,
//               size: 20,
//               color: AppColorConstants.iconColor,
//             ).ripple(() {
//               Get.back();
//             }),
//           ],
//         ).hp(DesignConstants.horizontalPadding),
//       ),
//     );
//   }
// }
