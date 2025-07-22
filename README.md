# Unifi WPA Password Changer - Flutter App

A Flutter mobile application to change WPA passwords on Unifi Cloud equipment through the Unifi Controller API.

## Features

- 🔐 Secure login with Unifi Cloud credentials
- 💾 Remember credentials with secure storage
- 🏢 Multi-site support for organizations
- 📱 Native mobile interface for iOS and Android
- 📡 List and manage wireless networks
- 🔄 Update WPA passwords remotely
- ⚠️ Safety confirmations before changes
- 🔒 Only shows secured networks (WPA/WPA2/WPA3)

## Screenshots

The app includes:
- Login screen with credential storage
- Site selection for multi-site setups
- Network list with security indicators
- Password change form with validation
- Confirmation dialogs for safety

## Prerequisites

- Flutter SDK 3.10.0 or higher
- Dart SDK 3.0.0 or higher
- Unifi Cloud account with admin access
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

1. **Login Screen**
   - Enter Unifi Cloud credentials
   - Option to remember credentials securely
   - Custom Unifi URL support

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

## Security Features

- Credentials stored using Flutter Secure Storage
- HTTPS-only API communications
- Password validation and confirmation
- Warning dialogs before changes
- No plaintext credential storage

## API Integration

The app uses these Unifi Controller API endpoints:
- `/api/auth/login` - Authentication
- `/api/self/sites` - List accessible sites
- `/proxy/network/api/s/{site}/rest/wlanconf` - Wireless network management

## Permissions

### Android
- Internet access for API calls
- Secure storage for credentials

### iOS
- Network access for API calls
- Keychain access for secure storage

## Troubleshooting

### Login Issues
- Verify Unifi Cloud credentials
- Check internet connection
- Ensure account has admin privileges
- Try custom Unifi URL if using self-hosted

### Network Issues
- Verify site access permissions
- Check if networks are enabled
- Ensure WPA security is configured

### Build Issues
- Run `flutter clean` and `flutter pub get`
- Check Flutter and Dart SDK versions
- Verify platform-specific requirements

## Development

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── unifi_models.dart    # Data models
├── services/
│   ├── unifi_service.dart   # API service
│   └── storage_service.dart # Secure storage
└── screens/
    ├── login_screen.dart
    ├── sites_screen.dart
    ├── networks_screen.dart
    └── password_change_screen.dart
```

### Dependencies
- `http` - HTTP client for API calls
- `flutter_secure_storage` - Secure credential storage
- `shared_preferences` - App preferences

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both iOS and Android
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Disclaimer

This app is not officially affiliated with Ubiquiti Networks. Use at your own risk and ensure you have proper authorization to modify network settings."# UnifiWPA" 
