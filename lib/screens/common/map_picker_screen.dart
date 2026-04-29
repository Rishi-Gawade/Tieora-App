import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/location_helper.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  LatLng? selectedLatLng;
  String selectedAddress = "Tap on map to select location";

  Marker? marker;

  /// 🔥 DEFAULT LOCATION (PUNE)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(18.5204, 73.8567),
    zoom: 14,
  );

  /// 🔹 HANDLE TAP
  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      selectedLatLng = position;
      marker = Marker(
        markerId: const MarkerId("selected"),
        position: position,
      );
    });

    final address = await LocationHelper.getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    if (address != null) {
      setState(() {
        selectedAddress = address;
      });
    }
  }

  /// 🔹 CONFIRM LOCATION
  void _confirmLocation() {
    if (selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a location")),
      );
      return;
    }

    final geoPoint = GeoPoint(
      selectedLatLng!.latitude,
      selectedLatLng!.longitude,
    );

    Navigator.pop(context, {
      "geo": geoPoint,
      "address": selectedAddress,
    });
  }

  /// 🔹 CURRENT LOCATION BUTTON
  Future<void> _goToCurrentLocation() async {
    final geo = await LocationHelper.getCurrentLocation();

    if (geo == null) return;

    final latLng = LatLng(geo.latitude, geo.longitude);

    final controller = await _controller.future;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 15),
      ),
    );

    _onMapTap(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Job Location"),
      ),
      body: Stack(
        children: [

          /// 🔥 GOOGLE MAP
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) {
              _controller.complete(controller);
            },
            onTap: _onMapTap,
            markers: marker != null ? {marker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          /// 📍 ADDRESS DISPLAY
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                selectedAddress,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          /// 🎯 CURRENT LOCATION BUTTON
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          /// ✅ CONFIRM BUTTON
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Confirm Location"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}