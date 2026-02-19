import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationDemo extends StatefulWidget {
  @override
  _NotificationDemoState createState() => _NotificationDemoState();
}

class _NotificationDemoState extends State<NotificationDemo> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    // _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Configuration pour Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration pour iOS
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer quand l'utilisateur clique sur la notification
        print('Notification cliquée: ${response.payload}');
        print('Action ID: ${response.actionId}');
        _showDialog(context, response.payload!, response.actionId);
      },
    );

    // Demander les permissions Android (version 19+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      print('Permission notifications: $granted');

      // Vérifier et demander la permission pour les alarmes exactes
      if (await androidImplementation.canScheduleExactNotifications() == false) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  // Notification immédiate simple
  Future<void> _showSimpleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'simple_channel',
      'Notifications Simples',
      channelDescription: 'Canal pour les notifications simples',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notification Simple',
      'Ceci est une notification simple de test',
      platformChannelSpecifics,
      payload: 'simple_notification',
    );

    _showSuccessSnackBar('Notification simple envoyée');
  }

  // Notification périodique (version 19+)
  Future<void> _schedulePeriodicNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'periodic_channel',
      'Notifications Périodiques',
      channelDescription: 'Canal pour les notifications périodiques',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      'Notification Périodique',
      'Cette notification apparaît toutes les minutes',
      RepeatInterval.everyMinute,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'periodic_notification',
    );

    _showSuccessSnackBar('Notification périodique programmée (toutes les minutes)');
  }

  // Notification programmée (version 19+)
  Future<void> _scheduleNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'scheduled_channel',
      'Notifications Programmées',
      channelDescription: 'Canal pour les notifications programmées',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      'Notification Programmée',
      'Cette notification apparaîtra dans 5 secondes',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      payload: 'scheduled_notification',
    );

    _showSuccessSnackBar('Notification programmée dans 5 secondes');
  }

  // Notification avec image (version 19+)
  Future<void> _showImageNotification() async {
    final BigPictureStyleInformation bigPictureStyleInformation =
    BigPictureStyleInformation(
      DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      contentTitle: 'Notification avec image',
      summaryText: 'Ceci est une notification avec une grande image',
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'image_channel',
      'Notifications avec Image',
      channelDescription: 'Canal pour les notifications avec images',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigPictureStyleInformation,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      3,
      'Notification avec Image',
      'Regardez cette belle image',
      platformChannelSpecifics,
      payload: 'image_notification',
    );

    _showSuccessSnackBar('Notification avec image envoyée');
  }

  // Notification avec actions personnalisées (version 19+)
  Future<void> _showNotificationWithActions() async {
    final List<AndroidNotificationAction> actions = [
      AndroidNotificationAction(
        'action_approve',
        'Approuver',
        showsUserInterface: true,
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        'action_reject',
        'Rejeter',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ];

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'action_channel',
      'Notifications avec Actions',
      channelDescription: 'Canal pour les notifications avec actions',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'actions_category',


      ),
    );

    await flutterLocalNotificationsPlugin.show(
      4,
      'Notification avec Actions',
      'Choisissez une option',
      platformChannelSpecifics,
      payload: 'action_notification',
    );

    _showSuccessSnackBar('Notification avec actions envoyée');
  }

  // Notification avec progression (nouvelle fonctionnalité)
  Future<void> _showProgressNotification() async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'progress_channel',
      'Notifications avec Progression',
      channelDescription: 'Canal pour les notifications avec barre de progression',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: 50,
      indeterminate: false,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      5,
      'Téléchargement en cours',
      '50% complété',
      platformChannelSpecifics,
      payload: 'progress_notification',
    );

    _showSuccessSnackBar('Notification avec progression (50%)');
  }

  // Annuler une notification spécifique
  Future<void> _cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    _showSuccessSnackBar('Notification #$id annulée');
  }

  // Annuler toutes les notifications
  Future<void> _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    _showSuccessSnackBar('Toutes les notifications ont été annulées');
  }

  // Obtenir les notifications actives (Android uniquement)
  Future<void> _getActiveNotifications() async {
    final List<ActiveNotification>? activeNotifications =
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();

    if (activeNotifications != null && activeNotifications.isNotEmpty) {
      _showDialog(
        context,
        'Notifications actives',
        '${activeNotifications.length} notification(s) active(s)',
      );
    } else {
      _showDialog(context, 'Aucune notification', 'Aucune notification active');
    }
  }

  // Afficher un SnackBar de succès
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Afficher une boîte de dialogue
  void _showDialog(BuildContext context, String title, String? message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message ?? 'Pas de message'),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Notifications v19'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showDialog(
              context,
              'Info',
              'Flutter Local Notifications v19.0.0\n\n' +
                  '• Notifications immédiates\n' +
                  '• Notifications programmées\n' +
                  '• Notifications périodiques\n' +
                  '• Actions personnalisées\n' +
                  '• Barre de progression',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(),
                SizedBox(height: 24),
                _buildButton(
                  icon: Icons.notifications_active,
                  label: 'Notification Simple',
                  color: Colors.blue,
                  onPressed: _showSimpleNotification,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.schedule,
                  label: 'Notification Programmée (5s)',
                  color: Colors.orange,
                  onPressed: _scheduleNotification,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.repeat,
                  label: 'Notification Périodique',
                  color: Colors.green,
                  onPressed: _schedulePeriodicNotification,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.image,
                  label: 'Notification avec Image',
                  color: Colors.purple,
                  onPressed: _showImageNotification,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.touch_app,
                  label: 'Notification avec Actions',
                  color: Colors.teal,
                  onPressed: _showNotificationWithActions,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.pie_chart,
                  label: 'Notification avec Progression',
                  color: Colors.indigo,
                  onPressed: _showProgressNotification,
                ),
                SizedBox(height: 24),
                Divider(height: 1, thickness: 1),
                SizedBox(height: 16),
                _buildButton(
                  icon: Icons.list,
                  label: 'Voir Notifications Actives',
                  color: Colors.amber.shade800,
                  onPressed: _getActiveNotifications,
                ),
                SizedBox(height: 12),
                _buildButton(
                  icon: Icons.cancel,
                  label: 'Annuler Toutes',
                  color: Colors.red,
                  onPressed: _cancelAllNotifications,
                ),
                SizedBox(height: 20),
                _buildInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications,
            size: 50,
            color: Colors.blue,
          ),
          SizedBox(height: 10),
          Text(
            'Démonstration Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Flutter Local Notifications v19',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cliquez sur une notification pour voir son payload. '
                  'Les actions "Approuver/Rejeter" sont interactives!',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 3,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}