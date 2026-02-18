import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize({String? userId}) async {
    // 0: Initialize Timezones
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint("DETECTED TIMEZONE: $timeZoneName");
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
      debugPrint("Timezone initialized to: $timeZoneName");
    } catch (e) {
      debugPrint(
        "Could not get local timezone, defaulting to Asia/Kolkata: $e",
      );
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
    debugPrint("Final Local Timezone: ${tz.local.name}");
    debugPrint("Timezones initialized");

    // 1: Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("Notification Permission Granted");

      // Initialize Local Notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings();

      await _localPlugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );
      debugPrint("Local Notifications Plugin Initialized");

      // Request Android 13+ Notification Permission & Exact Alarms
      final androidImplementation = _localPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      // 2: Get the device token (with APNS retry for iOS) — skip for guests
      if (userId != null) {
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
      }

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
    debugPrint("Attempting to schedule study reminder for $dueDate");
    var scheduledDate = tz.TZDateTime.from(dueDate, tz.local);

    final title = deckTitle != null
        ? '🃏 New cards for "$deckTitle"!'
        : 'Study Reminder';
    final body = deckTitle != null
        ? 'Your next batch is ready. Recall it now!!'
        : 'Time to review your flashcards!';

    // Use deckTitle hashCode for unique ID so notifications don't overwrite each other
    final notificationId = deckTitle?.hashCode.abs() ?? 0;

    debugPrint("Current time (local): ${tz.TZDateTime.now(tz.local)}");
    debugPrint("Scheduled time: $scheduledDate");

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("WARNING: Scheduled time is in the past!");
      // Optional: Bump it to the future for testing
      // scheduledDate = scheduledDate.add(const Duration(minutes: 1));
    }

    await _localPlugin.zonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recall_study_channel_v2', // Changed ID to force update
          'Study Reminders',
          importance: Importance.max,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // Changed to exact
    );

    debugPrint("Scheduled reminder for: $scheduledDate (deck: $deckTitle)");

    final pendingNotifications = await _localPlugin
        .pendingNotificationRequests();
    debugPrint("🔔 --- PENDING NOTIFICATIONS ---");
    for (var notification in pendingNotifications) {
      debugPrint(
        "ID: ${notification.id} | Title: ${notification.title} | Body: ${notification.body} | Payload: ${notification.payload}",
      );
    }
    debugPrint("🔔 -----------------------------");
  }

  Future<void> cancelNotification(String deckTitle) async {
    final notificationId = deckTitle.hashCode.abs();
    await _localPlugin.cancel(id: notificationId);
    debugPrint(
      "Cancelled notification for deck: $deckTitle (ID: $notificationId)",
    );
  }

  //4: Save Token to Firestore
  Future<void> _saveToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
