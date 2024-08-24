import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guest_house_rental_system/booking/manage_bookings.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';

import 'package:printing/printing.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Lighter grey background
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal, // Teal color for AppBar
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageBookingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.book),
            color: Colors.white,
          ),
        ],
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle(title: 'Bookings Overview'),
              BookingsOverview(),
              SectionTitle(title: 'Check-Ins Today'),
              CheckInsToday(),
              SectionTitle(title: 'Room Statuses'),
              RoomStatuses(),
              SizedBox(height: 16),
              SectionTitle(title: 'Get Report'),
              GetReportSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal[800], // Color matching the AppBar
          ),
        ),
      ),
    );
  }
}

class BookingsOverview extends StatelessWidget {
  const BookingsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        int totalBookings = snapshot.data!.docs.length;
        int confirmedBookings = snapshot.data!.docs
            .where((doc) => doc['isPaid'] == true)
            .length;
        int pendingBookings = totalBookings - confirmedBookings;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InfoCard(label: 'Total', value: totalBookings, color: Colors.teal),
              InfoCard(label: 'Confirmed', value: confirmedBookings, color: Colors.green),
              InfoCard(label: 'Pending', value: pendingBookings, color: Colors.orange),
            ],
          ),
        );
      },
    );
  }
}

class CheckInsToday extends StatelessWidget {
  const CheckInsToday({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Bookings')
          .where('checkInDate', isEqualTo: DateFormat('yyyy-MM-dd').format(Timestamp.fromDate(today).toDate()))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        int checkInsToday = snapshot.data!.docs.length;

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InfoCard(
              label: 'Check-Ins Today',
              value: checkInsToday,
              color: Colors.blue,
            ),
          ),
        );
      },
    );
  }
}

class RoomStatuses extends StatelessWidget {
  const RoomStatuses({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Rooms').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        List<DocumentSnapshot> properties = snapshot.data!.docs;
        int available = properties
            .where((doc) => doc['isAvailable'] == true)
            .length;
        int booked = properties
            .where((doc) => doc['isAvailable'] == false)
            .length;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InfoCard(label: 'Available', value: available, color: Colors.lightGreen),
              InfoCard(label: 'Booked', value: booked, color: Colors.redAccent),
            ],
          ),
        );
      },
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class GetReportSection extends StatelessWidget {
  const GetReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          onPressed: () {
            _exportBookingsToPDF();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal, // Button color
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Generate Report'),
        ),
      ),
    );
  }

  Future<void> _exportBookingsToPDF() async {
    final pdf = pw.Document();
    final bookingsSnapshot = await FirebaseFirestore.instance.collection('Bookings').get();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bookings Report',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.black,
                    width: 1,
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(210),
                    1: const pw.FixedColumnWidth(120),
                    2: const pw.FixedColumnWidth(90),
                    3: const pw.FixedColumnWidth(120),
                    4: const pw.FixedColumnWidth(120),
                    5: const pw.FixedColumnWidth(150),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue200,
                      ),
                      children: [
                        _buildTableHeader('Booking ID'),
                        _buildTableHeader('Guest Name'),
                        _buildTableHeader('Room No'),
                        _buildTableHeader('Check In'),
                        _buildTableHeader('Check Out'),
                        _buildTableHeader('Total Payment'),
                      ],
                    ),
                    ...bookingsSnapshot.docs.map(
                          (booking) {
                        final data = booking.data();
                        final checkIn = data['checkInDate'] as String;
                        final checkOut = data['checkOutDate'] as String;

                        return pw.TableRow(
                          children: [
                            pw.Text(booking.id),
                            pw.Text(data['guestName']),
                            pw.Text(data['roomNo']),
                            pw.Text(checkIn),
                            pw.Text(checkOut),
                            pw.Text("LKR: ${data['payment'].toString()}"),
                          ],
                        );
                      },
                    ).toList(),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/bookings_report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    // Load the PDF file
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    // Show a confirmation
    print('PDF Exported: $path');
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }


}
