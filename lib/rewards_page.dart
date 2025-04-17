import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  Map<String, dynamic> getRewardTier(int donations) {
    if (donations >= 10) {
      return {
        'title': 'Gold Hero',
        'description': 'Completed 10+ donations',
        'icon': '🥇',
        'color': Colors.amber.shade100,
      };
    } else if (donations >= 5) {
      return {
        'title': 'Silver Supporter',
        'description': 'Completed 5+ donations',
        'icon': '🥈',
        'color': Colors.grey.shade200,
      };
    } else if (donations >= 1) {
      return {
        'title': 'Bronze Contributor',
        'description': 'Completed 1+ donation',
        'icon': '🥉',
        'color': Colors.brown.shade100,
      };
    } else {
      return {
        'title': 'No Rewards Yet',
        'description': 'Make your first donation!',
        'icon': '⛔',
        'color': Colors.red.shade100,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Rewards',
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amberAccent,
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/reward_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          user == null
              ? const Center(child: Text("Please login to view your rewards."))
              : FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('rewards')
                      .where('donor_email', isEqualTo: user.email)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No reward data found."));
                    }

                    final data = snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    final int donations = data['donation_count'] ?? 0;
                    final int contribution = data['contribution_points'] ?? 0;

                    final reward = getRewardTier(donations);

                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          color: reward['color'],
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  reward['icon'],
                                  style: const TextStyle(fontSize: 48),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  reward['title'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  reward['description'],
                                  style: GoogleFonts.poppins(fontSize: 16),
                                ),
                                const Divider(height: 32, thickness: 1.5),
                                Text(
                                  'Your Stats',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.volunteer_activism,
                                            color: Colors.teal),
                                        const SizedBox(height: 4),
                                        Text('$donations Donations',
                                            style: GoogleFonts.poppins()),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.star,
                                            color: Colors.orange),
                                        const SizedBox(height: 4),
                                        Text('$contribution Points',
                                            style: GoogleFonts.poppins()),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
