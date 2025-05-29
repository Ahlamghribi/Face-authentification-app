import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        // TODO: Replace with your Firebase configuration
        apiKey: 'AIzaSyBvkHQEHd0TVkBb_ywhAPMWj-jYJ8Ryipc',
        appId: '1:822178388719:android:202c9d5961f99621ab991a',
        messagingSenderId: '822178388719',
        projectId: 'face-recognition-ddd84',
      ),
    );
  }

  // Collection names
  static const String usersCollection = 'users';
  static const String faceEmbeddingsCollection = 'face_embeddings';
} 