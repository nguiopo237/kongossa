// lib/model/user_profile_model.dart

class UserProfileModel {
  final String uid;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final String? website;
  final int followersCount;
  final int followingCount;
  final int likesCount;
  final int postsCount;
  final bool isVerified;
  final bool isPrivate;
  final DateTime joinedDate;
  final List<StoryModel>? stories;
  final List<PostModel>? posts;
  final List<PostModel>? likedPosts;
  final List<PostModel>? savedPosts;

  UserProfileModel({
    required this.uid,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.website,
    this.followersCount = 0,
    this.followingCount = 0,
    this.likesCount = 0,
    this.postsCount = 0,
    this.isVerified = false,
    this.isPrivate = false,
    required this.joinedDate,
    this.stories,
    this.posts,
    this.likedPosts,
    this.savedPosts,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      displayName: json['displayName'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      website: json['website'],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      postsCount: json['postsCount'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      joinedDate: json['joinedDate'] != null
          ? DateTime.parse(json['joinedDate'])
          : DateTime.now(),
    );
  }
}

class StoryModel {
  final String id;
  final String imageUrl;
  final bool isViewed;
  final DateTime timestamp;

  StoryModel({
    required this.id,
    required this.imageUrl,
    this.isViewed = false,
    required this.timestamp,
  });
}

class PostModel {
  final String id;
  final String mediaUrl;
  final MediaType mediaType;
  final int likesCount;
  final int commentsCount;
  final DateTime timestamp;

  PostModel({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.timestamp,
  });
}

enum MediaType { image, video }