import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> addNotification(String receiverId, String message) async {
    await _firestore.collection('notifications').doc(receiverId).collection('feed').add({
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('feed')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
