// ... imports remain the same
import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

import '../services/match_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  final void Function() onToggleTheme;

  const HomeScreen({required this.onToggleTheme, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchService _matchService = MatchService();
  final CardSwiperController _controller = CardSwiperController();
  final List<Map<String, dynamic>> _swipeHistory = [];
  List<Map<String, dynamic>> userProfiles = [];
  int _swipesToday = 0;
  final int _maxFreeSwipes = 50;
  bool _isPremium = false;
  bool _showVerifiedOnly = false; // ✅ New Toggle

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    _loadSwipeCount();
    _loadProfiles();
  }

  Future<void> _checkPremiumStatus() async {
    final currentUserId = AuthService().currentUserId;
    if (currentUserId == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!mounted) return;

    setState(() {
      _isPremium = userDoc.data()?['isPremium'] == true;
    });
  }

  double _distanceBetween(GeoPoint a, GeoPoint b) {
    const R = 6371;
    double dLat = (b.latitude - a.latitude) * pi / 180;
    double dLon = (b.longitude - a.longitude) * pi / 180;
    double lat1 = a.latitude * pi / 180;
    double lat2 = b.latitude * pi / 180;

    double aValue =
        pow(sin(dLat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dLon / 2), 2);
    double c = 2 * atan2(sqrt(aValue), sqrt(1 - aValue));
    return R * c;
  }

  Future<void> _loadSwipeCount() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('swipes').doc(uid).get();
    final today = DateTime.now();

    if (doc.exists) {
      final data = doc.data()!;
      final lastDate = (data['date'] as Timestamp).toDate();

      if (lastDate.year == today.year &&
          lastDate.month == today.month &&
          lastDate.day == today.day) {
        setState(() {
          _swipesToday = data['count'] ?? 0;
        });
      }
    }
  }

  Future<void> _loadProfiles() async {
    final currentUserId = AuthService().currentUserId;
    if (currentUserId == null) return;

    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!currentUserDoc.exists) return;

    final branch = currentUserDoc['branch'];
    final dutyStation = currentUserDoc['dutyStation'];
    final currentUserLoc = currentUserDoc['location'] as GeoPoint?;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('branch', isEqualTo: branch)
        .where('dutyStation', isEqualTo: dutyStation)
        .get();

    final filtered = query.docs.where((doc) {
      if (doc.id == currentUserId) return false;
      final loc = doc['location'] as GeoPoint?;
      if (currentUserLoc == null || loc == null) return false;

      final distanceOk = _distanceBetween(currentUserLoc, loc) < 50;
      final verifiedOk = !_showVerifiedOnly || doc['verified'] == true;

      return distanceOk && verifiedOk;
    }).map((doc) {
      final data = doc.data();
      final loc = data['location'] as GeoPoint?;
      final distance = (loc != null && currentUserLoc != null)
          ? _distanceBetween(currentUserLoc, loc)
          : null;
      return {
        ...data,
        'uid': doc.id,
        'distanceKm': distance?.toStringAsFixed(1),
      };
    }).toList();

    if (mounted) {
      setState(() {
        userProfiles = filtered;
      });
    }
  }

  Future<void> _handleRewind() async {
    if (!_isPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upgrade to Premium to use Rewind')),
      );
      return;
    }

    if (_swipeHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recent swipe to rewind')),
      );
      return;
    }

    final lastProfile = _swipeHistory.removeLast();

    setState(() {
      userProfiles.insert(0, lastProfile);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Swipe undone')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Matches'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
                _showVerifiedOnly ? Icons.verified : Icons.verified_outlined),
            tooltip: _showVerifiedOnly
                ? 'Showing Verified Only'
                : 'Show Only Verified',
            onPressed: () async {
              final currentUserId = AuthService().currentUserId;
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .get();
              final isPremium = userDoc.data()?['isPremium'] == true;

              if (!isPremium) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Upgrade to Premium to filter by verified only')),
                );
                return;
              }

              setState(() {
                _showVerifiedOnly = !_showVerifiedOnly;
                _loadProfiles();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'RuckUp Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Who Liked You'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/liked-you');
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Matches'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/matches');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                // Logout action here
              },
            ),
          ],
        ),
      ),
      body: userProfiles.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : CardSwiper(
              controller: _controller,
              cardsCount: userProfiles.length,
              numberOfCardsDisplayed: 3,
              isLoop: false,
              onSwipe: (previousIndex, currentIndex, direction) async {
                final targetUser = userProfiles[previousIndex];
                final currentUserId = AuthService().currentUserId;

                if (!mounted) return false;

                if (!_isPremium && _swipesToday >= _maxFreeSwipes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Free swipe limit reached. Upgrade to swipe more.'),
                    ),
                  );
                  return false;
                }

                _swipeHistory.add(targetUser);
                _swipesToday++;

                await FirebaseFirestore.instance
                    .collection('swipes')
                    .doc(currentUserId)
                    .set({
                  'count': _swipesToday,
                  'date': Timestamp.fromDate(DateTime.now()),
                });

                if (direction == CardSwiperDirection.right &&
                    currentUserId != null &&
                    targetUser['uid'] != null) {
                  await _matchService.likeUser(
                      currentUserId, targetUser['uid']);
                }

                return true;
              },
              cardBuilder: (context, index) {
                final user = userProfiles[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Column(
                    children: [
                      user['profileImage'] != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: Image.network(
                                user['profileImage'],
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const SizedBox(height: 250),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user['branch'] ?? 'Unknown Branch',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (user['verified'] == true)
                                  const Icon(Icons.verified,
                                      color: Colors.blue, size: 18),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Duty Station: ${user['dutyStation'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Text(user['bio'] ?? ''),
                            if (user['distanceKm'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '📍 ${user['distanceKm']} km away',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'rewind',
            tooltip: 'Rewind',
            onPressed: _handleRewind,
            child: const Icon(Icons.undo),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'matches',
            tooltip: 'Matches',
            onPressed: () {
              Navigator.pushNamed(context, '/matches');
            },
            child: const Icon(Icons.chat),
          ),
        ],
      ),
    );
  }
}
