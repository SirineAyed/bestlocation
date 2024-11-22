class LocationModel {
  final double latitude;
  final double longitude;
  final String number;
  final String pseudo;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.number,
    required this.pseudo,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'number': number,
      'pseudo': pseudo,
    };
  }

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      latitude: map['latitude'],
      longitude: map['longitude'],
      number: map['number'],
      pseudo: map['pseudo'],
    );
  }
}