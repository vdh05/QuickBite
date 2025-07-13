class Address {
  final String id;
  final String addressLine;
  final String city;
  final String state;
  final String zipCode;
  final String landmark;
  final String addressType; // Home, Work, Other
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  Address({
    required this.id,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.zipCode,
    this.landmark = '',
    required this.addressType,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['_id'] ?? json['id'] ?? '',
      addressLine: json['addressLine'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zipCode: json['zipCode'] ?? '',
      landmark: json['landmark'] ?? '',
      addressType: json['addressType'] ?? 'Home',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'landmark': landmark,
      'addressType': addressType,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
    };
  }
}
