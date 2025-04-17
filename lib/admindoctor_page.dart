import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDoctorPage extends StatelessWidget {
  const AdminDoctorPage({super.key});

  /// Approve a donation and move it to 'approved_donations', add to rewards
  Future<void> approveDonation(BuildContext context, String docId, Map<String, dynamic> data) async {
    try {
      Map<String, dynamic> donationData = Map.from(data);
      donationData.remove('timestamp');

      donationData['quantity'] = int.tryParse(donationData['quantity'].toString()) ?? 0;

      final donorEmail = donationData['donor_email'] ?? 'Unknown';
      final timestamp = FieldValue.serverTimestamp();

      // Add to approved_donations
      await FirebaseFirestore.instance.collection('approved_donations').doc(docId).set({
        ...donationData,
        'donor_email': donorEmail,
        'timestamp': timestamp,
      });

      // Add to rewards
      await FirebaseFirestore.instance.collection('rewards').add({
        'donor_email': donorEmail,
        'donation_count': 1,
        'contribution_points': 10,
        'timestamp': timestamp,
      });

      // Add to notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'email': donorEmail,
        'medicine_name': donationData['medicine_name'] ?? 'Unknown',
        'status': 'Approved',
        'timestamp': timestamp,
      });

      // Delete from donations
      await FirebaseFirestore.instance.collection('donations').doc(docId).delete();

      debugPrint('✅ Donation approved and moved to approved_donations and rewards');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation approved successfully'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('❌ Error approving donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Reject a donation and notify donor
  Future<void> rejectDonation(BuildContext context, String docId) async {
    try {
      DocumentSnapshot donationSnapshot =
          await FirebaseFirestore.instance.collection('donations').doc(docId).get();

      if (!donationSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Donation not found!'), backgroundColor: Colors.red),
        );
        return;
      }

      Map<String, dynamic>? data = donationSnapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      final donorEmail = data['donor_email'] ?? 'Unknown';
      final medicineName = data['medicine_name'] ?? 'Unknown';

      // Delete donation
      await FirebaseFirestore.instance.collection('donations').doc(docId).delete();

      // Notify rejection
      await FirebaseFirestore.instance.collection('notifications').add({
        'email': donorEmail,
        'medicine_name': medicineName,
        'status': 'Rejected',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('❌ Donation rejected and donor notified');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation rejected successfully'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      debugPrint('❌ Error rejecting donation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Show full image in a dialog
  void showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: false,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 3.0,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Doctor Panel'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/doc_bg1.png',
              fit: BoxFit.cover,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('donations').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Error fetching data"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No donations available.'));
              }

              var donations = snapshot.data!.docs;

              return ListView.builder(
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  var donation = donations[index];
                  var data = donation.data() as Map<String, dynamic>?;

                  if (data == null) return const SizedBox();

                  final medicineName = data['medicine_name'] ?? 'Unknown';
                  final quantity = int.tryParse(data['quantity']?.toString() ?? '0') ?? 0;
                  final dosage = data['dosage'] ?? 'N/A';
                  final expiryDate = data['expiry_date'] ?? 'N/A';
                  final imageUrl = data['image_url'] ?? '';

                  return Card(
                    margin: const EdgeInsets.all(10),
                    color: Colors.white.withOpacity(0.85),
                    child: ListTile(
                      leading: imageUrl.isNotEmpty
                          ? GestureDetector(
                              onTap: () => showFullImage(context, imageUrl),
                              child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.medical_services, size: 50),
                      title: Text(medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Quantity: $quantity'),
                          Text('Dosage: $dosage'),
                          Text('Expiry Date: $expiryDate'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => approveDonation(context, donation.id, data),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => rejectDonation(context, donation.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
