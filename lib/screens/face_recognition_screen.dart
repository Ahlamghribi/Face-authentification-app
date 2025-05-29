import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/face_model.dart';
import '../services/face_recognition_service.dart';

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final FaceRecognitionService _recognitionService = FaceRecognitionService();
  final List<Face> _registeredFaces = [];
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registerFace() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final face = await _recognitionService.processImage(
        image.path,
        label: _nameController.text.trim(),
      );

      if (face != null) {
        setState(() {
          _registeredFaces.add(face);
          _nameController.clear();
        });
        _showSuccessMessage('Face registered successfully!');
      } else {
        _showErrorMessage('Failed to process face. Please try again.');
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recognizeFace() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final face = await _recognitionService.processImage(image.path);
      if (face == null) {
        _showErrorMessage('Failed to process face. Please try again.');
        return;
      }

      final match = await _recognitionService.findMatch(face, _registeredFaces);
      if (match != null) {
        _showSuccessMessage('Welcome back, ${match.label}!');
      } else {
        _showErrorMessage('Face not recognized. Please register first.');
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition Demo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter name for registration',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _registerFace,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Register Face'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _recognizeFace,
                    icon: const Icon(Icons.face),
                    label: const Text('Recognize Face'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Registered Faces: ${_registeredFaces.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _registeredFaces.length,
                      itemBuilder: (context, index) {
                        final face = _registeredFaces[index];
                        return ListTile(
                          leading: face.imageData != null
                              ? Image.memory(face.imageData!, height: 50, width: 50)
                              : const Icon(Icons.face),
                          title: Text(face.label),
                          subtitle: Text('Registered: ${face.createdAt.toString()}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    _nameController.dispose();
    super.dispose();
  }
} 