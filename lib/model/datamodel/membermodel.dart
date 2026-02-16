// lib/models/member_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String uid;
  final String username;
  final String? displayName;
  final String? photoUrl;
  final String? email;
  final String googleId;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? status;
  final List<String>? interests;
  final int followersCount;
  final int followingCount;
  final bool isVerified;
  final DateTime? createdAt;

  MemberModel({
    required this.uid,
    required this.username,
    this.displayName,
    this.photoUrl,
    this.email,
    this.isOnline = false,
    this.lastSeen,
    this.status,
    this.interests,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isVerified = false,
    this.createdAt,
    required this.googleId,
  });

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MemberModel(
      uid: doc.id,
      username: data['name'] ?? 'pas specifier',
      displayName: data['displayName'] ?? data['username'],
      photoUrl: data['photoUrl'],
      email: data['email'],
      googleId: data['googleId'],
      isOnline: data['isOnline'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      status: data['status'],
      interests: List<String>.from(data['interests'] ?? []),
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'email': email,
      'googleId': googleId,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'status': status,
      'interests': interests,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isVerified': isVerified,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}