// controllers/story_viewer_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import '../../../model/datamodel/storyModels.dart';
import '../../upload/upload_post.dart';

StoryViewerController st =Get.find();
class StoryViewerController extends GetxController {
  final PostUpdateService service = PostUpdateService();
  final List<StoryModel> stories;
  final int initialIndex;
  final Function(StoryModel)? onStoryTap;

  var currentUserIndex = 0.obs;
  var currentStoryIndex = 0.obs;
  var isLiked = false.obs;
  var showHeartAnimation = false.obs;
  var likeCount = 0.obs;
  var isPaused = false.obs;

  late PageController pageController;
  Map<String, VideoPlayerController?> videoControllers = {};
  Map<String, bool> videoInitialized = {};
  late AnimationController animationController;
  late Animation<double> animation;


  // Pour éviter les appels pendant le build
  Set<String> _viewedStories = {};

  StoryViewerController({
    required this.stories,
    required this.initialIndex,
    this.onStoryTap,
  });

  @override
  void onInit() {
    super.onInit();
    currentUserIndex.value = initialIndex;
    pageController = PageController(initialPage: currentUserIndex.value);
  }

  @override
  void onClose() {
    pageController.dispose();
    videoControllers.forEach((key, controller) {
      controller?.dispose();
    });
    super.onClose();
  }

  void toggleLike({required String id}) {
    showHeartAnimation.value = true;
    isLiked.value = !isLiked.value;
    likeCount.value += isLiked.value ? 1 : -1;

    service.toggleLike(postId: id);

    Future.delayed(const Duration(seconds: 1), () {
      if (Get.isRegistered<StoryViewerController>()) {
        showHeartAnimation.value = false;
      }
    });
  }

  // void resume() {
  //   if (isPaused.value && !_animationController.isCompleted) {
  //     _animationController.forward(from: _pausedValue);
  //     setState(() => _isPaused = false);
  //     print("Resumed from value: $_pausedValue");
  //   }
  // }
  // void reset() {
  //   _controller.reset();
  //   _controller.forward();
  //   _elapsed = Duration.zero;
  //   setState(() => _isPaused = false);
  // }
  //
  // void pause() {
  //   if (!_isPaused && _controller.isAnimating) {
  //     _elapsed = widget.duration * _controller.value;
  //     _controller.stop();
  //     setState(() => _isPaused = true);
  //   }
  // }



  void nextStory() {
    final currentUser = stories[currentUserIndex.value];
    if (currentStoryIndex.value < currentUser.stories.length - 1) {
      currentStoryIndex.value++;
    } else if (currentUserIndex.value < stories.length - 1) {
      currentUserIndex.value++;
      currentStoryIndex.value = 0;
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void previousStory() {
    if (currentStoryIndex.value > 0) {
      currentStoryIndex.value--;
    } else if (currentUserIndex.value > 0) {
      currentUserIndex.value--;
      currentStoryIndex.value = stories[currentUserIndex.value].stories.length - 1;
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  void pauseVideo() {
    final currentStory = stories[currentUserIndex.value]
        .stories[currentStoryIndex.value];
    if (currentStory.mediaType == StoryMediaType.video) {
      final videoId = '${currentStory.id}_${currentUserIndex.value}';
      videoControllers[videoId]?.pause();
      isPaused.value = true;
    }
  }

  void resumeVideo() {
    final currentStory = stories[currentUserIndex.value]
        .stories[currentStoryIndex.value];
    if (currentStory.mediaType == StoryMediaType.video) {
      final videoId = '${currentStory.id}_${currentUserIndex.value}';
      videoControllers[videoId]?.play();
      isPaused.value = false;
    }
  }

  void onPageChanged(int index) {
    currentUserIndex.value = index;
    currentStoryIndex.value = 0;
  }

  VideoPlayerController? getVideoController(StoryItem story) {
    final videoId = '${story.id}_${currentUserIndex.value}';

    if (!videoControllers.containsKey(videoId)) {
      videoControllers[videoId] = VideoPlayerController.network(story.mediaUrl)
        ..initialize().then((_) {
          videoInitialized[videoId] = true;
          update();
          videoControllers[videoId]!.play();
        });
    }

    return videoControllers[videoId];
  }

  bool isVideoInitialized(StoryItem story) {
    final videoId = '${story.id}_${currentUserIndex.value}';
    return videoInitialized[videoId] ?? false;
  }

  // Version corrigée : n'appelle pas update() immédiatement
  void markStoryAsViewed(StoryItem story) {
    final storyKey = '${currentUserIndex.value}_${story.id}';

    // Éviter les appels multiples pour la même story
    if (!_viewedStories.contains(storyKey) && !story.isViewed) {
      _viewedStories.add(storyKey);

      // Utiliser addPostFrameCallback pour éviter l'appel pendant le build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // if (mounted) {
        //   story.isViewed = true;
        //   // Ne pas appeler update() ici pour éviter de rebuild
        //   // La vue n'a pas besoin de se reconstruire pour ce changement
        // }
      });
    }
  }

  String formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} h';
    } else {
      return '${difference.inDays} j';
    }
  }
}