import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = AuthService().currentUserId!;
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.getNotifications(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(child: Text("No notifications yet"));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (_, i) {
              return ListTile(
                title: Text(notifications[i]['message']),
                subtitle: Text(notifications[i]['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
