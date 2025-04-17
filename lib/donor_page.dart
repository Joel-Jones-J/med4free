import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class DonorPage extends StatefulWidget {
  const DonorPage({super.key});

  @override
  _DonorPageState createState() => _DonorPageState();
}

class _DonorPageState extends State<DonorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String? _expiryDate;
  File? _image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTutorialDialog();
    });
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Welcome Donor!", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTutorialLine(Icons.medical_services, "Enter the medicine name, dosage, and quantity."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.calendar_today, "Pick the expiry date of the medicine."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.image, "Upload a clear image of the medicine."),
            SizedBox(height: 10),
            _buildTutorialLine(Icons.check_circle, "Tap the submit button to complete donation."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Got it!", style: TextStyle(color: Colors.teal)),
          )
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
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    const String apiKey = "63d3c1f2c1cc5d49ccd7ea0f6a464ae0";
    final Uri uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var response = await http.post(
        uri,
        body: {"image": base64Image},
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['data']['url'];
      } else {
        print("Error uploading image: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception while uploading: $e");
      return null;
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _expiryDate = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate() && _expiryDate != null && _image != null) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        String? userEmail = user?.email;

        if (userEmail == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("User not authenticated")),
          );
          return;
        }

        String? uploadedImageUrl = await _uploadImageToImgBB(_image!);
        if (uploadedImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Image upload failed")),
          );
          return;
        }

        String medicineName = _medicineNameController.text.trim().toLowerCase();
        int? quantity = int.tryParse(_quantityController.text.trim());
        if (quantity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please enter a valid quantity")),
          );
          return;
        }

        // Save all data including contribution points in the same 'donations' collection
        await FirebaseFirestore.instance.collection('donations').add({
          'donor_email': userEmail,
          'medicine_name': medicineName,
          'dosage': _dosageController.text.trim(),
          'expiry_date': _expiryDate,
          'quantity': quantity,
          'image_url': uploadedImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'donation_count': 1,
          'contribution_points': quantity * 5,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Donation Submitted Successfully")),
        );

        setState(() {
          _medicineNameController.clear();
          _dosageController.clear();
          _quantityController.clear();
          _expiryDate = null;
          _image = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving data: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/login_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Top-right App Logo
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset(
              "assets/app_name.png",
              width: 100,
            ),
          ),

          // Page Content
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              children: [
                SizedBox(height: 10),
                Image.asset(
                  "assets/donate_word.png",
                  width: 668,
                  height: 92,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 30),

                // Form Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 6,
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(_medicineNameController, "Medicine Name", Icons.medical_services),
                          _buildTextField(_dosageController, "Dosage (Enter only the dose)", Icons.healing),
                          _buildExpiryDateField(),
                          _buildTextField(_quantityController, "Quantity", Icons.format_list_numbered),
                          SizedBox(height: 15),

                          Text("Upload Tablet Image:", style: TextStyle(fontSize: 16)),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: _pickImage,
                            child: _image == null
                                ? Icon(Icons.camera_alt, size: 40, color: Colors.teal)
                                : Image.file(_image!, width: 100, height: 100),
                          ),
                          SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _submitData,
                              child: Text("Submit"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        validator: (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  Widget _buildExpiryDateField() {
    return Padding(
      padding: EdgeInsets.only(bottom: 15),
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Expiry Date",
          prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onTap: () => _selectExpiryDate(context),
        controller: TextEditingController(text: _expiryDate ?? ""),
        validator: (value) => _expiryDate == null ? "Select an expiry date" : null,
      ),
    );
  }
}
