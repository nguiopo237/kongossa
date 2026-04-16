// lib/widgets/stories_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kongossa/screens/storywindows/storyViewScreen.dart';
import 'package:kongossa/screens/storywindows/storyviewer.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';

import '../../model/datamodel/storyModels.dart';
import '../../presentation/component/image_component/image.dart';


class StoriesWidget extends StatefulWidget {
  final List<StoryModel> stories;
  final Function(StoryModel)? onStoryTap;
  final Function(StoryModel)? onStoryLongPress;
  final Color? backgroundColor;
  final Duration? animationDuration;

  const StoriesWidget({
    Key? key,
    required this.stories,
    this.onStoryTap,
    this.onStoryLongPress,
    this.backgroundColor,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _StoriesWidgetState createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: widget.backgroundColor ?? Colors.transparent,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.stories.length,
        itemBuilder: (context, index) {
          final story = widget.stories[index];
          return GestureDetector(
            onTap: () => _openStory(context, index),
            onLongPress: () => widget.onStoryLongPress?.call(story),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          gradient: story.isViewed
                              ? null
                              : const LinearGradient(
                            colors: [
                              Color(0xFFF58529),
                              Color(0xFFFEDA77),
                              Color(0xFFDD2A7B),
                              Color(0xFF8134AF),
                              Color(0xFF515BD4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        // child: CircleAvatar(
                        //   radius: 32,
                        //   backgroundImage: NetworkImage(story.userAvatar),
                        //   backgroundColor: Colors.grey[200],
                        // ),
                        child: CustomImage(
                          source: story.stories.first.mediaUrl,
                          type: ImageType.circle,
                          fit: BoxFit.cover,
                          height: 8.h,
                          width: 8.h,
                        ),
                      ),
                      if (story.isViewed)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    story.userName,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }




  void _openStory(BuildContext context, int index,) {
    // startCounting();

    Get.to(StoryViewerScreen(stories: widget.stories, initialIndex: index,onStoryTap: widget.onStoryTap,));
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => StoryViewerScreen(
    //       stories: widget.stories,
    //       initialIndex: index,
    //       onStoryTap: widget.onStoryTap,
    //     ),
    //   ),
    // ).then((_) {
    //   setState(() {});
    // });
  }
}