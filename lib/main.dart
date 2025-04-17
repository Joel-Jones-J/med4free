import 'dart:developer'; // Import for logging
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:med4free/welcome_page.dart';
import 'firebase_options.dart'; // Import Firebase configuration

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter initializes before async calls

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    log("✅ Firebase initialized successfully"); // Logging instead of print

    // Start listening for new donations
    listenForNewDonations();

  } catch (e) {
    log("❌ Error initializing Firebase: $e", error: e); // Use log() instead of print()
  }

  runApp(const MyApp()); // Start Flutter app
}

/// Listen for new donations in Firestore
void listenForNewDonations() {
  FirebaseFirestore.instance.collection('donations').snapshots().listen((snapshot) {
    for (var doc in snapshot.docChanges) {
      if (doc.type == DocumentChangeType.added) {
        var data = doc.doc.data();
        log("📢 New donation added: ${data?['medicine_name'] ?? 'Unknown'} by ${data?['donor_email'] ?? 'Unknown'}");
      }
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const WelcomePage(), // Set WelcomePage as the first screen
    );
  }
}
