import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _audioPlayer = AudioPlayer();
  String? _faceImagePath;
  bool _isLoading = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      imageQuality: 100,
      maxWidth: 1080,
      maxHeight: 1080,
    );
  }

  Future<void> _captureImage() async {
    final XFile? image = await _getImage(context);
    if (image != null) {
      setState(() => _faceImagePath = image.path);
    }
  }

  Future<void> _register() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      await _playSound(false);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      await _playSound(false);
      return;
    }

    if (_faceImagePath == null) {
      setState(() => _errorMessage = 'Please capture a face image');
      await _playSound(false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Creating account...';
    });

    try {
      // Step 1: Create Firebase Auth account
      setState(() => _statusMessage = 'Creating user account...');
      final response = await _authService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.user != null) {
        // Step 2: Register face
        setState(() => _statusMessage = 'Processing face image...');
        final (success, message) = await _authService.registerFace(
          userId: response.user!.uid,
          imagePath: _faceImagePath!,
        );

        if (success) {
          if (!mounted) return;
          setState(() => _statusMessage = message);
          
          // Small delay to show success message
          await Future.delayed(const Duration(seconds: 1));
          
          if (!mounted) return;
          await _playSound(true);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          setState(() {
            _errorMessage = message;
            _statusMessage = null;
          });
          
          // Delete the created user account if face registration fails
          await response.user?.delete();
          await _playSound(false);
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to create account';
          _statusMessage = null;
        });
        await _playSound(false);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: ${e.toString()}';
        _statusMessage = null;
      });
      await _playSound(false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_faceImagePath == null ? 'Capture Face Image' : 'Recapture Face Image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (_faceImagePath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_faceImagePath!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (_statusMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _statusMessage!,
                style: const TextStyle(color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Processing...'),
                        ],
                      )
                    : const Text('Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 