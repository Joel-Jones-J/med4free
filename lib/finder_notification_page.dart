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

class FinderNotificationPage extends StatefulWidget {
  const FinderNotificationPage({super.key});

  @override
  _FinderNotificationPageState createState() => _FinderNotificationPageState();
}

class _FinderNotificationPageState extends State<FinderNotificationPage> {
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

  /// Load app icon
  Future<void> _loadAppLogo() async {
    final ByteData data = await rootBundle.load('assets/app_icon.png');
    setState(() {
      appLogoBytes = data.buffer.asUint8List();
    });
  }

  /// Fetch approved medicine requests for the current finder
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

        // Fetch finder details (fullname, phone) from users collection
        String finderEmail = data['finder_email'] ?? "";
        Map<String, dynamic> finderDetails = await _fetchFinderDetails(finderEmail);

        data['finder_name'] = finderDetails['fullname'];
        data['finder_phone'] = finderDetails['phone'];
        requests.add(data);
      }

      setState(() {
        approvedRequests = requests;
      });
    }
  }

  /// Fetch finder details (fullname, phone) from Firestore based on email
  Future<Map<String, dynamic>> _fetchFinderDetails(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();
      return {
        'fullname': data['fullname'] ?? 'Unknown Finder',
        'phone': data['phone'] ?? 'Not Available',
      };
    }
    return {'fullname': 'Unknown Finder', 'phone': 'Not Available'};
  }

  /// Request storage permissions (for Android)
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
  }

  /// Fetch medicine image
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

  /// Generate & download PDF
  Future<void> _generateAndDownloadPDF(Map<String, dynamic> data) async {
    setState(() => isDownloading = true);

    final pdf = pw.Document();
    Uint8List? medicineImageBytes;
    if (data['imageUrl'] != null && data['imageUrl'].isNotEmpty) {
      medicineImageBytes = await _fetchImage(data['imageUrl']);
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
                "Finder Details",
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
                _tableRow("Finder Name", data['finder_name']),
                _tableRow("Finder Email", data['finder_email']),
                _tableRow("Phone", data['finder_phone']),
              ],
            ),
            pw.SizedBox(height: 15),
            if (medicineImageBytes != null) ...[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(medicineImageBytes),
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
      setState(() => isDownloading = false);
    }
  }

  pw.TableRow _tableRow(String title, dynamic value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: pw.EdgeInsets.all(8),
          child: pw.Text(value?.toString() ?? "Not Available"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        title: const Text("Finder Notifications"),
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
                  margin: const EdgeInsets.all(10),
                  elevation: 5,
                  child: ListTile(
                    title: Text("Medicine: ${data['medicine_name']} (${data['dosage']})"),
                    subtitle: Text("Finder: ${data['finder_name']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () => _generateAndDownloadPDF(data),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
