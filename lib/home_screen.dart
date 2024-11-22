import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'location_model.dart';
import 'package:provider/provider.dart';
import 'location_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController mapController;
  Position currentPosition = Position(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    isMocked: false,
    altitudeAccuracy: 0, headingAccuracy: 0, 
  );
  String number = '';
  String pseudo = '';
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdateStream();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); 
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentPosition = position;
    });
  }

  void _startLocationUpdateStream() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Mise à jour chaque mètre
      ),
    ).listen((newPosition) {
      if (newPosition.latitude != currentPosition.latitude || newPosition.longitude != currentPosition.longitude) {
        setState(() {
          currentPosition = newPosition;
        });

        // Sauvegarder la nouvelle position si elle a changé
        _saveLocation();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _saveLocation() {
    if (pseudo.isNotEmpty && number.isNotEmpty) {
      final location = LocationModel(
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
        number: number,
        pseudo: pseudo,
      );
      Provider.of<LocationProvider>(context, listen: false).addLocation(location);
    }
  }

  void _showEditDialog(LocationModel location, int index) {
    TextEditingController numberController = TextEditingController(text: location.number);
    TextEditingController pseudoController = TextEditingController(text: location.pseudo);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                decoration: InputDecoration(labelText: 'Number'),
              ),
              TextField(
                controller: pseudoController,
                decoration: InputDecoration(labelText: 'Pseudo'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final updatedLocation = LocationModel(
                  latitude: location.latitude,
                  longitude: location.longitude,
                  number: numberController.text,
                  pseudo: pseudoController.text,
                );
                Provider.of<LocationProvider>(context, listen: false).updateLocation(index, updatedLocation);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Localisation App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(currentPosition.latitude, currentPosition.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('current'),
                  position: LatLng(currentPosition.latitude, currentPosition.longitude),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => number = value,
                  decoration: InputDecoration(labelText: 'Number'),
                ),
                TextField(
                  onChanged: (value) => pseudo = value,
                  decoration: InputDecoration(labelText: 'Pseudo'),
                ),
                ElevatedButton(
                  onPressed: _saveLocation,
                  child: Text('Save'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<LocationProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.locations.length,
                  itemBuilder: (context, index) {
                    final location = provider.locations[index];
                    return ListTile(
                      title: Text(location.pseudo),
                      subtitle: Text('${location.latitude}, ${location.longitude}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              _showEditDialog(location, index);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.map),
                            onPressed: () {
                              mapController.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(location.latitude, location.longitude),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              provider.removeLocation(index);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}