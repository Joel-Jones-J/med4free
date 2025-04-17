import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> loginUser(String email, String password) async {
    try {
      // Sign in the user using Firebase Authentication
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user ID after authentication
      String uid = userCredential.user!.uid;

      // Check if user exists in Firestore (Optional)
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        print("Login Successful: ${userCredential.user!.email}");
        return true;
      } else {
        print("User data not found in Firestore");
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print("Login Failed: ${e.message}");
      return false;
    }
  }
}
