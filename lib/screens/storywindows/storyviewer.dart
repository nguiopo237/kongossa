// lib/screens/story_viewer_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';

import '../../model/datamodel/storyModels.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/widget/animatedWidgets/storywidget.dart';
import '../../presentation/component/widget/component_for_post/like_button.dart';
import '../../sevice/controlleur/chat_controlleur/chat_controlleur.dart';
import '../../sevice/upload/upload_post.dart';
import '../mymember/chatpage.dart';

class StoryViewerScreens extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final Function(StoryModel)? onStoryTap;

  const StoryViewerScreens({
    Key? key,
    required this.stories,
    required this.initialIndex,
    this.onStoryTap,
  }) : super(key: key);

  @override
  _StoryViewerScreensState createState() => _StoryViewerScreensState();
}

class _StoryViewerScreensState extends State<StoryViewerScreens> {
  late PageController _pageController;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;
  Map<String, VideoPlayerController?> _videoControllers = {};
  Map<String, bool> _videoInitialized = {};
  bool _isLiked = false;
  bool _showHeartAnimation = false;
  int _likeCount = 0;

  final PostUpdateService service = PostUpdateService();

  void _toggleLike({required String id}) {
    if (!mounted) return;

    setState(() {
      _showHeartAnimation = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    service.toggleLike(
      postId: id,
      // isLiked: _isLiked,
      // like: widget.likes,
    );
  }

  @override
  void initState() {
    super.initState();
    // startCounting();
    _currentUserIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentUserIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoControllers.forEach((key, controller) {
      controller?.dispose();
    });
    super.dispose();
  }

  void _nextStory() {
    final currentUser = widget.stories[_currentUserIndex];
    if (_currentStoryIndex < currentUser.stories.length - 1) {
      setState(() {
        _currentStoryIndex++;
      });
    } else if (_currentUserIndex < widget.stories.length - 1) {
      setState(() {
        _currentUserIndex++;
        _currentStoryIndex = 0;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _previousStory() {
    if (_currentStoryIndex > 0) {
      setState(() {
        _currentStoryIndex--;
      });
    } else if (_currentUserIndex > 0) {
      setState(() {
        _currentUserIndex--;
        _currentStoryIndex =
            widget.stories[_currentUserIndex].stories.length - 1;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } else {
      Navigator.pop(context);
    }
  }

  int _currentNumber = 1;
  late Timer _timer;
  bool _isCounting = false;
  int _count = 1;
  double progress = 5;

  void stopCounting() {
    _timer?.cancel();
    setState(() {
      _isCounting = false;
    });
  }

  void startCounting() {
    print("object");
    if (_isCounting) return;

    // setState(() {
    _isCounting = true;
    _count = 1;
    // });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      print(_timer.toString());
      if (_currentNumber < 5) {
        setState(() {
          progress = (progress / double.parse(_currentNumber.toString()));
          _currentNumber++;
        });
        print(progress.toString());
        print(progress.toString());
      } else {
        print(_timer.toString());
        stopCounting();
        // Arrivé à 5, faire quelque chose
        print("Compteur terminé !");
      }
    });
  }

  Offset _heartPosition = Offset.zero;
int time = 40;
  Widget buildHeartAnimation() {
    return Positioned(
      left: _heartPosition.dx - 30,
      top: _heartPosition.dy - 30,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration:  Duration(seconds: time ),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          print("times");
          print(time);
          print(value);
          print("times");
          return Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: value,
              child: const Icon(Icons.favorite, color: Colors.red, size: 60),
            ),
          );
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  })
  {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentUserIndex = index;
          _currentStoryIndex = 0;
        });
      },
      itemCount: widget.stories.length,
      itemBuilder: (context, userIndex) {
        final userStories = widget.stories[userIndex];
        final ChatController controller = Get.put(
          ChatController(
            receiverId: userStories.id,
            receiverName: userStories.userName,
            receiverPhoto: userStories.userAvatar,
            isOnline: false,

            // onesignalId: widget.onesignalId,
          ),
          // permanent: true,
        );

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: GestureDetector(
              onTap: () {
                widget.onStoryTap?.call(userStories);
                _nextStory();
              },
              onLongPress: _pauseVideo,
              onLongPressUp: _resumeVideo,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Contenu principal
                  _buildStoryContent(userStories),

                  // Overlay UI
                  _buildStoryOverlay(userStories),
                 // SimpleHeartAnimation(position: Offset(10,5), isActive: false,)

                  // Zones de navigation tactile
                  _buildNavigationZones(),
                ],
              ),
            ),
          ),
          bottomSheet: _buildBottomSheet(controller: controller,userStories: userStories),
        );
      },
    );
  }

  Widget _buildStoryContent(StoryModel userStories) {
    final story = userStories.stories[_currentStoryIndex];

    // Marquer comme vu
    if (!story.isViewed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          story.isViewed = true;
          // userStories.isViewed = true;
        });
      });
    }

    if (story.mediaType == StoryMediaType.video) {
      return _buildVideoPlayer(story);
    } else {
      return CustomImage(
        source: story.mediaUrl,
        type: ImageType.cachedNetwork,
        width: double.infinity,
        height: double.infinity,
        errorWidget: Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
      return _buildImage(story);
    }
  }

  Widget _buildImage(StoryItem story) {
    return Image.network(
      story.mediaUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        );
      },
    );
  }

  Widget _buildVideoPlayer(StoryItem story) {
    final videoId = '${story.id}_${_currentUserIndex}';

    if (!_videoControllers.containsKey(videoId)) {
      _videoControllers[videoId] = VideoPlayerController.network(story.mediaUrl)
        ..initialize().then((_) {
          setState(() {
            _videoInitialized[videoId] = true;
          });
          _videoControllers[videoId]!.play();
        });
    }

    final controller = _videoControllers[videoId];
    final isInitialized = _videoInitialized[videoId] ?? false;

    if (controller != null && isInitialized) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
          ),
          // Contrôles vidéo
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    if (controller.value.isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildProgressBars(StoryModel userStories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(userStories.stories.length, (index) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
              child: _buildProgressBar(userStories, index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProgressBar(StoryModel userStories, int index) {
    final isCurrentStory = index == _currentStoryIndex;
    final isCompleted = index < _currentStoryIndex;
    final story = userStories.stories[index];

    // double progress = 0;
    //  if (isCurrentStory) {
    //    // Simuler la progression
    // setState(() {
    //   progress = progress;
    // });// À implémenter avec un timer réel
    //  } else if (isCompleted) {
    //    setState(() {
    //      progress = 1;
    //    });
    //  }
    return StoryProgressBar(currentIndex: _currentStoryIndex, totalStories: 1, onComplete: () {
      if (isCompleted) {
        Get.back();
      } else {
        _nextStory();
      }
    }, incomplete: () {  },);

    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(seconds: 5),
      onEnd: () {
        if (isCompleted) {
          Get.back();
        } else {
          _nextStory();
        }
      },
      builder: (context, value, _) {
        print("times");
        print(value);
        print("times");
        return Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: index == index ? value : 0,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfo(StoryModel userStories) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          // backgroundImage: NetworkImage(userStories.userAvatar),
          child: CustomImage(
            source: userStories.userAvatar,
            type: ImageType.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userStories.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatTimestamp(userStories.timestamp),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
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

  void _pauseVideo() {
    final currentStory =
        widget.stories[_currentUserIndex].stories[_currentStoryIndex];
    if (currentStory.mediaType == StoryMediaType.video) {
      final videoId = '${currentStory.id}_${_currentUserIndex}';
      _videoControllers[videoId]?.pause();
    }
  }

  void _resumeVideo() {
    final currentStory =
        widget.stories[_currentUserIndex].stories[_currentStoryIndex];
    if (currentStory.mediaType == StoryMediaType.video) {
      final videoId = '${currentStory.id}_${_currentUserIndex}';
      _videoControllers[videoId]?.play();
    }
  }
  bool _isPaused =false;
  Widget _buildStoryOverlay(StoryModel userStories) {
    return Stack(
      children: [
        // Barres de progression


        // En-tête avec infos utilisateur
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildUserInfo(userStories),
        ),

        // Indicateur de statut (lecture/pause)
        if (_isPaused)
          Positioned(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildProgressBars(userStories),
        ),
      ],
    );
  }

  Widget _buildNavigationZones() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _previousStory,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _nextStory,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet({required ChatController controller,StoryModel? userStories}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            color: Colors.white24,
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: MessageTextField(controller: controller,
                    
                    // controller: controller,
                    // hintText: 'Envoyer un message...',
                    // textStyle: const TextStyle(color: Colors.white),
                    // decoration: InputDecoration(
                    //   filled: true,
                    //   fillColor: Colors.white.withOpacity(0.1),
                    //   border: OutlineInputBorder(
                    //     borderRadius: BorderRadius.circular(24),
                    //     borderSide: BorderSide.none,
                    //   ),
                    //   contentPadding: const EdgeInsets.symmetric(
                    //     horizontal: 16,
                    //     vertical: 12,
                    //   ),
                    // ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  label: _formatCount(1),
                  onTap: () => _toggleLike(id: userStories!.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class SimpleHeartAnimation extends StatefulWidget {
  final Offset position;
  final bool isActive;

  const SimpleHeartAnimation({
    Key? key,
    required this.position,
    required this.isActive,
  }) : super(key: key);

  @override
  State<SimpleHeartAnimation> createState() => _SimpleHeartAnimationState();
}

class _SimpleHeartAnimationState extends State<SimpleHeartAnimation>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SimpleHeartAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.forward();
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 30,
      top: widget.position.dy - 30,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _animation.value,
              child: child,
            ),
          );
        },
        child: const Icon(
          Icons.favorite,
          color: Colors.red,
          size: 60,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class StoryProgressController {
  _StoryProgressBarState? _state;

  void pause() => _state?.pause();
  void resume() => _state?.resume();
  void reset() => _state?.reset();

  void attach(_StoryProgressBarState state) {
    _state = state;
  }

  void detach() {
    _state = null;
  }
}

class StoryProgressBar extends StatefulWidget {
  final int currentIndex;
  final int totalStories;
  final VoidCallback onComplete;
  final VoidCallback incomplete;
  final StoryProgressController? controller;

  const StoryProgressBar({
    Key? key,
    required this.currentIndex,
    required this.totalStories,
    required this.onComplete,
    required this.incomplete,
    this.controller,
  }) : super(key: key);

  @override
  State<StoryProgressBar> createState() => _StoryProgressBarState();
}

class _StoryProgressBarState extends State<StoryProgressBar>
    with SingleTickerProviderStateMixin {

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isPaused = false;
  double _pausedValue = 0.0;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    _initAnimation();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController)
      ..addListener(() {
        if (mounted) setState(() {
          print("_animation.status");
          print(_animation.status);
          print(_animation.status);
          print("_animation.status");
        });
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _animationController.forward();
  }

  void pause() {
    if (!_isPaused && _animationController.isAnimating) {
      _pausedValue = _animation.value;
      _animationController.stop();
      setState(() => _isPaused = true);
      print("Paused at value: $_pausedValue");
    }
  }

  void resume() {
    if (_isPaused && !_animationController.isCompleted) {
      _animationController.forward(from: _pausedValue);
      setState(() => _isPaused = false);
      print("Resumed from value: $_pausedValue");
    }
  }

  void reset() {
    _animationController.reset();
    _animationController.forward();
    _pausedValue = 0.0;
    setState(() => _isPaused = false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 10.h,
        color: Colors.green,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _animation.value,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 3,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _animationController.dispose();
    super.dispose();
  }
}