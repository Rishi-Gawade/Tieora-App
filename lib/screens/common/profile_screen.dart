import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/widgets/app_rating.dart';
import '../../utils/location_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController ageController = TextEditingController();

  final TextEditingController experienceTitleCtrl = TextEditingController();
  final TextEditingController experienceDescCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool loading = true;
  bool saving = false;

  late DocumentSnapshot userDoc;

  List<String> _skills = [];
  List<Map<String, dynamic>> _experience = [];

  String? _profileImageUrl;
  Uint8List? _imageBytes;

  /// 🔥 AVAILABLE SKILLS
  final List<String> _availableSkills = [
    "Flutter",
    "Java",
    "Python",
    "React",
    "Node.js",
    "UI/UX",
    "Firebase",
    "MongoDB",
    "Mechanical",
    "Electrical",
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      userDoc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

      final data = userDoc.data() as Map<String, dynamic>? ?? {};

      phoneController.text = data["phone"] ?? "";
      locationController.text = data["locationText"] ?? "";
      ageController.text = (data["age"] ?? "").toString();
      _profileImageUrl = data["profileImage"];

      final skillsFromDb = data["skills"];
      if (skillsFromDb is List) {
        _skills = skillsFromDb.map((e) => e.toString()).toList();
      }

      final expFromDb = data["experience"];
      if (expFromDb is List) {
        _experience = expFromDb
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Load failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
  try {
    LocationPermission permission =
        await Geolocator.requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Location permission denied");
    }

    final position = await Geolocator.getCurrentPosition();

    final lat = position.latitude;
    final lng = position.longitude;
    String city = "";

String address = "Fetching location...";

try {
  final placemarks = await placemarkFromCoordinates(lat, lng);
  
  if (placemarks.isNotEmpty) {
    final place = placemarks.first;

    city = place.locality ?? place.subAdministrativeArea ?? "";
    
    final state = place.administrativeArea ?? "";
    final country = place.country ?? "";

    final formatted = [city, state, country]
        .where((e) => e.isNotEmpty)
        .join(", ");

    address = formatted.isNotEmpty
        ? formatted
        : "Location detected";
  } else {
    address = "Location detected";
  }
} catch (e) {
  debugPrint("Geocoding failed: $e");
  address = "Location detected";
}

/// 🔥 UPDATE UI
setState(() {
  locationController.text = address;
});

/// 🔥 SAVE IN FIRESTORE
await userDoc.reference.update({
  "locationGeo": GeoPoint(lat, lng),
  "locationText": address,
  "city": city,
});
await loadProfile();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Location updated from GPS ✅")),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location error: $e")),
    );
  }
}

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();

    setState(() {
      _imageBytes = bytes;
    });

    await _uploadImage(bytes);
  }

  Future<void> _uploadImage(Uint8List bytes) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$uid.jpg');

      await ref.putData(bytes);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"profileImage": url});

      setState(() => _profileImageUrl = url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile image updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    }
  }

  bool _validatePhone(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^\+?\d{7,15}$').hasMatch(normalized);
  }

  Future<void> saveProfile() async {
    final phone = phoneController.text.trim();
    final age = ageController.text.trim();

    if (!_validatePhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid phone")),
      );
      return;
    }

    if (age.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Age is required")),
      );
      return;
    }

    final locationText = locationController.text.trim();

    if (locationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location is required")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      GeoPoint? locationGeo;

      if (userDoc.data() != null &&
          (userDoc.data() as Map)["locationGeo"] != null) {
        locationGeo = (userDoc.data() as Map)["locationGeo"];
      }

      locationGeo ??= await LocationHelper.geoFromText(locationText);

      if (locationGeo == null) {
        locationGeo = const GeoPoint(0, 0);
      }

      final payload = {
        "phone": phone,
        "age": age,
        "skills": _skills,
        "experience": _experience,
        "locationText": locationText,
        "locationGeo": locationGeo,
        "updatedAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set(payload, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Save failed: $e")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _cardWrapper({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, IconData icon,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final data = userDoc.data() as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            icon: saving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
            onPressed: saving ? null : saveProfile,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

        Center(
          child: Column(
            children: [

      /// 👤 PROFILE IMAGE
      GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 55,
          backgroundImage: _imageBytes != null
              ? MemoryImage(_imageBytes!)
              : (_profileImageUrl != null
                  ? NetworkImage(_profileImageUrl!)
                  : null) as ImageProvider?,
          child: _profileImageUrl == null && _imageBytes == null
              ? const Icon(Icons.camera_alt)
              : null,
        ),
      ),

      const SizedBox(height: 12),

      /// 👤 NAME
      Text(
        data["fullName"] ?? "User",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 6),

      /// ⭐ RATING (NEW)
      AppRating(
        rating: (data['rating'] ?? 0).toDouble(),
        totalRatings: data['totalRatings'] ?? 0,
      ),
    ],
  ),
),

          const SizedBox(height: 20),

          _cardWrapper(
            title: "Basic Info",
            child: Column(
              children: [
                _textField(TextEditingController(text: data["fullName"] ?? ""), "Full Name", Icons.person, readOnly: true),
                _textField(TextEditingController(text: data["email"] ?? ""), "Email", Icons.email, readOnly: true),
                _textField(ageController, "Age", Icons.cake),
              ],
            ),
          ),

          _cardWrapper(
            title: "Contact",
            child: Column(
              children: [
                _textField(phoneController, "Phone", Icons.phone),
                _textField(locationController, "Location", Icons.location_on),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text("Use Current Location"),
                  ),
                ),
              ],
            ),
          ),

          _cardWrapper(
            title: "Skills",
            child: Column(
              children: [

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSkills.map((skill) {
                    final isSelected = _skills.contains(skill);

                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _skills.add(skill);
                          } else {
                            _skills.remove(skill);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  children: _skills
                      .map((s) => Chip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() => _skills.remove(s));
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          _cardWrapper(
            title: "Experience",
            child: Column(
              children: [
                ..._experience.map((e) => ListTile(
                      title: Text(e["title"] ?? ""),
                      subtitle: Text(e["description"] ?? ""),
                    )),
                _textField(experienceTitleCtrl, "Role", Icons.work_outline),
                _textField(experienceDescCtrl, "Description", Icons.notes),
                ElevatedButton(
                  onPressed: _addExperience,
                  child: const Text("Add Experience"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addExperience() {
    final title = experienceTitleCtrl.text.trim();
    final desc = experienceDescCtrl.text.trim();

    if (title.isEmpty) return;

    setState(() {
      _experience.add({
        "title": title,
        "description": desc,
        "addedAt": Timestamp.now(),
      });
      experienceTitleCtrl.clear();
      experienceDescCtrl.clear();
    });
  }
}