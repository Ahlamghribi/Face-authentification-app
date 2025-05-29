import 'package:cloud_firestore/cloud_firestore.dart';

class FaceEmbedding {
  final String userId;
  final List<double> embedding;
  final DateTime updatedAt;

  FaceEmbedding({
    required this.userId,
    required this.embedding,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'embedding': embedding,
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  factory FaceEmbedding.fromMap(String id, Map<String, dynamic> map) {
    return FaceEmbedding(
      userId: id,
      embedding: List<double>.from(map['embedding'] ?? []),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
} 