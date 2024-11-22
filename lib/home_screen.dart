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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }



Future<void> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Vérifie si le service de localisation est activé
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Le service de localisation est désactivé, informez l'utilisateur
    return Future.error('Location services are disabled.');
  }

  // Vérifie la permission
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    // Demande la permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // La permission est refusée, informez l'utilisateur
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // La permission est refusée de manière permanente, informez l'utilisateur
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Obtient la position actuelle
  final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  setState(() {
    currentPosition = position;
  });
}

 void _startLocationUpdateTimer() {
  _timer = Timer.periodic(Duration(minutes: 1), (timer) async {
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
      
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

   
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentPosition = position;
    });
  });
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _saveLocation() {
    final location = LocationModel(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      number: number,
      pseudo: pseudo,
    );
    Provider.of<LocationProvider>(context, listen: false).addLocation(location);
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