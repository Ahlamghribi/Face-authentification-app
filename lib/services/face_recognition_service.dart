import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../models/face_model.dart';
import 'face_detector_service.dart';
import 'face_embedding_service.dart';

class FaceRecognitionService {
  final FaceDetectorService _faceDetector;
  final FaceEmbeddingService _embeddingService;
  static const double _similarityThreshold = 0.7;
  final _uuid = const Uuid();

  FaceRecognitionService()
      : _faceDetector = FaceDetectorService(),
        _embeddingService = FaceEmbeddingService();

  Future<Face?> processImage(String imagePath, {String? label}) async {
    try {
      // Detect faces in the image
      final faces = await _faceDetector.detectFaces(imagePath);
      if (faces.isEmpty) {
        throw Exception('No face detected in the image');
      }
      if (faces.length > 1) {
        throw Exception('Multiple faces detected. Please use an image with a single face');
      }

      // Crop and process the detected face
      final croppedFace = await _faceDetector.cropFace(imagePath, faces.first);
      if (croppedFace == null) {
        throw Exception('Failed to crop face from image');
      }

      // Extract face embedding
      final embedding = await _embeddingService.extractEmbedding(croppedFace);

      // Create face model
      return Face(
        id: _uuid.v4(),
        label: label ?? 'Unknown',
        embedding: embedding,
        createdAt: DateTime.now(),
        imageData: Uint8List.fromList(img.encodeJpg(croppedFace)),
      );
    } catch (e) {
      print('❌ Error processing face: $e');
      return null;
    }
  }

  Future<bool> compareFaces(Face face1, Face face2) async {
    try {
      final similarity = _embeddingService.compareFaces(
        face1.embedding,
        face2.embedding,
      );
      return similarity >= _similarityThreshold;
    } catch (e) {
      print('❌ Error comparing faces: $e');
      return false;
    }
  }

  Future<Face?> findMatch(Face targetFace, List<Face> registeredFaces) async {
    try {
      Face? bestMatch;
      double highestSimilarity = _similarityThreshold;

      for (final face in registeredFaces) {
        final similarity = _embeddingService.compareFaces(
          targetFace.embedding,
          face.embedding,
        );

        if (similarity > highestSimilarity) {
          highestSimilarity = similarity;
          bestMatch = face;
        }
      }

      return bestMatch;
    } catch (e) {
      print('❌ Error finding face match: $e');
      return null;
    }
  }

  void dispose() {
    _faceDetector.dispose();
    _embeddingService.dispose();
  }
} 