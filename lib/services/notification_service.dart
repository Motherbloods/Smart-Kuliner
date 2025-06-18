// services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart/managers/user_manager.dart';
import 'package:smart/models/notifikasi.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Initialize FCM
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM permission granted');
      } else {
        print('❌ FCM permission denied');
      }

      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        print('✅ FCM Token: $token');
        // Save token to user document for sending notifications
        await _savetokenFCM(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        print('🔄 FCM Token refreshed: $newToken');
        _savetokenFCM(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Handle app opened from terminated state
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      print('❌ Error initializing FCM: $e');
    }
  }

  // Save FCM token to user document
  Future<void> _savetokenFCM(String token) async {
    try {
      // You'll need to get current user ID from your auth service
      // This is a placeholder - replace with actual user ID
      String? userId = await _getCurrentUserId();

      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'tokenFCM': token,
          'lastTokenUpdate': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  Future<void> deleteTokenFCM() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {
            'fcmToken': FieldValue.delete(),
            'fcmTokenUpdatedAt': FieldValue.delete(),
          },
        );
        print('🗑️ Token FCM removed from Firestore for user: $userId');
      }
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  // Get current user ID (replace with your auth implementation)
  Future<String?> _getCurrentUserId() async {}

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Received foreground message: ${message.notification?.title}');

    // You can show a custom notification or update UI here
    // For example, show a snackbar or update a notification counter
  }

  // Handle background messages
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📱 Received background message: ${message.notification?.title}');

    // Handle background message processing here
    // This runs in a separate isolate
  }

  // Handle notification taps
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');

    // Navigate to appropriate screen based on notification data
    // You'll need to implement navigation logic here
    String? type = message.data['type'];
    String? orderId = message.data['orderId'];

    switch (type) {
      case 'new_order':
      case 'order_status_update':
        // Navigate to order details screen
        _navigateToOrderDetails(orderId);
        break;
      default:
        // Navigate to notifications screen
        _navigateToNotifications();
        break;
    }
  }

  // Navigation methods (implement based on your routing)
  void _navigateToOrderDetails(String? orderId) {
    // Implement navigation to order details
    print('Navigate to order details: $orderId');
  }

  void _navigateToNotifications() {
    // Implement navigation to notifications screen
    print('Navigate to notifications');
  }

  // Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('❌ User not found: $userId');
        return;
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      String? tokenFCM = userData['tokenFCM'];

      if (tokenFCM == null) {
        print('❌ FCM token not found for user: $userId');
        return;
      }

      // Send FCM notification
      await _sendFCMNotification(
        token: tokenFCM,
        title: title,
        body: body,
        data: data ?? {},
      );

      print('✅ Notification sent to user: $userId');
    } catch (e) {
      print('❌ Error sending notification to user: $e');
    }
  }

  // Send notification to seller
  Future<void> sendNotificationToSeller({
    required String sellerId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await sendNotificationToUser(
      userId: sellerId,
      title: title,
      body: body,
      data: data,
    );
  }

  // Send FCM notification using HTTP API
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // You'll need to replace this with your actual FCM server key
      const String serverKey = 'YOUR_FCM_SERVER_KEY';

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': 1,
          },
          'data': data,
          'priority': 'high',
          'content_available': true,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ FCM notification sent successfully');
      } else {
        print('❌ Failed to send FCM notification: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending FCM notification: $e');
    }
  }

  // Get notifications for user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      print('✅ Notification marked as read: $notificationId');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      print('✅ All notifications marked as read for user: $userId');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // Clear all notifications for user
  Future<void> clearAllNotifications(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      WriteBatch batch = _firestore.batch();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ All notifications cleared for user: $userId');
    } catch (e) {
      print('❌ Error clearing all notifications: $e');
    }
  }
}
