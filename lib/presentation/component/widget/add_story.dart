// widgets/story_circle.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';


class StoryCircle extends StatelessWidget {
  final UserStory userStory;
  final VoidCallback onTap;
  final double radius;

  const StoryCircle({
    Key? key,
    required this.userStory,
    required this.onTap,
    this.radius = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !userStory.allViewed
                    ? const LinearGradient(
                  colors: [Colors.purple, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                border: userStory.allViewed
                    ? Border.all(color: Colors.grey.shade300, width: 3)
                    : null,
              ),
              padding: const EdgeInsets.all(3),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      userStory.userAvatarUrl,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   userStory.username,
            //   style: const TextStyle(fontSize: 12),
            //   overflow: TextOverflow.ellipsis,
            //   maxLines: 1,
            // ),
          ],
        ),
      ),
    );
  }
}




enum StoryMediaType { image, video }

class StoryModel {
  final String id;
  final String userId;
  final String username;
  final String userAvatarUrl;
  final String mediaUrl;
  final StoryMediaType mediaType;
  final DateTime timestamp;
  final Duration? videoDuration;
  final List<String> viewers;
  final bool isViewed;

  StoryModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    this.videoDuration,
    this.viewers = const [],
    this.isViewed = false,
  });

  // Méthode pour créer une copie avec des champs modifiés
  StoryModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? userAvatarUrl,
    String? mediaUrl,
    StoryMediaType? mediaType,
    DateTime? timestamp,
    Duration? videoDuration,
    List<String>? viewers,
    bool? isViewed,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      timestamp: timestamp ?? this.timestamp,
      videoDuration: videoDuration ?? this.videoDuration,
      viewers: viewers ?? this.viewers,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}

class UserStory {
  final String userId;
  final String username;
  final String userAvatarUrl;
  final List<StoryModel> stories;
  final bool hasUnviewedStories;

  UserStory({
    required this.userId,
    required this.username,
    required this.userAvatarUrl,
    required this.stories,
    this.hasUnviewedStories = false,
  });

  // Obtenir la dernière story
  StoryModel get lastStory => stories.last;

  // Vérifier si toutes les stories ont été vues
  bool get allViewed => stories.every((story) => story.isViewed);
}