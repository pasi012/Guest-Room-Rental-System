import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guest_house_rental_system/guest/guest_registration_screen.dart';
import 'package:intl/intl.dart';

class RegisteredGuestsScreen extends StatefulWidget {
  const RegisteredGuestsScreen({super.key});

  @override
  State<RegisteredGuestsScreen> createState() => _RegisteredGuestsScreenState();
}

class _RegisteredGuestsScreenState extends State<RegisteredGuestsScreen> {
  void _deleteGuest(String guestId) {
    FirebaseFirestore.instance.collection('Guests').doc(guestId).delete();
  }

  void _updateGuest(DocumentSnapshot guest) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => GuestRegistrationScreen(
    //       guest: guest, // Pass the guest data to the registration screen for updating
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Guests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Guests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final guests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: guests.length,
            itemBuilder: (context, index) {
              final guest = guests[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade200,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      guest['name'] ?? 'Unnamed Guest',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.teal,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${guest['contact'] ?? 'N/A'}'),
                          Text('NIC: ${guest['idNo'] ?? 'N/A'}'),
                          Text('Card No: ${guest['cardNo'] ?? 'N/A'}'),
                          Text('Vehicle No: ${guest['vehicleNo'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _updateGuest(guest),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteGuest(guest.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GuestRegistrationScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}