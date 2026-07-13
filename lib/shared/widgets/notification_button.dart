import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:rive/rive.dart';

import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../model/datamodel/user_model.dart';
import '../../screens/mymember/chatpage.dart';
import '../../utils/transitions.dart';

class NotificationPopupButton extends StatefulWidget {
  final Color bellColor;
  final Color badgeColor;

  const NotificationPopupButton({
    Key? key,
    this.bellColor = Colors.red,
    this.badgeColor = Colors.red,
  }) : super(key: key);

  @override
  State<NotificationPopupButton> createState() =>
      _NotificationPopupButtonState();
}

class _NotificationPopupButtonState extends State<NotificationPopupButton> {
  int    _notificationCount = 0; // Example with 3 notifications


  @override
  void initState() {
    super.initState();
    // _loadNotifications();
  }



  void _updateNotificationCount(idnotif) {
    // _notificationCount = _notifications.where((n) => !n.isRead).length;
    FirestoreCollectionsService.notif.doc(idnotif).update({'isRead': true,});
  }

  void _markAsRead(String id) {
    _updateNotificationCount(id);
  }

  void _markAllAsRead(id) {

    _updateNotificationCount(id);
  }

  void _deleteNotification(String id) {
    _updateNotificationCount(id);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      offset: const Offset(0, 50),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            width: 320,
            height: 400,
            child: _buildNotificationList(),
          ),
        ),
      ],
      child: _buildNotificationBell(),
    );
  }

  // Separate widget for notification bell (single StreamBuilder)
  Widget _buildNotificationBell() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreCollectionsService.notif
          .where("receiveId", isEqualTo: AppUser.info!.googleId)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, notificationSnapshot) {
        final unreadCount = _getUnreadCount(notificationSnapshot);

        return Stack(
          children: [
            Container(
              width: 45,
              height: 45,
              margin: const EdgeInsets.only(right: 8),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  widget.bellColor,
                  BlendMode.srcATop,
                ),
                child: RiveAnimation.asset(
                  "assets/RiveAssets/icons.riv",
                  artboard: "BELL",
                  stateMachines: ["BELL_Interactivity"],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 2.w,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Helper pour compter les notifications non lues depuis un snapshot
  int _getUnreadCount(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return 0;
    return snapshot.data!.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isRead'] == false;
    }).length;
  }

  // Widget pour la liste des notifications
  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreCollectionsService.notif
          .where("receiveId", isEqualTo: AppUser.info!.googleId)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('notifications.error'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('notifications.empty'.tr));
        }

        final items = snapshot.data!.docs;
        final readCount = items.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isRead'] == false;
        }).length;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'notifications.title',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (readCount > 0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$readCount ${readCount > 1 ? 'notifications.new_plural'.tr : 'notifications.new'.tr}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildNotificationItems(
                      notification: NotificationModel(
                        uid: doc.id,
                        id: data['senderId'],
                        title: data['namesenderId'],
                        body: data['content'],
                        type: NotificationType.message,
                        isRead: data['isRead'] ?? false,
                        photo: data['photo'] ?? '',
                        time: (data['timestamp'] as Timestamp).toDate(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItems({required NotificationModel notification}) {
    return PopupMenuItem<String>(
      value: notification.id,
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        // onDismissed: (direction) {
        //   _deleteNotification(notification.id);
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: const Text('Notification deleted'),
        //       action: SnackBarAction(
        //         label: 'Annuler',
        //         onPressed: () {
        //           // Restaurer la notification
        //           setState(() {
        //             // _notifications.insert(0, notification);
        //             _updateNotificationCount(notification.id);
        //           });
        //         },
        //       ),
        //     ),
        //   );
        // },
        child: GestureDetector(
          onTap: () {
            debugPrint("result");
            _markAsRead(notification.uid);

            AppTransitions.toChat(ChatPageTikTok(
              receiverId: notification.id,
              receiverName: notification.title ,
              receiverPhoto: notification.photo,
            ));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon by type
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            _getTimeAgo(notification.time),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Indicateur de non-lu
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      onTap: () {
        debugPrint("verifie");
        debugPrint(notification.uid);
        _markAsRead(notification.uid);


        AppTransitions.toChat(ChatPageTikTok(
          receiverId: notification.id,
          receiverName: notification.title ,
          receiverPhoto: notification.photo,
        ));

        // _showNotificationDetails(context, notification);
      },
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    NotificationModel notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              'notifications.received'.tr + '${_getTimeAgo(notification.time)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('notifications.close'.tr),
          ),
          if (notification.type == NotificationType.message)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Reply action
              },
              child: Text('notifications.reply'.tr),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.update:
        return Icons.update;
      case NotificationType.promo:
        return Icons.local_offer;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.alert:
        return Icons.warning;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.update:
        return Colors.purple;
      case NotificationType.promo:
        return Colors.orange;
      case NotificationType.reminder:
        return Colors.green;
      case NotificationType.alert:
        return Colors.red;
    }
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays} j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min';
    } else {
      return 'à l\'instant';
    }
  }
}

// Notification model
enum NotificationType { message, update, promo, reminder, alert }

class NotificationModel {
  final String id;
  final String uid;
  final String title;
  final String body;
  final String? photo;
  final NotificationType type;
  bool isRead;
  final DateTime time;

  NotificationModel({
    required this.id,
    required this.title,
    required this.uid,
    required this.body,
     this.photo = '',
    required this.type,
    required this.isRead,
    required this.time,
  });
}
