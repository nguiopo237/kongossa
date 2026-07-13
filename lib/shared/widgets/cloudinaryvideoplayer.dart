import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:responsive_sizer/responsive_sizer.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:path_provider/path_provider.dart';

import '../../config_App/colorsApp.dart';
import '../../config_App/image.dart';

class Videoplayerpost extends StatefulWidget {
  //Url to play video
  // final PostModel postModel;
  final String videoUrl;
  final String urlimage;
  final bool full;
  final bool isfile;
  final File? files;

  Videoplayerpost({
    Key? key,

    this.full = false,
    this.isfile = false,
    this.files,
    this.urlimage = "",
    this.videoUrl = "",
  }) : super(key: key);

  @override
  State<Videoplayerpost> createState() => _VideoplayerpostState();
}

class _VideoplayerpostState extends State<Videoplayerpost> with AutomaticKeepAliveClientMixin {
  // Controlleur c = Get.find();

  //player controller
  @override
  bool get wantKeepAlive => true;

  VideoPlayerController _controller = VideoPlayerController.networkUrl(Uri.parse(""));
  File? filestart;
  late FlickManager flickManager;
  bool isInitialized = false;

  File? file;

  late ValueNotifier<double> _progressNotifier;
  FileInfo? files;

  //Initialize Video Player

  void _checkIfVideoEnded() {
    if (_controller.value.position == _controller.value.duration) {
      debugPrint('Video ended.');
      setState(() {
        _controller.pause();
      });
    }
  }

