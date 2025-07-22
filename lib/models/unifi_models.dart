class UnifiSite {
  final String id;
  final String name;
  final String description;
  final bool isOwner;

  UnifiSite({
    required this.id,
    required this.name,
    required this.description,
    required this.isOwner,
  });

  factory UnifiSite.fromJson(Map<String, dynamic> json) {
    return UnifiSite(
      id: json['name'] ?? '',
      name: json['name'] ?? '',
      description: json['desc'] ?? json['name'] ?? '',
      isOwner: json['role'] == 'admin' || json['role'] == 'owner',
    );
  }
}

class WirelessNetwork {
  final String id;
  final String name;
  final String security;
  final bool enabled;
  final String? currentPassword;

  WirelessNetwork({
    required this.id,
    required this.name,
    required this.security,
    required this.enabled,
    this.currentPassword,
  });

  factory WirelessNetwork.fromJson(Map<String, dynamic> json) {
    return WirelessNetwork(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      security: json['security'] ?? 'open',
      enabled: json['enabled'] ?? true,
      currentPassword: json['x_passphrase'],
    );
  }
}

class UnifiCredentials {
  final String username;
  final String password;
  final String baseUrl;

  UnifiCredentials({
    required this.username,
    required this.password,
    this.baseUrl = 'https://unifi.ui.com',
  });
}