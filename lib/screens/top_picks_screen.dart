import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TopPicksScreen extends StatefulWidget {
  const TopPicksScreen({super.key});

  @override
  State<TopPicksScreen> createState() => _TopPicksScreenState();
}

class _TopPicksScreenState extends State<TopPicksScreen> {
  List<Map<String, dynamic>> topPicks = [];
  String? currentUserId;
  Map<String, dynamic>? currentUserData;

  @override
  void initState() {
    super.initState();
    _loadTopPicks();
  }

  Future<void> _loadTopPicks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    currentUserId = user.uid;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();

    if (!userDoc.exists) return;

    currentUserData = userDoc.data();

    final branch = currentUserData?['branch'];
    final dutyStation = currentUserData?['dutyStation'];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('branch', isEqualTo: branch)
        .where('dutyStation', isEqualTo: dutyStation)
        .get();

    final results = querySnapshot.docs.where((doc) {
      if (doc.id == currentUserId) return false;
      final data = doc.data();
      return data['verified'] == true || (data['interests'] ?? []).contains('fitness');
    }).map((doc) {
      return {
        ...doc.data(),
        'uid': doc.id,
      };
    }).toList();

    setState(() {
      topPicks = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Picks')),
      body: topPicks.isEmpty
          ? const Center(child: Text("No top picks yet..."))
          : ListView.builder(
              itemCount: topPicks.length,
              itemBuilder: (context, index) {
                final user = topPicks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['photoUrl'] ?? ''),
                    ),
                    title: Text(user['displayName'] ?? 'Unknown'),
                    subtitle: Text(
                      '${user['branch'] ?? ''} • ${user['dutyStation'] ?? ''}',
                    ),
                    trailing: user['verified'] == true
                        ? const Icon(Icons.verified, color: Colors.blue)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}
