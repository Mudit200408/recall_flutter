import 'dart:io';

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

      // 2: Get the device token (with APNS retry for iOS)
      if (Platform.isIOS) {
        // On iOS, wait for the APNS token before requesting FCM token.
        // This can fail on simulators where APNS isn't supported — that's OK.
        try {
          String? apnsToken = await _messaging.getAPNSToken();
          if (apnsToken == null) {
            for (int i = 0; i < 3; i++) {
              await Future.delayed(const Duration(seconds: 2));
              apnsToken = await _messaging.getAPNSToken();
              if (apnsToken != null) break;
            }
          }
        } catch (e) {
          debugPrint("APNS token not available (expected on simulator): $e");
        }
      }

      try {
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint("FCM token: $token");
          await _saveToken(userId, token);
        }
      } catch (e) {
        debugPrint("Error getting FCM token: $e");
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

  Future<void> scheduleStudyReminder(
    DateTime dueDate, {
    String? deckTitle,
  }) async {
    var scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

    final title = deckTitle != null
        ? '🃏 New cards for "$deckTitle"!'
        : 'Study Reminder';
    final body = deckTitle != null
        ? 'Your next batch is ready. Recall it now!!'
        : 'Time to review your flashcards!';

    // Use deckTitle hashCode for unique ID so notifications don't overwrite each other
    final notificationId = deckTitle?.hashCode.abs() ?? 0;

    await _localPlugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
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

    debugPrint("Scheduled reminder for: $scheduledDate (deck: $deckTitle)");
  }

  //4: Save Token to Firestore
  Future<void> _saveToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
