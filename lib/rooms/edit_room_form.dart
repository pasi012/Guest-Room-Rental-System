import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditRoomForm extends StatefulWidget {
  final String roomId;
  final String roomNumber;
  final String roomType;
  final double roomRent;
  final bool isAvailable;

  const EditRoomForm({
    super.key,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.roomRent,
    required this.isAvailable,
  });

  @override
  _EditRoomFormState createState() => _EditRoomFormState();
}

class _EditRoomFormState extends State<EditRoomForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roomNumberController;
  late TextEditingController _roomRentController;
  late bool _isAvailable;
  String? _selectedRoomType;

  @override
  void initState() {
    super.initState();
    _roomNumberController = TextEditingController(text: widget.roomNumber);
    _roomRentController = TextEditingController(text: widget.roomRent.toString());
    _isAvailable = widget.isAvailable;
    _selectedRoomType = widget.roomType;
  }

  Future<void> _updateRoomData() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('Rooms')
          .doc(widget.roomId)
          .update({
        'roomNumber': _roomNumberController.text,
        'roomType': _selectedRoomType,
        'roomRent': double.parse(_roomRentController.text),
        'isAvailable': _isAvailable,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Room'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _roomNumberController,
                labelText: 'Room Number',
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdownField(
                labelText: 'Room Type',
                value: _selectedRoomType,
                items: ['AC', 'Non-AC'],
                onChanged: (newValue) {
                  setState(() {
                    _selectedRoomType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a room type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _roomRentController,
                labelText: 'Room Rent',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the room rent';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Is Available'),
                value: _isAvailable,
                onChanged: (bool value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                activeColor: Colors.blue,
                controlAffinity: ListTileControlAffinity.trailing,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateRoomData,
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Update Room',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _roomRentController.dispose();
    super.dispose();
  }
}