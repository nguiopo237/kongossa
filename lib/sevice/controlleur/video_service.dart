// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_video_trimmer/flutter_video_trimmer.dart' hide DurationStyle;
//
// import 'package:flutter_video_trimmer_ios_android/config/theme/color_schemes.dart';
// import 'package:flutter_video_trimmer_ios_android/core/utils/durations.dart';
// import 'package:flutter_video_trimmer_ios_android/flutter_video_trimmer.dart';
// import 'package:flutter_video_trimmer_ios_android/presentation/widgets/trimmer_widget.dart';
//
// import 'package:image_picker/image_picker.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// import '../../presentation/component/widget/cloudinaryvideoplayer.dart';
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   File? selectedVideo;
//   VideoPlayerController? videoPlayerController;
//   final int _maxVideoDuration = 300;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Flutter Video Trimmer"),
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             ElevatedButton(
//               child: const Text("LOAD VIDEO FROM GALLERY"),
//               onPressed: () async {
//                 await _getVideo(ImageSource.gallery);
//               },
//             ),
//             //show video player
//             selectedVideo != null ? _videoWidget() : Container(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _getVideo(ImageSource img,) async {
//     final ImagePicker picker = ImagePicker();
//     final pickedFile = await picker.pickVideo(
//         source: img,
//         maxDuration: Duration(
//           seconds: _maxVideoDuration,
//         ));
//     XFile? videoFile = pickedFile;
//     if (videoFile == null) {
//       return;
//     }
//     selectedVideo = File(videoFile.path);
//     debugPrint("Video Path: ${selectedVideo!.path}");
//     videoPlayerController = VideoPlayerController.file(
//       selectedVideo!,
//     )
//       ..initialize().then(
//             (_) {
//           if (videoPlayerController == null) {
//             return;
//           }
//           if (videoPlayerController!.value.duration.inSeconds >
//               _maxVideoDuration) {
//             Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       VideoTrimmerScreen(
//                         file: selectedVideo!,
//                         maxDuration: _maxVideoDuration,
//                       ),
//                 )).then((value) {
//               if (value != null) {
//                 selectedVideo = null;
//                 videoPlayerController = null;
//                 selectedVideo = File(value as String);
//                 videoPlayerController = VideoPlayerController.file(
//                   selectedVideo!,
//                 )
//                   ..initialize().then((_) {
//                     setState(() {});
//                   });
//               }
//             });
//           } else {
//             showDialog(
//               context: context,
//               builder: (context) =>
//                   AlertDialog(
//                     title: const Text("Video is too short"),
//                     content: const Text("Please choose another video"),
//                     actions: <Widget>[
//                       TextButton(
//                         child: const Text("OK"),
//                         onPressed: () {
//                           Navigator.of(context).pop();
//                         },
//                       ),
//                     ],
//                   ),
//             );
//           }
//         },
//       );
//   }
//
//   Widget _videoWidget() {
//     return videoPlayerController == null
//         ? const SizedBox.shrink()
//         : videoPlayerController!.value.isInitialized
//         ? Stack(
//       alignment: Alignment.center,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(12),
//           child: Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: 150,
//                 clipBehavior: Clip.hardEdge,
//                 decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: Colors.grey),
//                 child: SizedBox(
//                   height: 150,
//                   child: FutureBuilder<Uint8List?>(
//                     future: VideoThumbnail.thumbnailData(
//                       video: selectedVideo!.path,
//                       imageFormat: ImageFormat.JPEG,
//                       maxWidth: 128,
//                       quality: 100,
//                     ),
//                     builder: (BuildContext context,
//                         AsyncSnapshot<Uint8List?> snapshot) {
//                       if (snapshot.connectionState ==
//                           ConnectionState.done &&
//                           snapshot.data != null) {
//                         return Image.memory(
//                           snapshot.data!,
//                           fit: BoxFit.cover,
//                           width: double.infinity,
//                           height: double.infinity,
//                         );
//                       } else if (snapshot.error != null) {
//                         return Icon(Icons.error);
//                       } else {
//                         return const Center(
//                             child: CircularProgressIndicator());
//                       }
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         InkWell(
//           child: Icon(
//             videoPlayerController!.value.isPlaying
//                 ? Icons.pause
//                 : Icons.play_arrow,
//             color: ColorSchemes.white,
//             size: 50,
//           ),
//         ),
//         Positioned.directional(
//           end: 18,
//           bottom: 18,
//           textDirection: Directionality.of(context),
//           child: Text(
//             "${videoPlayerController!.value.position.inSeconds} / ${videoPlayerController!.value
//                 .duration.inSeconds}",
//             style: Theme
//                 .of(context)
//                 .textTheme
//                 .bodyMedium!
//                 .copyWith(
//               color: ColorSchemes.white,
//             ),
//           ),
//         ),
//       ],
//     )
//         : const SizedBox.shrink();
//   }
// }
//
//
//
// class VideoTrimmerScreen extends StatefulWidget {
//   final File file;
//   final int maxDuration;
//
//   const VideoTrimmerScreen({
//     super.key,
//     required this.file,
//     required this.maxDuration,
//   });
//
//   @override
//   State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
// }
//
// class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
//   final FlutterVideoTrimmer _trimmer = FlutterVideoTrimmer();
//
//   double _startValue = 0.0;
//   double _endValue = 0.0;
//   double _initialEndValue = 0.0;
//   bool _isPlaying = false;
//   bool _progressVisibility = false;
//
//   Future<String?> _saveVideo() async {
//     setState(() => _progressVisibility = true);
//     String? value;
//
//     await _trimmer.saveTrimmedVideo(
//       startValue: _startValue,
//       endValue: _endValue,
//       onSave: (String? outputPath) {
//         value = outputPath;
//         Navigator.pop(context, value);
//         debugPrint('OUTPUT PATH: $value');
//         const snackBar = SnackBar(content: Text('Video Saved successfully'));
//         ScaffoldMessenger.of(context).showSnackBar(snackBar);
//       },
//     ).then((_) {
//       setState(() => _progressVisibility = false);
//     });
//
//     return value;
//   }
//
//   void _loadVideo() => _trimmer.loadVideo(videoFile: widget.file);
//
//   @override
//   void initState() {
//     super.initState();
//     _loadVideo();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             const SizedBox(height: 16),
//             Expanded(child: VideoViewer(trimmer: Trimmer(),)),
//         //    Expanded(child: Videoplayerpost(files:  widget.file)),
//             const SizedBox(height: 10),
//             SizedBox(
//               height: 100,
//               child: TrimmerWidget(
//                 flutterVideoTrimmer: _trimmer,
//                 viewerHeight: 60.0,
//                 showDuration: true,
//                 durationStyle: DurationStyle.FORMAT_HH_MM_SS,
//                 durationTextStyle: const TextStyle(color: Colors.black),
//                 viewerWidth: MediaQuery
//                     .of(context)
//                     .size
//                     .width,
//                 onChangeStart: (value) => _startValue = value,
//                 onChangeEnd: (value) {
//                   _endValue = value;
//                   if (_initialEndValue == 0.0) _initialEndValue = value;
//                 },
//                 onChangePlaybackState: (value) =>
//                     setState(() => _isPlaying = value),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorSchemes.primary,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: ColorSchemes.primary,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       child: const Text("SAVE", style: TextStyle(color: Colors.white)),
//                       onPressed: () async {
//                         if (!_progressVisibility) {
//                           if (Duration(
//                               milliseconds: (_endValue - _startValue).toInt())
//                               .inSeconds >
//                               widget.maxDuration) {
//                             _showMessageDialog();
//                           } else {
//                             await _saveVideo();
//                           }
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _showMessageDialog() {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           AlertDialog(
//             content: Text(
//               "Keep It Short And Sweet — Videos Are Best At ${widget
//                   .maxDuration} Seconds Or Less. Thanks!",
//             ),
//             actions: [
//               TextButton(
//                 child: const Text("OK"),
//                 onPressed: () => Navigator.pop(context),
//               )
//             ],
//           ),
//     );
//   }
// }
