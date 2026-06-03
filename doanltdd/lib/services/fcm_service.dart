import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Handler cho background message (phải là top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Xử lý message khi app ở background/terminated
  debugPrint('Background message: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> init(String uid) async {
    // Đăng ký background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Xin quyền (bắt buộc trên iOS, khuyến nghị trên Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('FCM permission denied');
      return;
    }

    // Lấy và lưu FCM token
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    // Refresh token tự động
    _fcm.onTokenRefresh.listen((newToken) {
      _saveToken(uid, newToken);
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
    });

    // Khi user tap notification từ background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notification tapped: ${message.data}');
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  /// Xóa token khi logout (tránh nhận notification sau khi đăng xuất)
  Future<void> clearToken(String uid) async {
    await _fcm.deleteToken();
    await _db.collection('users').doc(uid).update({
      'fcmToken': FieldValue.delete(),
    });
  }
}