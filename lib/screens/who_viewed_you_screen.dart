import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WhoViewedYouScreen extends StatefulWidget {
  const WhoViewedYouScreen({super.key});

  @override
  State<WhoViewedYouScreen> createState() => _WhoViewedYouScreenState();
}

class _WhoViewedYouScreenState extends State<WhoViewedYouScreen> {
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> viewedBy = [];

  @override
  void initState() {
    super.initState();
    fetchViewers();
  }

  Future<void> fetchViewers() async {
    final viewsSnapshot = await FirebaseFirestore.instance
        .collection('profile_views')
        .doc(currentUserId)
        .collection('viewedBy')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> results = [];

    for (var doc in viewsSnapshot.docs) {
      final userId = doc.id;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        results.add(userDoc.data()!);
      }
    }

    setState(() {
      viewedBy = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Who Viewed You")),
      body: viewedBy.isEmpty
          ? const Center(child: Text("No one has viewed you yet..."))
          : ListView.builder(
              itemCount: viewedBy.length,
              itemBuilder: (context, index) {
                final user = viewedBy[index];
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
