import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? currentUserId = AuthService().currentUserId;

  Map<String, dynamic>? otherUserData;
  late Stream<String?> _typingStream;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    loadOtherUser();
    checkIfBlocked();
    _typingStream = _chatService.typingStatus(widget.matchId);
  }

  Future<void> loadOtherUser() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .get();

    if (!mounted) return;

    if (doc.exists) {
      setState(() {
        otherUserData = doc.data();
      });
    }
  }

  Future<void> checkIfBlocked() async {
    final doc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(widget.otherUserId)
        .get();

    final hasBlockedMe = doc.exists && doc.data()?[currentUserId] == true;

    final myDoc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(currentUserId)
        .get();

    final iBlockedThem =
        myDoc.exists && myDoc.data()?[widget.otherUserId] == true;

    if (!mounted) return;

    setState(() {
      _isBlocked = hasBlockedMe || iBlockedThem;
    });
  }

  Future<void> _blockUser() async {
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('blocks')
        .doc(currentUserId)
        .set({widget.otherUserId: true}, SetOptions(merge: true));

    await _unmatchUser(); // Optionally delete match + chat

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User blocked')),
    );

    Navigator.of(context).pop();
  }

  Future<void> _reportUser() async {
    if (currentUserId == null) return;

    String selectedReason = 'Inappropriate Content';

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Report User'),
            content: DropdownButton<String>(
              isExpanded: true,
              value: selectedReason,
              items: const [
                DropdownMenuItem(
                    value: 'Inappropriate Content',
                    child: Text('Inappropriate Content')),
                DropdownMenuItem(
                    value: 'Harassment', child: Text('Harassment')),
                DropdownMenuItem(
                    value: 'Scam/Fraud', child: Text('Scam/Fraud')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => selectedReason = value!),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, selectedReason),
                  child: const Text('Report')),
            ],
          ),
        );
      },
    );

    if (reason == null) return;

    final reportEntry = {
      'reporter': currentUserId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('reports')
        .doc(widget.otherUserId)
        .set({
      'reportList': FieldValue.arrayUnion([reportEntry])
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User reported')),
    );
  }

  Future<void> _unmatchUser() async {
    if (currentUserId == null) return;

    final matchId1 = '${currentUserId}_${widget.otherUserId}';
    final matchId2 = '${widget.otherUserId}_$currentUserId';

    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId1)
        .delete();
    await FirebaseFirestore.instance
        .collection('matches')
        .doc(matchId2)
        .delete();

    final chatId = [currentUserId, widget.otherUserId]..sort();
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId.join('_'))
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unmatched')),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    _chatService.sendMessage(
      matchId: widget.matchId,
      senderId: currentUserId!,
      text: text,
    );

    _controller.clear();
    _chatService.setTypingStatus(widget.matchId, null);
  }

  Future<void> _sendFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      final file = result.files.first;

      if (file.bytes == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_files/${widget.matchId}/${file.name}');

      await storageRef.putData(file.bytes!);
      final url = await storageRef.getDownloadURL();

      await _chatService.sendMessage(
        matchId: widget.matchId,
        senderId: currentUserId!,
        text: '[image] $url',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (otherUserData?['profileImage'] != null)
              CircleAvatar(
                backgroundImage: NetworkImage(otherUserData!['profileImage']),
              )
            else
              const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Text(otherUserData?['branch'] ?? widget.otherUserId),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'block') {
                await _blockUser();
              } else if (value == 'report') {
                await _reportUser();
              } else if (value == 'unmatch') {
                await _unmatchUser();
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'block', child: Text('Block User')),
              const PopupMenuItem(value: 'report', child: Text('Report User')),
              const PopupMenuItem(value: 'unmatch', child: Text('Unmatch')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatService.getMessages(widget.matchId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == currentUserId;

                    return Row(
                      mainAxisAlignment: isMe
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        if (!isMe && otherUserData?['profileImage'] != null)
                          CircleAvatar(
                            radius: 14,
                            backgroundImage:
                                NetworkImage(otherUserData!['profileImage']),
                          ),
                        if (!isMe) const SizedBox(width: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: msg['text'].startsWith('[image]')
                              ? Image.network(
                                  msg['text'].replaceFirst('[image] ', ''),
                                  width: 180,
                                )
                              : Text(msg['text']),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Typing indicator
          StreamBuilder<String?>(
            stream: _typingStream,
            builder: (_, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data != currentUserId) {
                return const Padding(
                  padding: EdgeInsets.only(left: 16.0),
                  child:
                      Text('Typing...', style: TextStyle(color: Colors.grey)),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Input or block warning
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isBlocked
                ? const Text(
                    'You cannot send messages to this user.',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w500),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          onChanged: (val) {
                            _chatService.setTypingStatus(widget.matchId,
                                val.isNotEmpty ? currentUserId : null);
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _sendFile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
