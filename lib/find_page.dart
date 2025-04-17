import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medicine_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key});

  @override
  _FindPageState createState() => _FindPageState();
}

class _FindPageState extends State<FindPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  bool _loading = false;
  bool _isEligible = false;
  bool _checkingEligibility = true;
  final int salaryThreshold = 400000;

  @override
  void initState() {
    super.initState();
    _checkUserEligibility();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  Future<void> _checkUserEligibility() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String salaryString = userDoc['income'] ?? '0';
          int salary = int.tryParse(salaryString) ?? 0;

          setState(() {
            _isEligible = salary < salaryThreshold;
            _checkingEligibility = false;
          });
        } else {
          setState(() {
            _checkingEligibility = false;
          });
        }
      } catch (e) {
        setState(() {
          _checkingEligibility = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error checking eligibility: $e")),
        );
      }
    } else {
      setState(() {
        _checkingEligibility = false;
      });
    }
  }

  Future<void> _searchMedicine() async {
    String searchQuery = _searchController.text.trim().toLowerCase();
    String dosageQuery = _dosageController.text.trim();
    User? user = FirebaseAuth.instance.currentUser;

    if (searchQuery.isEmpty || dosageQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter medicine name and dosage")),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You need to be logged in to search.")),
      );
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('approved_donations')
          .where('medicine_name', isEqualTo: searchQuery)
          .where('dosage', isEqualTo: dosageQuery)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var medicineData = querySnapshot.docs.first.data() as Map<String, dynamic>;

        await FirebaseFirestore.instance.collection('request_cart').add({
          'finder_email': user.email,
          'medicine_name': searchQuery,
          'dosage': dosageQuery,
          'timestamp': FieldValue.serverTimestamp(),
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MedicineDetailsPage(medicineData: medicineData),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No medicine found with this name and dosage.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 10),
        contentPadding: EdgeInsets.all(20),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.teal, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "How to Use Find Page",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.teal,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTutorialLine(Icons.search, "Enter the medicine name."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.medical_services, "Provide the correct dosage (e.g., 500(don't enter mg))."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.verified_user, "Make sure you're eligible based on your income."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.check_circle_outline, "Click the Search button to proceed."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Got it!", style: TextStyle(color: Colors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.teal),
        SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: Image.asset(
              'assets/app_name.png',
              height: 50,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeInUp(
                    duration: Duration(milliseconds: 500),
                    child: Image.asset(
                      'assets/find_word.png',
                      height: 50,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 600),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Medicine...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 700),
                    child: TextField(
                      controller: _dosageController,
                      decoration: InputDecoration(
                        hintText: 'Enter Dosage (e.g., 500)',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(Icons.medical_services, color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInUp(
                    duration: Duration(milliseconds: 900),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: (_loading || !_isEligible) ? null : _searchMedicine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _loading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Search',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                        ),
                        if (!_isEligible && !_checkingEligibility)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'You are not eligible to find medicine.',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
