import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirestoreCollectionsService extends GetxService {
  static FirestoreCollectionsService get to => Get.find();

  late CollectionReference usersCollection;
  late CollectionReference postsCollection;
  late CollectionReference smsCollection;
  late CollectionReference notificationsCollection;
  late CollectionReference livesCollection;

  @override
  void onInit() {
    super.onInit();
    usersCollection = FirebaseFirestore.instance.collection('user');
    postsCollection = FirebaseFirestore.instance.collection('postcarduser');
    smsCollection = FirebaseFirestore.instance.collection('message');
    notificationsCollection = FirebaseFirestore.instance.collection('notification');
    livesCollection = FirebaseFirestore.instance.collection('lives');
  }

  /// Shorthand static getters for convenience.
  static CollectionReference get users => to.usersCollection;
  static CollectionReference get posts => to.postsCollection;
  static CollectionReference get sms => to.smsCollection;
  static CollectionReference get notif => to.notificationsCollection;
  static CollectionReference get lives => to.livesCollection;
}
