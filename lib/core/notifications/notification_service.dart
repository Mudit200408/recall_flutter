import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  //4: Save Token to Firestore
  Future<void> _saveToken(String userId, String token) async {
    await _firestore.collection('user').doc(userId).set({
      'fcmToken': token,
      'lastLogin': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.toString(),
    }, SetOptions(merge: true));
  }
}
