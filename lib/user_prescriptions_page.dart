import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserPrescriptionsPage extends StatefulWidget {
  const UserPrescriptionsPage({super.key});

  @override
  State<UserPrescriptionsPage> createState() => _UserPrescriptionsPageState();
}

class _UserPrescriptionsPageState extends State<UserPrescriptionsPage> {
  final picker = ImagePicker();
  final List<String> _imageUrls = [];
  final String imgbbApiKey = '63d3c1f2c1cc5d49ccd7ea0f6a464ae0';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadPrescriptionsFromFirestore();
  }

  Future<void> pickAndUploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await uploadImageToImgbb(imageFile);
    }
  }

  Future<void> loadPrescriptionsFromFirestore() async {
    final email = _auth.currentUser?.email ?? "unknown";

    final snapshot = await _firestore
        .collection('prescriptions')
        .where('email', isEqualTo: email)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _imageUrls.clear();
      _imageUrls.addAll(snapshot.docs.map((doc) => doc['imageUrl'] as String));
    });
  }

  Future<void> uploadImageToImgbb(File imageFile, {int? replaceIndex}) async {
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
    final base64Image = base64Encode(imageFile.readAsBytesSync());

    final response = await http.post(uri, body: {'image': base64Image});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final imageUrl = data['data']['url'];
      final email = _auth.currentUser?.email ?? "unknown";

      if (replaceIndex != null) {
        setState(() {
          _imageUrls[replaceIndex] = imageUrl;
        });
        await updatePrescriptionInFirestore(replaceIndex, imageUrl, email);
      } else {
        setState(() {
          _imageUrls.insert(0, imageUrl); // add to top
        });
        await savePrescriptionToFirestore(imageUrl, email);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(replaceIndex != null ? "Image updated" : "Image uploaded")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image")),
      );
    }
  }

  Future<void> savePrescriptionToFirestore(String imageUrl, String email) async {
    await _firestore.collection('prescriptions').add({
      'imageUrl': imageUrl,
      'email': email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePrescriptionInFirestore(int index, String imageUrl, String email) async {
    final snapshot = await _firestore
        .collection('prescriptions')
        .where('email', isEqualTo: email)
        .orderBy('timestamp', descending: true)
        .get();

    if (index < snapshot.docs.length) {
      final docId = snapshot.docs[index].id;
      await _firestore.collection('prescriptions').doc(docId).update({
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _openImageView(String imageUrl, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImagePreviewPage(
          imageUrl: imageUrl,
          onDelete: () async {
            final email = _auth.currentUser?.email ?? "unknown";

            final snapshot = await _firestore
                .collection('prescriptions')
                .where('email', isEqualTo: email)
                .orderBy('timestamp', descending: true)
                .get();

            if (index < snapshot.docs.length) {
              final docId = snapshot.docs[index].id;
              await _firestore.collection('prescriptions').doc(docId).delete();
            }

            setState(() {
              _imageUrls.removeAt(index);
            });

            Navigator.pop(context);
          },
          onEdit: () async {
            final pickedFile = await picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              final imageFile = File(pickedFile.path);
              await uploadImageToImgbb(imageFile, replaceIndex: index);
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Prescriptions"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              "Upload your doctor prescription report",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: _imageUrls.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GestureDetector(
                    onTap: pickAndUploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            "Add Prescription",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => _openImageView(_imageUrls[index - 1], index - 1),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(_imageUrls[index - 1]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ImagePreviewPage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ImagePreviewPage({
    super.key,
    required this.imageUrl,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription View'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit),
                label: const Text("Edit"),
              ),
              ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete),
                label: const Text("Delete"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
