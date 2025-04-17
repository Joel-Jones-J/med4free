import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:lottie/lottie.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, bool> selectedItems = {};
  bool isLoading = false;
  bool shipmentRequested = false;

  Future<void> _addSelectedToShipment() async {
    setState(() {
      isLoading = true;
      shipmentRequested = false;
    });

    try {
      var selectedCartItems = selectedItems.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedCartItems.isEmpty) {
        _showSnackbar("No items selected.");
        setState(() => isLoading = false);
        return;
      }

      for (var cartItemId in selectedCartItems) {
        var cartItemDoc = await FirebaseFirestore.instance
            .collection("cart_data")
            .doc(cartItemId)
            .get();
        if (cartItemDoc.exists) {
          var cartItem = cartItemDoc.data();
          if (cartItem != null) {
            await FirebaseFirestore.instance.collection("request_cart").add({
              "userId": user!.uid,
              "medicine_name": cartItem['medicine_name'] ?? '',
              "dosage": cartItem['dosage'] ?? 'N/A',
              "quantity": cartItem['quantity'] ?? 'N/A',
              "imageUrl": cartItem['imageUrl'] ?? '',
              "donor_email": cartItem['donor_email'] ?? 'Unknown',
              "finder_email": user!.email ?? 'Unknown',
              "timestamp": FieldValue.serverTimestamp(),
            });
            await FirebaseFirestore.instance
                .collection("cart_data")
                .doc(cartItemId)
                .delete();
          }
        }
      }

      setState(() {
        selectedItems.clear();
        shipmentRequested = true;
      });

      await Future.delayed(const Duration(seconds: 3)); // Show animation for a while

      _showSnackbar("Shipment requested successfully!");
    } catch (e) {
      _showSnackbar("Failed to send shipment request.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteSelectedItems() async {
    setState(() => isLoading = true);
    try {
      var selectedCartItems = selectedItems.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (selectedCartItems.isEmpty) {
        _showSnackbar("No items selected.");
        setState(() => isLoading = false);
        return;
      }

      for (var cartItemId in selectedCartItems) {
        var cartItemDoc = await FirebaseFirestore.instance
            .collection("cart_data")
            .doc(cartItemId)
            .get();
        if (cartItemDoc.exists) {
          var cartItem = cartItemDoc.data();
          if (cartItem != null) {
            await FirebaseFirestore.instance
                .collection("approved_donations")
                .add({
              "medicine_name": cartItem['medicine_name'] ?? '',
              "dosage": cartItem['dosage'] ?? 'N/A',
              "quantity": cartItem['quantity'] ?? 'N/A',
              "imageUrl": cartItem['imageUrl'] ?? '',
              "timestamp": FieldValue.serverTimestamp(),
            });
            await FirebaseFirestore.instance
                .collection("cart_data")
                .doc(cartItemId)
                .delete();
          }
        }
      }

      setState(() => selectedItems.clear());
      _showSnackbar("Items moved to approved donations.");
    } catch (e) {
      _showSnackbar("Failed to delete items.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _showFullImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text("Your Cart",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.teal,
            elevation: 4,
            centerTitle: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          body: user == null
              ? const Center(child: Text("Error: User not found."))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("cart_data")
                      .where("userId", isEqualTo: user!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("Your cart is empty.",
                              style: TextStyle(fontSize: 18)));
                    }

                    var cartItems = snapshot.data!.docs;

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              var cartItem = cartItems[index].data()
                                      as Map<String, dynamic>? ??
                                  {};
                              String medicineName =
                                  cartItem['medicine_name'] ?? 'No Name';
                              String cartItemId = cartItems[index].id;
                              bool isSelected =
                                  selectedItems[cartItemId] ?? false;

                              return FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                child: Card(
                                  elevation: isSelected ? 10 : 3,
                                  color: isSelected
                                      ? Colors.teal.shade50
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15)),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: GestureDetector(
                                      onTap: () {
                                        if (cartItem['imageUrl'] != null &&
                                            cartItem['imageUrl'].isNotEmpty) {
                                          _showFullImageDialog(
                                              context, cartItem['imageUrl']);
                                        }
                                      },
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: (cartItem['imageUrl'] != null &&
                                                cartItem['imageUrl'].isNotEmpty)
                                            ? Image.network(
                                                cartItem['imageUrl'],
                                                width: 55,
                                                height: 55,
                                                fit: BoxFit.cover)
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 50),
                                      ),
                                    ),
                                    title: Text(medicineName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Dosage: ${cartItem['dosage'] ?? 'N/A'}\nQuantity: ${cartItem['quantity'] ?? 'N/A'}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      activeColor: Colors.teal,
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() => selectedItems[
                                            cartItemId] = value ?? false);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 10)
                              ],
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                shipmentRequested
                                    ? BounceIn(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                              Icons.check_circle_outline),
                                          label:
                                              const Text("Requested ✅"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                          ),
                                          onPressed: null,
                                        ),
                                      )
                                    : ElevatedButton.icon(
                                        icon: const Icon(
                                            Icons.local_shipping_rounded),
                                        label: isLoading
                                            ? const Text("Requesting...")
                                            : const Text("Receive Medicine"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        onPressed: isLoading
                                            ? null
                                            : _addSelectedToShipment,
                                      ),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text("Delete"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed:
                                      isLoading ? null : _deleteSelectedItems,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Lottie.asset(
                'assets/lottie/box_delivery.json',
                width: 250,
                height: 250,
              ),
            ),
          ),
      ],
    );
  }
}
