// views/story_viewer_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';
import '../../model/datamodel/storyModels.dart';
import '../../presentation/component/image_component/image.dart';
import '../../presentation/component/widget/component_for_post/like_button.dart';
import '../../sevice/controlleur/chat_controlleur/chat_controlleur.dart';
import '../../sevice/controlleur/soryviewcontrolleur/soryControlleur.dart';
import '../mymember/chatpage.dart';

class StoryViewerScreen extends StatelessWidget {
  final List<StoryModel> stories;
  final int? initialIndex;
  final Function(StoryModel)? onStoryTap;

  const StoryViewerScreen({
    Key? key,
    required this.stories,
     this.initialIndex = 0,
    this.onStoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<StoryViewerController>(
      init: StoryViewerController(
        stories: stories,
        initialIndex: initialIndex!,
        onStoryTap: onStoryTap,
      ),
      builder: (controller) {
        return PageView.builder(
          controller: controller!.pageController,
          onPageChanged: controller!.onPageChanged,
          itemCount: stories.length,
          itemBuilder: (context, userIndex) {
         // if(initialIndex!=0){
         //   userIndex = initialIndex!;
         // }
            final userStories = stories[userIndex];
            final chatController = Get.put(
              ChatController(
                receiverId: userStories.id,
                receiverName: userStories.userName,
                receiverPhoto: userStories.userAvatar,
                isOnline: false,
              ),
            );


            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: GestureDetector(
                  onTap: () {
                    controller.onStoryTap?.call(userStories);
                    controller.nextStory();
                  },
                  onLongPress: controller.pauseVideo,
                  onLongPressUp: controller.resumeVideo,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildStoryContent(controller, userStories),
                      _buildStoryOverlay(controller, userStories),
                      _buildNavigationZones(controller),
                      // Obx(() => controller.showHeartAnimation.value
                      //     ? _buildHeartAnimation(controller)
                      //     : const SizedBox.shrink()),
                    ],
                  ),
                ),
              ),
              bottomSheet: _buildBottomSheet(
                controller: controller,
                chatController: chatController,
                userStories: userStories,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStoryContent(
    StoryViewerController controller,
    StoryModel userStories,
  ) {
    final story = userStories.stories[controller.currentStoryIndex.value];

    controller.markStoryAsViewed(story);

    if (story.mediaType == StoryMediaType.video) {
      return _buildVideoPlayer(controller, story);
    } else {
      return CustomImage(
        source: story.mediaUrl,
        type: ImageType.cachedNetwork,
        width: double.infinity,
        height: double.infinity,
        errorWidget: const Center(
          child: Icon(Icons.error, color: Colors.white, size: 48),
        ),
      );
    }
  }

  Widget _buildVideoPlayer(StoryViewerController controller, StoryItem story) {
    final videoController = controller.getVideoController(story);
    final isInitialized = controller.isVideoInitialized(story);

    if (videoController != null && isInitialized) {
      return Stack(
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController.value.size.width,
                height: videoController.value.size.height,
                child: VideoPlayer(videoController),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Icon(
                  videoController.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
                onPressed: () {
                  if (videoController.value.isPlaying) {
                    videoController.pause();
                  } else {
                    videoController.play();
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildStoryOverlay(
    StoryViewerController controller,
    StoryModel userStories,
  ) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildProgressBars(controller, userStories),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildUserInfo(controller, userStories),
        ),
        Obx(
          () => controller.isPaused.value
              ? Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
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
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildProgressBars(
    StoryViewerController controller,
    StoryModel userStories,
  ) {
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
              child: StoryProgressBar(
                currentIndex: controller.currentStoryIndex.value,
                storyIndex: index,
                totalStories: userStories.stories.length,
                onComplete: controller.nextStory,
                incomplete: () {},
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildUserInfo(
    StoryViewerController controller,
    StoryModel userStories,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
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
              controller.formatTimestamp(userStories.timestamp),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationZones(StoryViewerController controller) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: controller.previousStory,
            behavior: HitTestBehavior.translucent,
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: controller.nextStory,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }

  Widget _buildHeartAnimation(StoryViewerController controller) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Opacity(
              opacity: (1 - value).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: 1 + value,
                child: const Icon(Icons.favorite, color: Colors.red, size: 80),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomSheet({
    required StoryViewerController controller,
    required ChatController chatController,
    required StoryModel userStories,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                  child: MessageTextField(
                    ontape: () {
                      if(FocusManager.instance.primaryFocus != null){
                        st.animationController.stop();
                        print("compat");
                      }else{
                        st.animationController.forward();
                        print("compat");
                      }
                    },
                    // onchange: (value) {
                    //   print("compat");
                    //   if (value.isNotEmpty) {
                    //     st.animationController.stop();
                    //   }
                    // },

                    controller: chatController,
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  controller: controller,
                  icon: Icons.add,
                  color: Colors.white,
                  label: controller.formatCount(1),
                  onTap: () => controller.toggleLike(id: userStories.id),
                ),
                Obx(
                  () => _buildActionButton(
                    controller: controller,
                    icon: controller.isLiked.value
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: controller.isLiked.value ? Colors.red : Colors.white,
                    label: controller.formatCount(controller.likeCount.value),
                    onTap: () => controller.toggleLike(id: userStories.id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required StoryViewerController controller,
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
}

// StoryProgressBar mis à jour
class StoryProgressBar extends StatefulWidget {
  final int currentIndex;
  final int storyIndex;
  final int totalStories;
  final VoidCallback onComplete;
  final VoidCallback incomplete;

  const StoryProgressBar({
    Key? key,
    required this.currentIndex,
    required this.storyIndex,
    required this.totalStories,
    required this.onComplete,
    required this.incomplete,
  }) : super(key: key);

  @override
  State<StoryProgressBar> createState() => _StoryProgressBarState();
}

class _StoryProgressBarState extends State<StoryProgressBar>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;
  double _pausedValue = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimation();
  }

  void _initAnimation() {
    st.animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    st.animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(st.animationController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              Get.back();
            }
          });

    if (widget.storyIndex == widget.currentIndex) {
      st.animationController.forward();
    }
  }

  @override
  void didUpdateWidget(StoryProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.storyIndex == widget.currentIndex &&
        widget.currentIndex != oldWidget.currentIndex) {
      st.animationController.forward(from: 0);
    } else if (widget.storyIndex < widget.currentIndex) {
      st.animationController.value = 1.0;
    } else if (widget.storyIndex > widget.currentIndex) {
      st.animationController.value = 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("_animation.value");
    print(st.animation.value);
    print("_animation.value");
    return AnimatedBuilder(
      animation: st.animation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: st.animation.value,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 3,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    st.animationController.dispose();
    super.dispose();
  }
}
