import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhoLikedYouScreen extends StatefulWidget {
  const WhoLikedYouScreen({super.key});

  @override
  State<WhoLikedYouScreen> createState() => _WhoLikedYouScreenState();
}

class _WhoLikedYouScreenState extends State<WhoLikedYouScreen> {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> likedBy = [];

  @override
  void initState() {
    super.initState();
    fetchLikedByUsers();
  }

  Future<void> fetchLikedByUsers() async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    final swipesSnapshot = await FirebaseFirestore.instance
        .collection('swipes')
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in swipesSnapshot.docs) {
      final likerId = doc.id;
      final likedSnapshot = await FirebaseFirestore.instance
          .collection('swipes')
          .doc(likerId)
          .collection('liked')
          .doc(currentUserId)
          .get();

      if (likedSnapshot.exists) {
        final youLikedThem = await FirebaseFirestore.instance
            .collection('swipes')
            .doc(currentUserId)
            .collection('liked')
            .doc(likerId)
            .get();

        if (!youLikedThem.exists) {
          final userDoc = await usersRef.doc(likerId).get();
          if (userDoc.exists) {
            results.add(userDoc.data()!);
          }
        }
      }
    }

    setState(() {
      likedBy = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Who Liked You")),
      body: likedBy.isEmpty
          ? const Center(child: Text("No likes yet..."))
          : ListView.builder(
              itemCount: likedBy.length,
              itemBuilder: (context, index) {
                final user = likedBy[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user['photoUrl'] ?? ''),
                  ),
                  title: Text(user['displayName'] ?? 'Unknown'),
                  subtitle: Text(user['branch'] ?? ''),
                );
              },
            ),
    );
  }
}
