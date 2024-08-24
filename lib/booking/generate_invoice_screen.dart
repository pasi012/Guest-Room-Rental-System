import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GenerateInvoiceScreen extends StatefulWidget {
  final String bookingId;

  const GenerateInvoiceScreen({super.key, required this.bookingId});

  @override
  _GenerateInvoiceScreenState createState() => _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends State<GenerateInvoiceScreen> {
  double? _totalRent;
  bool _isPaid = false;
  final _additionalChargesController = TextEditingController();

  Future<void> _calculateAndSaveInvoice() async {
    final bookingSnapshot = await FirebaseFirestore.instance
        .collection('Bookings')
        .doc(widget.bookingId)
        .get();

    if (bookingSnapshot.exists) {
      final bookingData = bookingSnapshot.data()!;

      DateTime checkInDate;
      DateTime checkOutDate;
      var checkInDateValue = bookingData['checkInDate'];
      var checkOutDateValue = bookingData['checkOutDate'];

      if (checkInDateValue is Timestamp && checkOutDateValue is Timestamp) {
        checkInDate = (checkInDateValue).toDate();
        checkOutDate = (checkOutDateValue).toDate();
      } else if (checkInDateValue is String && checkOutDateValue is String) {
        checkInDate = DateTime.parse(checkInDateValue);
        checkOutDate = DateTime.parse(checkOutDateValue);
      } else {
        throw Exception('Unexpected type for checkInDate');
      }

      double roomRent = bookingData['payment'];
      double additionalCharges =
          double.tryParse(_additionalChargesController.text) ?? 0.0;

      _totalRent = calculateRent(checkInDate, checkOutDate, roomRent,
          additionalCharges: additionalCharges);

      // Update payment status in booking
      await FirebaseFirestore.instance
          .collection('Bookings')
          .doc(widget.bookingId)
          .update({
        'isPaid': _isPaid,
        'payment': _totalRent,
      });

      if(_isPaid == true){

        //guest Remove system
        final QuerySnapshot guestSnapshot = await FirebaseFirestore.instance
            .collection('Guests')
            .where('name', isEqualTo: bookingData['guestName'])
            .limit(1)
            .get();

        if (guestSnapshot.docs.isNotEmpty) {
          final String guestId = guestSnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('Guests')
              .doc(guestId)
              .delete();
        }

        //room availability update
        final QuerySnapshot roomSnapshot = await FirebaseFirestore.instance
            .collection('Rooms')
            .where('roomNumber', isEqualTo: bookingData['roomNo'])
            .limit(1)
            .get();

        if (roomSnapshot.docs.isNotEmpty) {
          final String roomId = roomSnapshot.docs.first.id;

          await FirebaseFirestore.instance
              .collection('Rooms')
              .doc(roomId)
              .update({'isAvailable': true});
        }

      }

      // Generate PDF invoice
      await _generatePDFInvoice(bookingData, additionalCharges);

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice generated successfully!'),
        ),
      );
    }
  }

  Future<void> _generatePDFInvoice(
      Map<String, dynamic> bookingData, double additionalCharges) async {
    final pdf = pw.Document();
    DateTime checkInDate;
    DateTime checkOutDate;
    var checkInDateValue = bookingData['checkInDate'];
    var checkOutDateValue = bookingData['checkOutDate'];

    if (checkInDateValue is Timestamp && checkOutDateValue is Timestamp) {
      checkInDate = (checkInDateValue).toDate();
      checkOutDate = (checkOutDateValue).toDate();
    } else if (checkInDateValue is String && checkOutDateValue is String) {
      checkInDate = DateTime.parse(checkInDateValue);
      checkOutDate = DateTime.parse(checkOutDateValue);
    } else {
      throw Exception('Unexpected type for checkInDate');
    }
    final roomRent = bookingData['payment'];
    final totalRent = roomRent + additionalCharges;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Invoice',
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
            pw.Divider(height: 2, thickness: 2),
            pw.SizedBox(height: 20),
            _buildDetailRow('Booking ID:', widget.bookingId),
            _buildDetailRow(
                'Check-In Date:', DateFormat('dd-MM-yyyy').format(checkInDate)),
            _buildDetailRow(
                'Check-Out Date:', DateFormat('dd-MM-yyyy').format(checkOutDate)),
            pw.SizedBox(height: 20),
            pw.Text(
              'Charges:',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildDetailRow('Room Rent:', 'LKR ${roomRent.toStringAsFixed(2)}'),
            _buildDetailRow('Additional Charges:',
                'LKR ${additionalCharges.toStringAsFixed(2)}'),
            pw.Divider(height: 1, thickness: 1, color: PdfColors.grey),
            _buildDetailRow('Total Rent:', 'LKR ${totalRent.toStringAsFixed(2)}'),
            pw.SizedBox(height: 20),
            _buildDetailRow('Payment Status:', _isPaid ? 'Paid' : 'Unpaid'),
          ],
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${widget.bookingId}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Load the PDF file
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(value),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Invoice'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _additionalChargesController,
              decoration: const InputDecoration(
                labelText: 'Additional Charges',
                labelStyle: TextStyle(color: Colors.blueAccent),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueGrey, width: 1.0),
                ),
                prefixIcon: Icon(Icons.attach_money, color: Colors.blueAccent),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Status:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      _isPaid ? 'Paid' : 'Unpaid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isPaid ? Colors.green : Colors.red,
                      ),
                    ),
                    Switch(
                      value: _isPaid,
                      onChanged: (value) {
                        setState(() {
                          _isPaid = value;
                        });
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _calculateAndSaveInvoice,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Generate Invoice'),
              ),
            ),
            if (_totalRent != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Center(
                  child: Text(
                    'Total Rent: LKR ${_totalRent!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double calculateRent(DateTime checkInDate, DateTime checkOutDate,
      double roomRent, {double additionalCharges = 0.0}) {
    double totalRent = roomRent + additionalCharges;
    return totalRent;
  }

  @override
  void dispose() {
    _additionalChargesController.dispose();
    super.dispose();
  }
}