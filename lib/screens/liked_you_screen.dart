import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';

class LikedYouScreen extends StatefulWidget {
  const LikedYouScreen({super.key});

  @override
  State<LikedYouScreen> createState() => _LikedYouScreenState();
}

class _LikedYouScreenState extends State<LikedYouScreen> {
  List<Map<String, dynamic>> users = [];
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadLikedUsers();
  }

  Future<void> _loadLikedUsers() async {
    final currentUserId = AuthService().currentUserId;
    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    isPremium = userDoc.data()?['isPremium'] == true;

    if (!isPremium) {
      return;
    }

    final reverseLikesDoc = await FirebaseFirestore.instance
        .collection('reverse_likes')
        .doc(currentUserId)
        .get();
    if (!reverseLikesDoc.exists) return;

    final likedByIds = reverseLikesDoc.data()?.keys.toList() ?? [];

    final likedDocs = await Future.wait(
      likedByIds.map(
          (id) => FirebaseFirestore.instance.collection('users').doc(id).get()),
    );

    setState(() {
      users = likedDocs
          .where((doc) => doc.exists)
          .map((doc) => {
                ...doc.data()!,
                'uid': doc.id,
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(title: const Text('Who Liked You')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/subscribe'),
            child: const Text('Upgrade to Premium to See Who Liked You'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Who Liked You')),
      body: users.isEmpty
          ? const Center(child: Text('No one has liked you yet.'))
          : ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  leading: user['profileImage'] != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(user['profileImage']))
                      : const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Text(user['branch'] ?? ''),
                  trailing: user['verified'] == true
                      ? const Icon(Icons.verified, color: Colors.blue)
                      : null,
                );
              },
            ),
    );
  }
}
