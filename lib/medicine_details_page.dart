import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'user_prescriptions_page.dart'; // Make sure this file exists

class MedicineDetailsPage extends StatefulWidget {
  final Map<String, dynamic> medicineData;

  const MedicineDetailsPage({super.key, required this.medicineData});

  @override
  _MedicineDetailsPageState createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> donationList = [];
  Map<String, int> selectedQuantities = {};
  Map<String, String> donorNames = {};
  Map<String, String> donorEmails = {};
  Map<String, int> availableStockMap = {};
  String expandedCardId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatchingDonations();
  }

  Future<void> _fetchMatchingDonations() async {
    try {
      QuerySnapshot donationsSnapshot = await firestore
          .collection('approved_donations')
          .where('medicine_name', isEqualTo: widget.medicineData['medicine_name'])
          .where('dosage', isEqualTo: widget.medicineData['dosage'])
          .get();

      setState(() {
        donationList = donationsSnapshot.docs;
        for (var doc in donationList) {
          int availableStock = (doc['quantity'] is int)
              ? doc['quantity']
              : int.tryParse(doc['quantity'].toString()) ?? 0;
          availableStockMap[doc.id] = availableStock;
          selectedQuantities[doc.id] = (availableStock > 0) ? 1 : 0;
          donorEmails[doc.id] = doc['donor_email'];
        }
        isLoading = false;
      });

      for (var doc in donationList) {
        String donorEmail = doc['donor_email'];
        _fetchDonorName(donorEmail, doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching donations: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchDonorName(String email, String docId) async {
    try {
      QuerySnapshot userSnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        setState(() {
          donorNames[docId] = userSnapshot.docs.first['fullname'] ?? "Unknown Donor";
        });
      }
    } catch (e) {
      debugPrint("Error fetching donor name: $e");
    }
  }

  Future<void> _addToCart(DocumentSnapshot medicineDoc, int selectedQuantity) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      int currentStock = availableStockMap[medicineDoc.id] ?? 0;
      if (selectedQuantity > currentStock) return;

      await firestore.collection('cart_data').add({
        'medicine_name': medicineDoc['medicine_name'],
        'quantity': selectedQuantity,
        'dosage': medicineDoc['dosage'],
        'userId': user.uid,
        'finder_email': user.email,
        'donor_email': donorEmails[medicineDoc.id],
        'imageUrl': medicineDoc['image_url'],
        'timestamp': FieldValue.serverTimestamp(),
      });

      int updatedStock = currentStock - selectedQuantity;

      if (updatedStock > 0) {
        await firestore.collection('approved_donations').doc(medicineDoc.id).update({'quantity': updatedStock});
        setState(() {
          availableStockMap[medicineDoc.id] = updatedStock;
          selectedQuantities[medicineDoc.id] = 1;
        });
      } else {
        await firestore.collection('approved_donations').doc(medicineDoc.id).delete();
        setState(() {
          donationList.removeWhere((item) => item.id == medicineDoc.id);
          availableStockMap.remove(medicineDoc.id);
          selectedQuantities.remove(medicineDoc.id);
        });
      }

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to cart!"), backgroundColor: Colors.green),
      );

      // Show prescription popup
      _showPrescriptionPopup();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showPrescriptionPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Upload Prescription"),
          content: const Text("Please upload your prescription to continue."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text("Upload", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserPrescriptionsPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text("Available Medicines"),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : donationList.isEmpty
              ? const Center(child: Text("No matching medicines available.", style: TextStyle(fontSize: 18)))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: donationList.length,
                  itemBuilder: (context, index) {
                    var medicineDoc = donationList[index];
                    int availableStock = availableStockMap[medicineDoc.id] ?? 0;
                    int selectedQuantity = selectedQuantities[medicineDoc.id] ?? 1;
                    String donorName = donorNames[medicineDoc.id] ?? "Fetching...";
                    bool isExpanded = expandedCardId == medicineDoc.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          expandedCardId = isExpanded ? "" : medicineDoc.id;
                        });
                      },
                      child: FadeInUp(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          padding: const EdgeInsets.all(15),
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.teal.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: isExpanded ? 150 : 80,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    medicineDoc['image_url'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Text("Medicine: ${medicineDoc['medicine_name']}",
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              Text("Available: $availableStock", style: const TextStyle(fontSize: 18)),

                              if (isExpanded) ...[
                                const Divider(color: Colors.teal),
                                Text("Donor: $donorName", style: const TextStyle(fontSize: 18)),

                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.teal),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: DropdownButton<int>(
                                    value: selectedQuantity,
                                    isExpanded: true,
                                    underline: Container(),
                                    items: List.generate(
                                      availableStock,
                                      (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1}")),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedQuantities[medicineDoc.id] = value!;
                                      });
                                    },
                                  ),
                                ),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => _addToCart(medicineDoc, selectedQuantity),
                                  child: const Text("Add to Cart", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
