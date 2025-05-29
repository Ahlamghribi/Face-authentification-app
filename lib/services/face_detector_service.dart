import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class FaceDetectorService {
  final FaceDetector _faceDetector;
  static const double _minFaceConfidence = 0.6;

  FaceDetectorService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            enableClassification: true,
            enableTracking: true,
            minFaceSize: 0.15,
            performanceMode: FaceDetectorMode.accurate,
          ),
        );

  Future<List<Face>> detectFaces(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final faces = await _faceDetector.processImage(inputImage);
    return faces.toList();
  }

  Future<img.Image?> cropFace(String imagePath, Face face) async {
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) return null;

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

      return img.copyCrop(
        image,
        cropX,
        cropY,
        cropWidth,
        cropHeight,
      );
    } catch (e) {
      print('Error cropping face: $e');
      return null;
    }
  }

  void dispose() {
    _faceDetector.close();
  }
} 