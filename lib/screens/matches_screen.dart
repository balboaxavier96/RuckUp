import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/match_service.dart';
import 'chat_screen.dart'; // ✅ Import the chat screen

class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUserId;
    final MatchService matchService = MatchService();

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Matches')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: matchService.getMatches(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No matches yet'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final users = match['users'] as List;
              final otherUserId = users.firstWhere((id) => id != userId);

              return ListTile(
                title: Text('Matched with: $otherUserId'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        matchId: users.join('_'), // ✅ Construct chat ID like uid1_uid2
                        otherUserId: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
