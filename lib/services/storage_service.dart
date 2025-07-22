import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  
  // Secure storage for UniFi credentials
  static const String _usernameKey = 'unifi_username';
  static const String _passwordKey = 'unifi_password';
  static const String _baseUrlKey = 'unifi_base_url';
  
  // Secure storage for app admin credentials
  static const String _adminUsernameKey = 'app_admin_username';
  static const String _adminPasswordKey = 'app_admin_password';
  
  // Secure storage for presetup login information
  static const String _presetupUsernameKey = 'presetup_username';
  static const String _presetupPasswordKey = 'presetup_password';
  static const String _presetupIpKey = 'presetup_ip';
  static const String _presetupPortKey = 'presetup_port';
  
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
  
  // Admin credentials methods
  static Future<void> saveAdminCredentials({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _adminUsernameKey, value: username);
    await _storage.write(key: _adminPasswordKey, value: password);
  }
  
  static Future<bool> hasAdminCredentials() async {
    final username = await _storage.read(key: _adminUsernameKey);
    final password = await _storage.read(key: _adminPasswordKey);
    return username != null && password != null;
  }
  
  static Future<bool> validateAdminCredentials({
    required String username,
    required String password,
  }) async {
    final storedUsername = await _storage.read(key: _adminUsernameKey);
    final storedPassword = await _storage.read(key: _adminPasswordKey);
    
    return username == storedUsername && password == storedPassword;
  }
  
  // Presetup login information methods
  static Future<void> savePresetupInfo({
    required String username,
    required String password,
    required String ip,
    required String port,
  }) async {
    await _storage.write(key: _presetupUsernameKey, value: username);
    await _storage.write(key: _presetupPasswordKey, value: password);
    await _storage.write(key: _presetupIpKey, value: ip);
    await _storage.write(key: _presetupPortKey, value: port);
  }
  
  static Future<Map<String, String?>> getPresetupInfo() async {
    final username = await _storage.read(key: _presetupUsernameKey);
    final password = await _storage.read(key: _presetupPasswordKey);
    final ip = await _storage.read(key: _presetupIpKey);
    final port = await _storage.read(key: _presetupPortKey);
    
    return {
      'username': username,
      'password': password,
      'ip': ip,
      'port': port ?? '443',
    };
  }
  
  static Future<bool> hasPresetupInfo() async {
    final username = await _storage.read(key: _presetupUsernameKey);
    final ip = await _storage.read(key: _presetupIpKey);
    return username != null && ip != null;
  }
}