  Future<void> downloadAndSaveVideo() async {
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/${widget.videoUrl.split("/").last}');
    double percent = 0.0;
    final urllocal = file.path;
    debugPrint(urllocal);

    Dio dio = Dio();
    var response = await dio.download(
      widget.videoUrl,
      file.path,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          percent = received / total;
          setState(() {
            _progressNotifier.value = percent * 100;
          });
          // if (percent == 0.39122302694669464) {
          //  inivideo();
          // }
          debugPrint("Download progress: $percent");
          // Update state or UI here if needed
        }
      },
    );
    final Uint8List fileContent = await File(urllocal).readAsBytes();
    await DefaultCacheManager().putFile(
      widget.videoUrl.split("/").last,
      fileContent,
    );
    debugPrint("Data cached successfully");
    if (response.statusCode == 200) {
      inivideo();
      debugPrint("Download successful");
      // Le téléchargement a réussi, vous pouvez maintenant lire la vidéo
    } else {
      debugPrint("Download error");        // Handle download error
    }
  }

  void _checkVideoCompletion() {
    if (_controller.value.position == _controller.value.duration) {
      setState(() {
        // c.pagecontroller
        //     .nextPage(duration: Duration(seconds: 1), curve: Curves.linear);
        // Video finished
        debugPrint('Video finished');
        // Add your logic here to handle video end
      });
    }
  }

  inivideo() async {
    _progressNotifier = ValueNotifier(0);
    files = await DefaultCacheManager().getFileFromCache(
      widget.videoUrl,
    );
    if (files == null) {
      debugPrint("empty");
      downloadAndSaveVideo();
    } else {
      debugPrint("cached");
      final file = File(files!.file.path);
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _controller!.pause();   // Start playing from the beginning
        });
      _controller.addListener(_checkVideoCompletion);
    }
  }

  void initializePlayer() async {
    files = await DefaultCacheManager().getFileFromCache(widget.videoUrl);
    if (files == null || files!.file == null) {
      // Download video if not in cache
      var response = await DefaultCacheManager().downloadFile(widget.videoUrl);
      debugPrint("video downloading...");
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {});
        });
      if (response != null) {
        initializePlayer();
        debugPrint("Download successful");
        // Download succeeded, you can now play the video
      } else {
        debugPrint("Download error");
        // Handle download error
      }
    } else {
      // Load video from cache        debugPrint("video already cached");
      final file = File(files!.file.path);
      _controller = VideoPlayerController.file(file);
      _controller!.initialize().then((value) {
        setState(() {
          _controller!.play();
        });
      });
      // return VideoPlayerController.file(fileInfo.file);
    }

  }

  Future<File?> downloadAndCacheVideo(String videoUrl) async {
    file = await DefaultCacheManager().getSingleFile(videoUrl);
    if (file != null) {
      debugPrint('Video already cached');
      return file;
    }
    debugPrint('Video downloaded and cached');
    return DefaultCacheManager().getSingleFile(videoUrl);
  }

  void initfile({File? files}){
    if (files == null) return;
    flickManager = FlickManager(
      autoInitialize: true,
      videoPlayerController: VideoPlayerController.file(files)
        ..setLooping(true),
      autoPlay: false,
      onVideoEnd: () {
        flickManager.flickControlManager?.pause();
      },
    );
    isInitialized = true;
    setState(() {});
  }

  initplayer(url) async {
    filestart = await downloadAndCacheVideo(url);
    if (filestart != null) {
      initfile(files: filestart);
    }
  }

  void initState() {
    super.initState();
    if (widget.files == null) {
      initplayer(widget.videoUrl);
    } else {
      initfile(files: widget.files);
    }
  }    @override
  void dispose() {
    _controller.removeListener(_checkVideoCompletion);
    _controller.dispose();
    _progressNotifier.dispose();
    super.dispose();
  }

  String VideoDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    return [if (duration.inHours > 0) hours, minutes, seconds].join(":");
  }

  //:cached Url Data

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return isInitialized == true
        ? VisibilityDetector(
            key: ObjectKey(flickManager),
            onVisibilityChanged: (visibilityInfo) {
              var visiblePercentage = visibilityInfo.visibleFraction * 50;
              debugPrint(
                'Widget ${visibilityInfo.key} is ${visiblePercentage}% visible',
              );

      if (visiblePercentage < 0.3) {          flickManager.flickControlManager?.pause();
      } else {
        flickManager.flickControlManager?.play();
      }
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  FlickVideoPlayer(
                    flickManager: flickManager,
                    flickVideoWithControls: FlickVideoWithControls(
                      videoFit: BoxFit.contain,
                      // backgroundColor: ColorApp.primary.withValues(alpha: 0.2),
                      willVideoPlayerControllerChange: true,
                      controls: IconTheme(
                        data: IconThemeData(color: ColorApp.primary),
                        child: FlickPortraitControls(
                          progressBarSettings: FlickProgressBarSettings(
                            playedColor: ColorApp.primary,
                            // Couleur du bouton play
                            bufferedColor: Colors.white.withValues(alpha: 0.2),
                            // Couleur de la barre de progression
                            handleColor: ColorApp
                                .primary, // Color of the handle icon
                          ),
                        ),
                      ),
                    ),

                    // flickVideoWithControls: FlickVideoWithControls(
                    //   playerLoadingFallback: Positioned.fill(
                    //     child: Stack(
                    //       children: <Widget>[
                    //         Positioned.fill(
                    //           child: Image.network(
                    //             "${AppConstants.baseUrlimage}${c.videodata.first.data!.items!.first.images!.first.mobile}",
                    //             fit: BoxFit.cover,
                    //           ),
                    //         ),
                    //         Positioned(
                    //           right: 10,
                    //           top: 10,
                    //           child: Container(
                    //             width: 20,
                    //             height: 20,
                    //             child: CircularProgressIndicator(
                    //               backgroundColor: Colors.white,
                    //               strokeWidth: 4,
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    //   // controls: FeedPlayerPortraitControls(
                    //   //   flickMultiManager: widget.flickMultiManager,
                    //   //   flickManager: flickManager,
                    //   // ),
                    // ),
                    // flickVideoWithControlsFullscreen: FlickVideoWithControls(
                    //   playerLoadingFallback: Center(
                    //       child: CacheImage(
                    //
                    //         fit: BoxFit.fitWidth, link: '"${AppConstants.baseUrlimage}${c.videodata.first.data!.items!.first.images!.first.mobile}"',
                    //       )),
                    //   controls: FlickLandscapeControls(),
                    //   iconThemeData: IconThemeData(
                    //     size: 40,
                    //     color: Colors.white,
                    //   ),
                    //   textStyle: TextStyle(fontSize: 16, color: Colors.white),
                    // ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 3.h,
                      ),
                      child: Opacity(
                        opacity: 0.5,
                        child: Image.asset(
                          Consticon.logo,
                          fit: BoxFit.contain,
                          height: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    widget.urlimage != null ? "${widget.videoUrl}" : "",
                  ),
                  fit: BoxFit.fill,
                ),
              ),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
  }
}
