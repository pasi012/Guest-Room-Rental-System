import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGuestName;
  String? _selectedRoomNo;
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  final _paymentController = TextEditingController();
  bool _isPaid = false;

  Future<void> _saveBookingData() async {
    if (_formKey.currentState!.validate() &&
        _checkInDate != null &&
        _checkOutDate != null) {

      int totalDays = _checkOutDate!.difference(_checkInDate!).inDays;

      await FirebaseFirestore.instance.collection('Bookings').add({
        'guestName': _selectedGuestName,
        'roomNo': _selectedRoomNo,
        'checkInDate': DateFormat('yyyy-MM-dd').format(Timestamp.fromDate(_checkInDate!).toDate()),
        'checkOutDate': DateFormat('yyyy-MM-dd').format(Timestamp.fromDate(_checkOutDate!).toDate()),
        'payment': totalDays * double.parse(_paymentController.text),
        'isPaid': _isPaid, // Add payment status
      });

      final QuerySnapshot roomSnapshot = await FirebaseFirestore.instance
          .collection('Rooms')
          .where('roomNumber', isEqualTo: _selectedRoomNo)
          .limit(1)
          .get();

      if (roomSnapshot.docs.isNotEmpty) {
        final String roomId = roomSnapshot.docs.first.id;

        await FirebaseFirestore.instance
            .collection('Rooms')
            .doc(roomId)
            .update({'isAvailable': false});
      }

      setState(() {
        _selectedGuestName = null;
        _selectedRoomNo = null;
        _checkInDate = null;
        _checkOutDate = null;
        _isPaid = false; // Reset isPaid status
      });
      _paymentController.clear();
    }

    Navigator.pop(context);
  }

  Future<void> _pickCheckInDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _checkInDate) {
      setState(() {
        _checkInDate = pickedDate;
      });
    }
  }

  Future<void> _pickCheckOutDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
      firstDate: _checkInDate?.add(const Duration(days: 1)) ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _checkOutDate) {
      setState(() {
        _checkOutDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Form'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Guests')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final guests = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedGuestName,
                    decoration: InputDecoration(
                      labelText: 'Select Guest',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: guests.map((guest) {
                      return DropdownMenuItem<String>(
                        value: guest['name'],
                        child: Text(guest['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGuestName = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Please select a guest' : null,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Rooms')
                    .where('isAvailable', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final rooms = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedRoomNo,
                    decoration: InputDecoration(
                      labelText: 'Select Room',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    items: rooms.map((room) {
                      return DropdownMenuItem<String>(
                        value: room['roomNumber'],
                        child: Text(
                            'Room ${room['roomNumber']} - ${room['roomType']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRoomNo = value;
                        // Set room rent to the payment controller
                        final selectedRoom = rooms.firstWhere((room) => room['roomNumber'] == value);
                        _paymentController.text = selectedRoom['roomRent'].toStringAsFixed(0);
                      });
                    },
                    validator: (value) =>
                    value == null ? 'Please select a room' : null,
                  );
                },
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: Text(_checkInDate == null
                    ? 'Select Check-In Date'
                    : 'Check-In Date: ${DateFormat('yyyy-MM-dd').format(_checkInDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickCheckInDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tileColor: Colors.teal[50],
              ),
              const SizedBox(height: 16.0),
              ListTile(
                title: Text(_checkOutDate == null
                    ? 'Select Check-Out Date'
                    : 'Check-Out Date: ${DateFormat('yyyy-MM-dd').format(_checkOutDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickCheckOutDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                tileColor: Colors.teal[50],
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                readOnly: true,
                controller: _paymentController,
                decoration: InputDecoration(
                  labelText: 'Room Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Payment Status'),
                value: _isPaid,
                onChanged: (bool value) {
                  setState(() {
                    _isPaid = value;
                  });
                },
                subtitle: const Text('Mark as paid'),
                activeColor: Colors.teal,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBookingData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }
}