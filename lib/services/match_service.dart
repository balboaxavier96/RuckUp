import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class MatchService {
  final _likesRef = FirebaseFirestore.instance.collection('likes');
  final _reverseLikesRef =
      FirebaseFirestore.instance.collection('reverse_likes');
  final _matchesRef = FirebaseFirestore.instance.collection('matches');

  Future<void> likeUser(String currentUserId, String targetUserId) async {
    final likeDocId = '${currentUserId}_$targetUserId';
    final reverseLikeDocId = '${targetUserId}_$currentUserId';

    // ✅ Step 1: Store the like
    await _likesRef.doc(likeDocId).set({
      'likerId': currentUserId,
      'likedId': targetUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Step 2: Store reverse like for "who liked me"
    await _reverseLikesRef.doc(targetUserId).set({
      currentUserId: true,
    }, SetOptions(merge: true));

    // ✅ Step 3: Check for mutual like
    final reverseLike = await _likesRef.doc(reverseLikeDocId).get();

    if (reverseLike.exists) {
      final matchId = currentUserId.compareTo(targetUserId) < 0
          ? '${currentUserId}_$targetUserId'
          : '${targetUserId}_$currentUserId';

      await _matchesRef.doc(matchId).set({
        'users': [currentUserId, targetUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ✅ Step 4: Trigger Match Notifications
      final notificationService = NotificationService();

      await notificationService.addNotification(
        targetUserId,
        "You’ve matched with $currentUserId!",
      );

      await notificationService.addNotification(
        currentUserId,
        "You’ve matched with $targetUserId!",
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getMatches(String userId) {
    return _matchesRef
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<List<Map<String, dynamic>>> getMatchesWithLastMessage(
      String userId) async {
    final matchesSnapshot =
        await _matchesRef.where('users', arrayContains: userId).get();

    List<Map<String, dynamic>> matchesWithPreview = [];

    for (var doc in matchesSnapshot.docs) {
      final matchId = doc.id;

      final lastMsgSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      final lastMsg = lastMsgSnapshot.docs.isNotEmpty
          ? lastMsgSnapshot.docs.first.data()['text']
          : '';

      final matchData = doc.data();
      matchData['lastMessage'] = lastMsg;

      matchesWithPreview.add(matchData);
    }

    return matchesWithPreview;
  }
}
