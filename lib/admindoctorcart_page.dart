import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';  // Import Lottie package
import 'prescription_view_page.dart'; // Import the prescription view page

class AdminDoctorCartPage extends StatefulWidget {
  const AdminDoctorCartPage({super.key});

  @override
  _AdminDoctorCartPageState createState() => _AdminDoctorCartPageState();
}

class _AdminDoctorCartPageState extends State<AdminDoctorCartPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> cartRequests = [];
  Map<String, String> donorNames = {};
  bool isApproving = false; // Flag to control Lottie animation

  @override
  void initState() {
    super.initState();
    _fetchCartRequests();
  }

  Future<void> _fetchCartRequests() async {
    try {
      final snapshot = await _firestore
          .collection('request_cart')
          .orderBy('timestamp', descending: true)
          .get();

      List<DocumentSnapshot> validCartDocs = [];
      Set<String> donorEmails = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>? ?? {};
        String? quantity = data['quantity']?.toString();

        if (quantity == null || quantity == '0') {
          await _firestore.collection('request_cart').doc(doc.id).delete();
          continue;
        }

        validCartDocs.add(doc);

        if (data.containsKey('donor_email')) {
          donorEmails.add(data['donor_email']);
        }
      }

      if (donorEmails.isNotEmpty) {
        final userSnapshots = await _firestore
            .collection('users')
            .where('email', whereIn: donorEmails.toList())
            .get();

        for (var userDoc in userSnapshots.docs) {
          donorNames[userDoc['email']] = userDoc['fullname'] ?? 'Unknown';
        }
      }

      setState(() {
        cartRequests = validCartDocs;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Cart Data Approval"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/doc_bg1.png",
              fit: BoxFit.cover,
            ),
          ),
          cartRequests.isEmpty
              ? _buildShimmerLoading()
              : ListView.builder(
                  itemCount: cartRequests.length,
                  itemBuilder: (context, index) {
                    var cartData = cartRequests[index];
                    var data = cartData.data() as Map<String, dynamic>? ?? {};

                    return _buildCartItem(
                      cartData.id,
                      data['donor_email'] ?? 'Unknown',
                      data['dosage']?.toString() ?? 'N/A',
                      data['medicine_name'] ?? 'Unknown',
                      data['quantity']?.toString() ?? '0',
                      data['imageUrl'] ?? '',
                      data['finder_email'] ?? 'Unknown',
                      index,
                    );
                  },
                ),
          if (isApproving)
            Center(
              child: Lottie.asset(
                'assets/lottie/added_to_cart.json',  //Custom Lottie file here
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: const ListTile(
                leading: CircleAvatar(backgroundColor: Colors.white, radius: 25),
                title: SizedBox(height: 10, width: 80, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
                subtitle: SizedBox(height: 10, width: 50, child: DecoratedBox(decoration: BoxDecoration(color: Colors.white))),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartItem(
    String docId,
    String donorEmail,
    String dosage,
    String medicineName,
    String quantity,
    String imageUrl,
    String finderEmail,
    int index,
  ) {
    String donorName = donorNames[donorEmail] ?? 'Unknown';

    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Column(
        children: [
          ListTile(
            leading: GestureDetector(
              onTap: () => _showImageDialog(imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image(
                    image: (imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true)
                        ? NetworkImage(imageUrl)
                        : const AssetImage('assets/noimg.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Text("$medicineName ($dosage)", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Donor: $donorName\nQuantity: $quantity"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                  onPressed: () => _approveCartRequest(docId, donorEmail, donorName, dosage, medicineName, quantity, imageUrl, finderEmail, index),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                  onPressed: () => _rejectCartRequest(docId, index),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0, bottom: 10),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrescriptionViewPage(finderEmail: finderEmail),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long),
                label: const Text("View Prescription"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _approveCartRequest(
    String docId,
    String donorEmail,
    String donorName,
    String dosage,
    String medicineName,
    String quantity,
    String imageUrl,
    String finderEmail,
    int index,
  ) async {
    setState(() {
      isApproving = true;  // Show Lottie animation when approval is in progress
    });

    try {
      await _firestore.collection('approved_cart').doc(docId).set({
        'donor_email': donorEmail,
        'donor_name': donorName,
        'dosage': dosage,
        'medicine_name': medicineName,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'finder_email': finderEmail,
        'status': 'Approved',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('request_cart').doc(docId).delete();

      setState(() {
        cartRequests.removeAt(index);
        isApproving = false;  // Hide Lottie animation after approval
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Approved and Removed"), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("Error approving request: $e");
      setState(() {
        isApproving = false;  // Hide Lottie animation if error occurs
      });
    }
  }

  Future<void> _rejectCartRequest(String docId, int index) async {
    try {
      await _firestore.collection('request_cart').doc(docId).delete();

      setState(() {
        cartRequests.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Rejected"), backgroundColor: Colors.red),
      );
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Image.network(imageUrl, fit: BoxFit.contain),
      ),
    );
  }
}
