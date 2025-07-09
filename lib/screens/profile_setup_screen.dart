import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import 'selfie_verification_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _dutyStationController = TextEditingController();
  File? _imageFile;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;

    String? imageUrl;

    if (_imageFile != null) {
      final ref =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'bio': _bioController.text.trim(),
      'branch': _branchController.text.trim(),
      'dutyStation': _dutyStationController.text.trim(),
      'profileImage': imageUrl ?? '',
      'location': GeoPoint(position.latitude, position.longitude),
      'verified': false,
      'isPremium': false,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved!')),
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _uploadSelfie() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile == null) return;

    final currentUserId = AuthService().currentUserId;
    final storageRef =
        FirebaseStorage.instance.ref().child('selfies/$currentUserId.jpg');

    await storageRef.putFile(File(pickedFile.path));
    final selfieUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
      'selfieUrl': selfieUrl,
      'verificationStatus': 'pending',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Selfie uploaded. Awaiting verification.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child:
                    _imageFile == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _dutyStationController,
              decoration: const InputDecoration(
                labelText: 'Duty Station',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitProfile,
              child: const Text('Save Profile'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SelfieVerificationScreen()),
                );
              },
              child: const Text("Verify Profile"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadSelfie,
              child: const Text('Upload Selfie for Verification'),
            ),
          ],
        ),
      ),
    );
  }
}
