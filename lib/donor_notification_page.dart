import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class DonorNotificationPage extends StatefulWidget {
  const DonorNotificationPage({super.key});

  @override
  _DonorNotificationPageState createState() => _DonorNotificationPageState();
}

class _DonorNotificationPageState extends State<DonorNotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> approvedRequests = [];
  bool isDownloading = false;
  Uint8List? appLogoBytes;

  @override
  void initState() {
    super.initState();
    _fetchApprovedRequests();
    _loadAppLogo();
  }

  Future<void> _loadAppLogo() async {
    final ByteData data = await rootBundle.load('assets/app_icon.png'); 
    setState(() {
      appLogoBytes = data.buffer.asUint8List();
    });
  }

  Future<void> _fetchApprovedRequests() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _firestore
          .collection('approved_cart')
          .where('finder_email', isEqualTo: user.email)
          .get();

      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();

        String donorEmail = data['donor_email'];
        var userSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: donorEmail)
            .limit(1)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          data['donor_phone'] = userSnapshot.docs.first['phone'];
        } else {
          data['donor_phone'] = "Not Available";
        }

        requests.add(data);
      }

      setState(() {
        approvedRequests = requests;
      });
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  Future<Uint8List?> _fetchImage(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      print("Error fetching image: $e");
    }
    return null;
  }

  Future<void> _generateAndDownloadPDF(Map<String, dynamic> data) async {
    setState(() => isDownloading = true);  // Start loading animation

    final pdf = pw.Document();
    Uint8List? donorImageBytes;
    if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty) {
      donorImageBytes = await _fetchImage(data['imageUrl']);
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (appLogoBytes != null)
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(appLogoBytes!),
                  width: 150,
                  height: 150,
                ),
              ),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                "Approved Medicine Request",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(width: 1),
              columnWidths: {
                0: pw.FlexColumnWidth(1),
                1: pw.FlexColumnWidth(2),
              },
              children: [
                _tableRow("Medicine", "${data['medicine_name']} (${data['dosage']})"),
                _tableRow("Quantity", data['quantity'].toString()),
                _tableRow("Donor Name", data['donor_name']),
                _tableRow("Donor Email", data['donor_email']),
                _tableRow("Donor Phone", data['donor_phone']),
              ],
            ),
            pw.SizedBox(height: 15),
            if (donorImageBytes != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(donorImageBytes),
                  width: 200,
                  height: 200,
                ),
              ),
              pw.SizedBox(height: 15),
            ],
            pw.Divider(),
            pw.Text(
              "Generated on: ${DateTime.now()}",
              style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
            ),
          ],
        ),
      ),
    );

    try {
      await _requestPermissions();
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Failed to get storage directory");
      }

      final filePath = "${directory.path}/${data['medicine_name']}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("PDF downloaded to $filePath")),
      );

      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isDownloading = false); // Stop loading animation
    }
  }

  pw.TableRow _tableRow(String title, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        title: const Text("Donor Details"),
        backgroundColor: Colors.teal[700],
      ),
      body: approvedRequests.isEmpty
          ? const Center(
              child: Text(
                "No approved requests found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          : ListView.builder(
              itemCount: approvedRequests.length,
              itemBuilder: (context, index) {
                var data = approvedRequests[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                  color: Colors.white,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Center(
                          child: Text(
                            "${data['medicine_name']} (${data['dosage']})",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text("Donor Name: ${data['donor_name']}"),
                        subtitle: Text("Phone: ${data['donor_phone']}"),
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.download),
                            label: const Text("Download PDF"),
                            onPressed: isDownloading ? null : () => _generateAndDownloadPDF(data),
                          ),
                          if (isDownloading)
                            const CircularProgressIndicator(),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
