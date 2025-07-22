import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  // Secure storage for credentials
  static const String _usernameKey = 'unifi_username';
  static const String _passwordKey = 'unifi_password';
  static const String _baseUrlKey = 'unifi_base_url';
  
  // Regular storage for preferences
  static const String _rememberCredentialsKey = 'remember_credentials';

  // Save credentials securely
  static Future<void> saveCredentials({
    required String username,
    required String password,
    String? baseUrl,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
    if (baseUrl != null) {
      await _storage.write(key: _baseUrlKey, value: baseUrl);
    }
  }

  // Get saved credentials
  static Future<Map<String, String?>> getCredentials() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    final baseUrl = await _storage.read(key: _baseUrlKey);
    
    return {
      'username': username,
      'password': password,
      'baseUrl': baseUrl,
    };
  }

  // Clear saved credentials
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
    await _storage.delete(key: _baseUrlKey);
  }

  // Remember credentials preference
  static Future<void> setRememberCredentials(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberCredentialsKey, remember);
  }

  static Future<bool> getRememberCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberCredentialsKey) ?? false;
  }

  // Check if credentials are saved
  static Future<bool> hasCredentials() async {
    final credentials = await getCredentials();
    return credentials['username'] != null && credentials['password'] != null;
  }
}