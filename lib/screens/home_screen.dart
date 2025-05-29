import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../services/auth_service.dart';
import '../services/face_auth_service.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _faceAuthService = FaceAuthService();
  final _audioPlayer = AudioPlayer();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _authService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(bool success) async {
    try {
      await _audioPlayer.setAsset(success ? 'assets/sounds/success.mp3' : 'assets/sounds/failure.mp3');
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<XFile?> _getImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    return await picker.pickImage(
      source: source,
      preferredCameraDevice: source == ImageSource.camera ? CameraDevice.front : CameraDevice.rear,
      imageQuality: 100, // Highest quality for better recognition
      maxWidth: 1080, // Limit size while maintaining quality
      maxHeight: 1080,
    );
  }

  Future<void> _updateFaceImage() async {
    final XFile? image = await _getImage(context);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final (success, message) = await _authService.registerFace(
        userId: _authService.currentUserId!,
        imagePath: image.path,
      );

      setState(() {
        _isSuccess = success;
        _message = message;
      });

      await _playSound(success);
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error updating face image: ${e.toString()}';
      });
      await _playSound(false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testFaceRecognition() async {
    final XFile? image = await _getImage(context);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _message = 'Processing face recognition...';
    });

    try {
      final (success, message) = await _faceAuthService.verifyFace(
        _authService.currentUserId!,
        File(image.path),
      );

      setState(() {
        _isSuccess = success;
        _message = message;
      });

      await _playSound(success);
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _message = 'Error during face verification: ${e.toString()}';
      });
      await _playSound(false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _updateFaceImage,
              icon: const Icon(Icons.face),
              label: const Text('Update Face Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testFaceRecognition,
              icon: const Icon(Icons.verified_user),
              label: const Text('Test Face Recognition'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_message != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}