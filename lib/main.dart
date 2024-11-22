

import 'package:bestlocation/home_screen.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'location_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocationProvider()..loadLocations(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Localisation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

