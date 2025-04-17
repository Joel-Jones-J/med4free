import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  Future<List<Map<String, dynamic>>> fetchDonorActivityLogs() async {
    final firestore = FirebaseFirestore.instance;
    final rewardSnapshot = await firestore.collection('rewards').get();

    List<Map<String, dynamic>> activities = [];

    for (var rewardDoc in rewardSnapshot.docs) {
      final rewardData = rewardDoc.data();
      final donorEmail = rewardData['donor_email'];

      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: donorEmail)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();

        int points = rewardData['contribution_points'] ?? 0;
        int donationCount = rewardData['donation_count'] ?? 0;
        int medicineDonated = (points / 5).round();

        activities.add({
          'name': userData['fullname'] ?? 'Unknown',
          'email': donorEmail,
          'medicines': medicineDonated,
          'donationCount': donationCount,
          'address': userData['address'] ?? 'N/A',
          'income': userData['income'] ?? 'N/A',
        });
      }
    }

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Page'),
        backgroundColor: Colors.deepPurpleAccent,
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/activity_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),

              ),
              elevation: 10,
              color: Colors.white.withOpacity(0.70),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchDonorActivityLogs(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'No activity data found.',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    }

                    final activities = snapshot.data!;
                    return ListView.builder(
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final donor = activities[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 6,
                          child: ExpansionTile(
                            leading: const Icon(Icons.person, color: Colors.teal),
                            title: Text(
                              donor['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: [
                              ListTile(
                                title: const Text("Medicines Donated Count"),
                                subtitle: Text("${donor['medicines']} medicines"),
                              ),
                              ListTile(
                                title: const Text("Total Donations"),
                                subtitle: Text("${donor['donationCount']} times"),
                              ),
                              ListTile(
                                title: const Text("Address"),
                                subtitle: Text(donor['address']),
                              ),
                              ListTile(
                                title: const Text("Income"),
                                subtitle: Text(donor['income'].toString()),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
