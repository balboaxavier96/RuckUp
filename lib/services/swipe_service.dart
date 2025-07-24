import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SwipeService {
  static Map<String, dynamic>? lastSwipedProfile;

  static void saveLastSwipe(Map<String, dynamic> profileData) {
    lastSwipedProfile = profileData;
  }

  static Map<String, dynamic>? getLastSwipe() {
    return lastSwipedProfile;
  }

  static void clearLastSwipe() {
    lastSwipedProfile = null;
  }

  // ----- Swipe Limit -----
  static const int maxDailySwipes = 50;

  static Future<int> getSwipesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('swipeDate') ?? '';
    final count = prefs.getInt('swipeCount') ?? 0;

    if (lastDate != today) {
      await prefs.setString('swipeDate', today);
      await prefs.setInt('swipeCount', 0);
      return 0;
    }

    return count;
  }

  static Future<void> incrementSwipeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getSwipesToday();
    await prefs.setInt('swipeCount', count + 1);
  }

  static Future<bool> isSwipeLimitReached() async {
    final count = await getSwipesToday();
    return count >= maxDailySwipes;
  }

  static Future<void> resetDailySwipes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('swipeCount', 0);
  }

  // ----- Super Like Limit -----
  static const int maxDailySuperLikes = 1;

  static Future<int> getSuperLikesToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('superLikeDate') ?? '';
    final count = prefs.getInt('superLikeCount') ?? 0;

    if (lastDate != today) {
      await prefs.setString('superLikeDate', today);
      await prefs.setInt('superLikeCount', 0);
      return 0;
    }

    return count;
  }

  static Future<void> incrementSuperLikeCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = await getSuperLikesToday();
    await prefs.setInt('superLikeCount', count + 1);
  }

  static Future<bool> isSuperLikeLimitReached() async {
    final count = await getSuperLikesToday();
    return count >= maxDailySuperLikes;
  }

  static Future<void> resetDailySuperLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('superLikeCount', 0);
  }

  // ----- View Tracking -----
  static Future<void> logProfileView(String viewedUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || currentUserId == viewedUserId) return;

    await FirebaseFirestore.instance
        .collection('profile_views')
        .doc(viewedUserId)
        .collection('viewedBy')
        .doc(currentUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }
}
