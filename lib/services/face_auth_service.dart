import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../config/firebase_config.dart';
import '../models/face_embedding.dart';
import 'face_embedding_service.dart';

class FaceAuthService {
  final _firestore = FirebaseFirestore.instance;
  final _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.15,
    ),
  );
  final _embeddingService = FaceEmbeddingService();
  final _audioPlayer = AudioPlayer();

  Future<(bool, String)> registerFace(String userId, File imageFile) async {
    try {
      print('Starting face registration for user: $userId');
      print('Image file path: ${imageFile.path}');
      print('Image file exists: ${await imageFile.exists()}');
      print('Image file size: ${await imageFile.length()} bytes');
      
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      print('Detected ${faces.length} faces in the image');
      
      if (faces.isEmpty) {
        return (false, 'No face detected in the image. Please try again with a clearer photo.');
      }
      
      if (faces.length > 1) {
        return (false, 'Multiple faces detected. Please use an image with a single face.');
      }

      // Process the image and get face embedding
      print('Processing face image...');
      final faceImage = await _embeddingService.preprocessImage(imageFile);
      if (faceImage == null) {
        return (false, 'Failed to process face image. Please try again with a different photo.');
      }

      print('Extracting face embedding...');
      final embeddingList = await _embeddingService.extractEmbedding(faceImage);
      
      if (embeddingList.isEmpty) {
        return (false, 'Failed to extract face features. Please try again with a clearer photo.');
      }
      
      print('Creating face embedding model...');
      final faceEmbedding = FaceEmbedding(
        userId: userId,
        embedding: embeddingList,
        updatedAt: DateTime.now(),
      );
      
      print('Storing face embedding in Firestore...');
      // Store face embedding in Firestore
      await _firestore
          .collection(FirebaseConfig.faceEmbeddingsCollection)
          .doc(userId)
          .set(faceEmbedding.toMap(), SetOptions(merge: true));
      
      print('Face registration completed successfully');
      return (true, 'Face registered successfully!');
    } catch (e, stackTrace) {
      print('Error registering face: $e');
      print('Stack trace: $stackTrace');
      return (false, 'An error occurred while registering face. Please try again.');
    }
  }

  Future<(bool, String)> verifyFace(String userId, File newImageFile) async {
    try {
      print('Starting face verification for user: $userId');
      
      // Get stored face embedding
      print('Fetching stored embedding from Firestore...');
      final doc = await _firestore
          .collection(FirebaseConfig.faceEmbeddingsCollection)
          .doc(userId)
          .get();
      
      if (!doc.exists) {
        print('No face embedding found for user: $userId');
        return (false, 'No registered face found for this user');
      }
      
      final storedFaceEmbedding = FaceEmbedding.fromMap(userId, doc.data()!);
      print('Retrieved stored embedding with length: ${storedFaceEmbedding.embedding.length}');
      
      // Process new image and get embedding
      print('Processing new face image...');
      final faceImage = await _embeddingService.preprocessImage(newImageFile);
      if (faceImage == null) {
        return (false, 'Failed to process face image. Please try again with a different photo.');
      }

      print('Extracting new face embedding...');
      final newEmbedding = await _embeddingService.extractEmbedding(faceImage);
      print('New embedding extracted with length: ${newEmbedding.length}');
      
      // Compare embeddings
      print('Comparing face embeddings...');
      final similarity = _embeddingService.compareFaces(newEmbedding, storedFaceEmbedding.embedding);
      print('Face similarity score: $similarity');
      
      final result = similarity >= 0.7; // Adjust threshold as needed
      print('Verification result: $result');
      
      // Play appropriate sound
      await _playSound(result);
      
      return (result, result ? 'Face verified successfully!' : 'Face verification failed. Please try again.');
    } catch (e, stackTrace) {
      print('Error verifying face: $e');
      print('Stack trace: $stackTrace');
      return (false, 'An error occurred while verifying face. Please try again.');
    }
  }

  Future<void> _playSound(bool success) async {
    try {
      if (success) {
        await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/failure.mp3'));
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  void dispose() {
    _faceDetector.close();
    _audioPlayer.dispose();
  }
} 
