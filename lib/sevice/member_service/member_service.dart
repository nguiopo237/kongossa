// lib/services/member_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../model/datamodel/membermodel.dart';


class MemberService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream pour obtenir tous les membres (sauf l'utilisateur actuel)
  Stream<List<MemberModel>> getMembers({String? excludeUserId}) {
    Query query = _firestore.collection('users');

    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserId);
    }

    return query
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    });
  }

  // Stream pour obtenir les membres en ligne
  Stream<List<MemberModel>> getOnlineMembers({String? excludeUserId}) {
    Query query = _firestore
        .collection('users')
        .where('isOnline', isEqualTo: true);

    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      query = query.where(FieldPath.documentId, isNotEqualTo: excludeUserId);
    }

    return query
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    });
  }

  // Stream pour obtenir les membres suivis
  Stream<List<MemberModel>> getFollowingMembers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncMap((snapshot) async {
      List<MemberModel> members = [];
      for (var doc in snapshot.docs) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(doc.id)
            .get();
        if (userDoc.exists) {
          members.add(MemberModel.fromFirestore(userDoc));
        }
      }
      return members;
    });
  }

  // Stream pour rechercher des membres
  Stream<List<MemberModel>> searchMembers(String query, {String? excludeUserId}) {
    if (query.isEmpty) {
      return getMembers(excludeUserId: excludeUserId);
    }

    // Recherche par username ou displayName
    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => excludeUserId == null || doc.id != excludeUserId)
          .map((doc) => MemberModel.fromFirestore(doc))
          .toList();
    });
  }

  // Obtenir un membre par son ID
  Future<MemberModel?> getMemberById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return MemberModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getMemberById: $e');
      return null;
    }
  }

  // Update online status
  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updateOnlineStatus: $e');
    }
  }
}