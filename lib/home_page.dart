import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:med4free/profile_page.dart';
import 'login_page.dart';
import 'donor_page.dart';
import 'find_page.dart';
import 'cart_page.dart';
import 'donor_notification_page.dart';
import 'finder_notification_page.dart';
import 'rewards_page.dart';
import 'user_prescriptions_page.dart'; // ✅ Import Prescriptions Page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String fullName = "Loading...";
  String email = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    Future.delayed(Duration.zero, () => showTutorialPopup());
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          fullName = userDoc['fullname'] ?? "No Name";
          email = userDoc['email'] ?? "No Email";
        });
      }
    }
  }

  void showTutorialPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Welcome to Med4Free!'),
          content: const Text(
            '🩺 Use "Donate" to contribute unused medicines.\n\n'
            '🔍 Use "Find" to search for available medicines.\n\n'
            '🛒 Use the cart to manage your selections.\n\n'
            '☰ Use the drawer menu to check your notifications and profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(fullName),
              accountEmail: Text(email),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('assets/profile_image.png'),
              ),
            ),
            ListTile(
              title: const Text("Profile"),
              leading: const Icon(Icons.person, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage()),
                );
              },
            ),
            ListTile(
              title: const Text("View Cart"),
              leading: const Icon(Icons.shopping_cart, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartPage()),
                );
              },
            ),
            ExpansionTile(
              title: const Text("Notifications"),
              leading: const Icon(Icons.notifications, color: Colors.teal),
              children: [
                ListTile(
                  leading: Image.asset('assets/donor_notification.png', width: 30, height: 30),
                  title: const Text("Donor Details"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DonorNotificationPage()),
                    );
                  },
                ),
                ListTile(
                  leading: Image.asset('assets/finder_notification.png', width: 30, height: 30),
                  title: const Text("Finder Details"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FinderNotificationPage()),
                    );
                  },
                ),
              ],
            ),
            ListTile(
              title: const Text("Rewards"),
              leading: const Icon(Icons.card_giftcard, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RewardsPage()),
                );
              },
            ),

            // ✅ Prescriptions menu item
            ListTile(
              title: const Text("Prescriptions"),
              leading: const Icon(Icons.receipt_long, color: Colors.teal),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserPrescriptionsPage()),
                );
              },
            ),

            const Spacer(),

            ListTile(
              title: const Text("Logout"),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/login_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DonorPage()),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/donate.png',
                              height: 150,
                              width: 150,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Donate',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FindPage()),
                          );
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/find.png',
                              height: 150,
                              width: 150,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Find',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: FadeInUp(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DonorPage()),
                                  );
                                },
                                icon: const Icon(
                                  Icons.local_hospital,
                                  size: 35,
                                  color: Colors.red,
                                ),
                              ),
                              const Text(
                                'Donate',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => FindPage()),
                                  );
                                },
                                icon: const Icon(
                                  Icons.search,
                                  size: 35,
                                  color: Colors.red,
                                ),
                              ),
                              const Text(
                                'Find',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => CartPage()),
                                  );
                                },
                                icon: const Icon(
                                  Icons.shopping_cart,
                                  size: 35,
                                  color: Colors.red,
                                ),
                              ),
                              const Text(
                                'Cart',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/app_name.png',
                  height: 60,
                  width: 150,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
