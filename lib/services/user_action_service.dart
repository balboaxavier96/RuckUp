import 'package:cloud_firestore/cloud_firestore.dart';

class UserActionService {
  Future<void> blockUser(String blockerId, String blockedId) async {
    await FirebaseFirestore.instance
        .collection('blocks')
        .doc(blockerId)
        .set({blockedId: true}, SetOptions(merge: true));
  }

  Future<void> reportUser(
      String reporterId, String reportedId, String reason) async {
    final reportData = {
      'reporter': reporterId,
      'reason': reason,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('reports').doc(reportedId).set({
      'reportList': FieldValue.arrayUnion([reportData])
    }, SetOptions(merge: true));
  }

  Future<void> unmatch(String matchId) async {
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId)
        .delete();
  }
}
