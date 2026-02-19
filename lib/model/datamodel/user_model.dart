import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  String uid;
  String googleId;
  String displayName;
  String email;
  String? photoUrl;
  String? serverAuthCode;
  DateTime createdAt;
  DateTime updatedAt;
  String? phoneNumber;
  String? bio;
  bool isEmailVerified;

  AppUser({
    required this.uid,
    required this.googleId,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.serverAuthCode,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.bio,
    this.isEmailVerified = false,
  });

  // Depuis Firebase Document
 static AppUser ?info;

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: doc.id,
      googleId: data['googleId'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      serverAuthCode: data['serverAuthCode'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      phoneNumber: data['phoneNumber'],
      isEmailVerified: data['isEmailVerified'] ?? false,
    );
  }

  // Vers Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'googleId': googleId,
      'uid': uid,
      'displayName': displayName,
      'bio': bio,
      'email': email,
      'photoUrl': photoUrl,
      'serverAuthCode': serverAuthCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'phoneNumber': phoneNumber,
      'isEmailVerified': isEmailVerified,
    };
  }

  // Depuis Google Sign-In
  factory AppUser.fromGoogleSignIn(Map<String, dynamic> googleData) {
    return AppUser(
      uid: '', // À générer
      googleId: googleData['id'] ?? '',
      displayName: googleData['displayName'] ?? '',
      email: googleData['email'] ?? '',
      photoUrl: googleData['photoUrl'] ?? '',
      serverAuthCode: googleData['serverAuthCode'] ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isEmailVerified: true,
    );
  }
}