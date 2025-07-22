# UniFi WPA Password Manager

A Flutter mobile application to change WPA passwords on local UniFi equipment through the UniFi Controller API.
Usefull for IT Service company to delegate to their customers the right to change WPA password ONLY.
I hope some tech will find it usefull.

## Features

- 🔐 Secure login with local UniFi Controller credentials
- � Netwmork scanner to discover UniFi devices on your local network
- 💾 Remember credentials with secure storage
- 🏢 Multi-site support for organizations
- � Nastive mobile interface for iOS and Android
- � UList and manage wireless networks
- 🔄 Update WPA passwords securely
- ⚠️ Safety confirmations before changes
- 🔒 Only shows secured networks (WPA/WPA2/WPA3)
- 🛠️ Presetup mode for IT administrators
- 🔐 Support for self-signed certificates

## Important Note

This app is designed to connect **only to local UniFi Controllers** and does not support UniFi Cloud. You must have a UniFi Controller accessible on your local network via IP address.

## Screenshots

The app includes:
- Login screen with credential storage
- Network scanner for device discovery
- Site selection for multi-site setups
- Network list with security indicators
- Password change form with validation
- Confirmation dialogs for safety
- Certificate helper for self-signed certificates

## Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Local UniFi Controller with admin access
- iOS 11.0+ or Android API level 21+

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd unifi_password_changer
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Building for Release

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## App Flow

### For End Users
1. **Login Screen**
   - Enter local UniFi Controller credentials
   - Option to remember credentials securely
   - Custom UniFi URL support for local controllers

2. **Sites Screen**
   - Lists all accessible sites
   - Shows admin/user permissions
   - Select site to manage

3. **Networks Screen**
   - Shows wireless networks for selected site
   - Only displays secured networks (WPA/WPA2/WPA3)
   - Security level indicators

4. **Password Change Screen**
   - Network information display
   - Password validation (8-63 characters)
   - Confirmation dialog with warnings
   - Success/error feedback

### For IT Administrators
1. **Presetup Screen**
   - Configure UniFi Controller credentials
   - Use network scanner to discover UniFi devices
   - Save configuration for end users

## Technical Details

- Connects only to local UniFi Controllers (not UniFi Cloud)
- Uses HTTPS for secure communication
- Discovers UniFi devices using UDP port 10001
- Stores credentials securely using Flutter's secure storage
- Handles self-signed certificates

## Security Features

- Credentials stored using Flutter Secure Storage
- HTTPS-only API communications
- Password validation and confirmation
- Warning dialogs before changes
- No plaintext credential storage
- Certificate validation options

## API Integration

The app uses these UniFi Controller API endpoints:
- `/api/auth/login` - Authentication
- `/api/self/sites` - List accessible sites
- `/proxy/network/api/s/{site}/rest/wlanconf` - Wireless network management

## Permissions

### Android
- Internet access for API calls
- Secure storage for credentials
- UDP socket access for network scanning

### iOS
- Network access for API calls
- Keychain access for secure storage
- UDP socket access for network scanning

## Troubleshooting

### Login Issues
- Verify local UniFi Controller credentials
- Check network connection to the controller
- Ensure account has admin privileges
- Check if controller is accessible via IP address
- Use certificate helper for self-signed certificates

### Network Issues
- Verify site access permissions
- Check if networks are enabled
- Ensure WPA security is configured
- Verify local network connectivity

### Build Issues
- Run `flutter clean` and `flutter pub get`
- Check Flutter and Dart SDK versions
- Verify platform-specific requirements

## Development

### Project Structure
```
lib/
├── main.dart                        # App entry point
├── models/
│   └── unifi_models.dart            # Data models
├── services/
│   ├── unifi_service.dart           # API service
│   ├── storage_service.dart         # Secure storage
│   └── network_scanner_service.dart # Network discovery
└── screens/
    ├── login_screen.dart
    ├── presetup_login_screen.dart
    ├── sites_screen.dart
    ├── networks_screen.dart
    ├── password_change_screen.dart
    └── certificate_helper_screen.dart
```

### Dependencies
- `http` - HTTP client for API calls
- `flutter_secure_storage` - Secure credential storage
- `shared_preferences` - App preferences
- `udp` - UDP socket communication for device discovery

## License

MIT License - see LICENSE file for details

## Credits

Developed by IEC
www.iec.vu

## Disclaimer

This app is not officially affiliated with Ubiquiti Networks. Use at your own risk and ensure you have proper authorization to modify network settings.