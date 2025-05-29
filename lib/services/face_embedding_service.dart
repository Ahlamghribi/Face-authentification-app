import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FaceEmbeddingService {
  final FaceDetector _faceDetector;
  
  FaceEmbeddingService() : _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      minFaceSize: 0.15,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  Future<img.Image?> preprocessImage(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

      // Convert to InputImage for face detection
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      if (faces.isEmpty) return null;
      
      // Get the first face
      final face = faces.first;
      
      // Crop the face region with padding
      final x = face.boundingBox.left.toInt();
      final y = face.boundingBox.top.toInt();
      final width = face.boundingBox.width.toInt();
      final height = face.boundingBox.height.toInt();

      // Add padding around the face
      final paddingX = (width * 0.2).toInt();
      final paddingY = (height * 0.2).toInt();

      // Ensure coordinates are within image bounds
      final cropX = (x - paddingX).clamp(0, image.width - 1);
      final cropY = (y - paddingY).clamp(0, image.height - 1);
      final cropWidth = (width + (paddingX * 2)).clamp(1, image.width - cropX);
      final cropHeight = (height + (paddingY * 2)).clamp(1, image.height - cropY);

      // Crop and normalize the face image
      final croppedImage = img.copyCrop(
        image,
        cropX,
        cropY,
        cropWidth,
        cropHeight,
      );

      // Resize to a standard size (e.g., 224x224 for many ML models)
      return img.copyResize(croppedImage, width: 224, height: 224);
    } catch (e) {
      print('❌ Error preprocessing image: $e');
      return null;
    }
  }

  Future<List<double>> extractEmbedding(img.Image faceImage) async {
    try {
      // Convert image to InputImage format
      final bytes = Uint8List.fromList(img.encodeJpg(faceImage));
      final tempDir = await getTemporaryDirectory();
      final tempPath = path.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFile(tempFile);
      
      // Detect face landmarks
      final faces = await _faceDetector.processImage(inputImage);
      await tempFile.delete(); // Clean up temp file
      
      if (faces.isEmpty) {
        throw Exception("No face detected in the image");
      }

      // Get the first face's landmarks
      final face = faces.first;
      final landmarks = [
        face.landmarks[FaceLandmarkType.leftEye],
        face.landmarks[FaceLandmarkType.rightEye],
        face.landmarks[FaceLandmarkType.noseBase],
        face.landmarks[FaceLandmarkType.leftMouth],
        face.landmarks[FaceLandmarkType.rightMouth],
      ];

      // Convert landmarks to a normalized embedding
      final embedding = <double>[];
      for (final landmark in landmarks) {
        if (landmark != null) {
          // Normalize coordinates relative to image size
          embedding.add(landmark.position.x / faceImage.width);
          embedding.add(landmark.position.y / faceImage.height);
        } else {
          // Add default values if landmark is not detected
          embedding.add(0.0);
          embedding.add(0.0);
        }
      }

      return _l2Normalize(embedding);
    } catch (e) {
      print('❌ Error extracting face embedding: $e');
      rethrow;
    }
  }

  List<double> _l2Normalize(List<double> embedding) {
    double sum = 0;
    for (var value in embedding) {
      sum += value * value;
    }
    
    final norm = sqrt(sum);
    return embedding.map((x) => x / norm).toList();
  }

  double compareFaces(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception("Embeddings must have the same length");
    }

    double dotProduct = 0;
    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
    }

    return dotProduct.clamp(-1.0, 1.0);
  }

  void dispose() {
    _faceDetector.close();
  }
}

double sqrt(double x) => x <= 0 ? 0.0 : pow(x, 0.5).toDouble(); 