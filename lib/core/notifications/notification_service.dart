import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(String userId) async {
    // 1: Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("Notification Permission Granted");

      // 2: Get the device tokem
      String? token = await _messaging.getToken();

      if (token != null) {
        debugPrint("FCM token: $token");
        await _saveToken(userId, token);
      }

      // Initialize Local Notifications
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings();

      await _localPlugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

      // 3: Listen for Foreground Messages
      // (If the app is open, the notification doesn't pop up automatically. We handle it here.)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification!.title}',
          );
          // Ideally: Show a generic SnackBar here
        }
      });
    } else {
      debugPrint('User declined permission');
    }
  }

  Future<void> scheduleStudyReminder(DateTime dueDate) async {
    // Determine the scheduled time (eg 9 am on the due date)
    // for testing use 10 sec but in production use the dueDate

    // If the due date is in the past/today, schedule for 5 sec later
    var scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

    await _localPlugin.zonedSchedule(
      id: 0,
      title: 'Study Reminder',
      body: 'Time to review your flashcards!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recall_study_channel',
          'Study Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint("Scheduled reminder for: $scheduledDate");
  }

  //4: Save Token to Firestore
  Future<void> _saveToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
