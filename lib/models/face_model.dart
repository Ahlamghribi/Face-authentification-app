import 'dart:typed_data';

class Face {
  final String id;
  final String label;
  final List<double> embedding;
  final DateTime createdAt;
  final Uint8List? imageData;

  Face({
    required this.id,
    required this.label,
    required this.embedding,
    required this.createdAt,
    this.imageData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'embedding': embedding,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Face.fromJson(Map<String, dynamic> json) {
    return Face(
      id: json['id'],
      label: json['label'],
      embedding: List<double>.from(json['embedding']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 