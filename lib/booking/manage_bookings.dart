import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guest_house_rental_system/booking/booking_form.dart';
import 'package:intl/intl.dart';
import 'generate_invoice_screen.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Bookings'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Bookings').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final checkInDate = booking['checkInDate'];
              final checkOutDate = booking['checkOutDate'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    booking['isPaid'] ? Icons.check_circle : Icons.warning,
                    color: booking['isPaid'] ? Colors.green : Colors.red,
                    size: 40,
                  ),
                  title: Text(
                    booking['guestName'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Room No: ${booking['roomNo']}'),
                      Text('Check-In: $checkInDate'),
                      Text('Check-Out: $checkOutDate'),
                      Text('Payment: LKR${booking['payment'].toStringAsFixed(2)}'),
                      Text(
                        'Status: ${booking['isPaid'] ? 'Paid' : 'Unpaid'}',
                        style: TextStyle(
                          color: booking['isPaid'] ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.receipt, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenerateInvoiceScreen(bookingId: booking.id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('Bookings')
                              .doc(booking.id)
                              .delete();

                          final QuerySnapshot roomSnapshot = await FirebaseFirestore.instance
                              .collection('Rooms')
                              .where('roomNumber', isEqualTo: booking['roomNo'])
                              .limit(1)
                              .get();

                          if (roomSnapshot.docs.isNotEmpty) {
                            final String roomId = roomSnapshot.docs.first.id;
                            await FirebaseFirestore.instance
                                .collection('Rooms')
                                .doc(roomId)
                                .update({'isAvailable': true});
                          }
                        },
                      ),
                    ],
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
              builder: (context) => const BookingForm(),
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}