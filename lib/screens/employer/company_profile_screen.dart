import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState
    extends State<CompanyProfileScreen> {

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  bool isLoading = true;

  final _fire = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (user == null) return;

    final doc =
        await _fire.collection('users').doc(user!.uid).get();

    final data = doc.data();

    if (data != null) {
      _nameController.text = data['companyName'] ?? '';
      _descController.text = data['companyDesc'] ?? '';
      _locationController.text = data['companyLocation'] ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    if (user == null) return;

    await _fire.collection('users').doc(user!.uid).update({
      "companyName": _nameController.text.trim(),
      "companyDesc": _descController.text.trim(),
      "companyLocation": _locationController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saved")),
    );
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Company Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [

            _field("Company Name", _nameController),
            _field("Description", _descController, max: 4),
            _field("Location", _locationController),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _save,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {int max = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: max,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}