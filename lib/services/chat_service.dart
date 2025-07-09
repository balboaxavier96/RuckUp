import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ Add this for sending notifications
import 'dart:async';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get messages stream
  Stream<List<Map<String, dynamic>>> getMessages(String matchId) {
    return _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // ✅ Send a message and optional notification
  Future<void> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    String? recipientId, // Add this if you want to trigger FCM
  }) async {
    await _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Reset typing status
    await setTypingStatus(matchId, null);

    // Optional: Trigger FCM
    if (recipientId != null) {
      await sendNotification(recipientId, text);
    }
  }

  // ✅ Send FCM notification via Cloud Function
  Future<void> sendNotification(String toUserId, String message) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(toUserId).get();
    final token = userDoc.data()?['fcmToken'];

    if (token != null) {
      await FirebaseFunctions.instance
          .httpsCallable('sendPushNotification')
          .call({'token': token, 'message': message});
    }
  }

  // ✅ Typing status stream
  Stream<String?> typingStatus(String matchId) {
    return _firestore
        .collection('typing_status')
        .doc(matchId)
        .snapshots()
        .map((doc) => doc.data()?['typing'] as String?);
  }

  // ✅ Set typing status (userId or null)
  Future<void> setTypingStatus(String matchId, String? userId) async {
    await _firestore
        .collection('typing_status')
        .doc(matchId)
        .set({'typing': userId});
  }
}
