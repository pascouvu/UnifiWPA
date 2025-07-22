import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/unifi_service.dart';
import '../services/storage_service.dart';
import 'debug_screen.dart';
import 'certificate_helper_screen.dart';
import '../secret.dart';
import '../widgets/network_scanner_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  
  bool _isLoading = false;
  bool _rememberCredentials = false;
  // Always use HTTPS
  bool _useHttps = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    // First try to load from presetup info
    final hasPresetup = await StorageService.hasPresetupInfo();
    if (hasPresetup) {
      final presetupInfo = await StorageService.getPresetupInfo();
      _usernameController.text = presetupInfo['username'] ?? '';
      _passwordController.text = presetupInfo['password'] ?? '';
      _ipController.text = presetupInfo['ip'] ?? '';
      _portController.text = presetupInfo['port'] ?? '443';
      print('Loaded credentials from presetup info');
      return;
    }
    
    // If no presetup info, try to load from secret.dart
    try {
      _usernameController.text = UnifiCredentials.username;
      _passwordController.text = UnifiCredentials.password;
      _ipController.text = UnifiCredentials.defaultIp;
      _portController.text = UnifiCredentials.defaultPort;
      _useHttps = UnifiCredentials.useHttps;
      
      print('Loaded credentials from secret.dart');
    } catch (e) {
      // If secret.dart doesn't exist or has missing fields, use defaults
      if (_ipController.text.isEmpty) {
        _ipController.text = '192.168.1.';
      }
      if (_portController.text.isEmpty) {
        _portController.text = '443';
      }
      
      // Then try to load from saved preferences
      await _loadSavedCredentials();
    }
  }

  Future<void> _loadSavedCredentials() async {
    final remember = await StorageService.getRememberCredentials();
    if (remember) {
      final credentials = await StorageService.getCredentials();
      setState(() {
        // Only override if not already set from secret.dart
        if (_usernameController.text.isEmpty) {
          _usernameController.text = credentials['username'] ?? '';
        }
        if (_passwordController.text.isEmpty) {
          _passwordController.text = credentials['password'] ?? '';
        }
        
        // Parse saved URL to extract IP and port
        final savedUrl = credentials['baseUrl'] ?? '';
        if (savedUrl.isNotEmpty) {
          final uri = Uri.tryParse(savedUrl);
          if (uri != null) {
            if (_ipController.text.isEmpty) {
              _ipController.text = uri.host;
            }
            if (_portController.text.isEmpty) {
              _portController.text = uri.port.toString();
            }
            _useHttps = uri.scheme == 'https';
          }
        }
        
        _rememberCredentials = remember;
      });
    }
  }

  String _buildControllerUrl() {
    final protocol = _useHttps ? 'https' : 'http';
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    return '$protocol://$ip:$port';
  }

  void _updateIpField(String ip) {
    setState(() {
      _ipController.text = ip;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final controllerUrl = _buildControllerUrl();
      final unifiService = UnifiService(baseUrl: controllerUrl);
      final success = await unifiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        // Save credentials if remember is checked
        if (_rememberCredentials) {
          await StorageService.saveCredentials(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            baseUrl: controllerUrl,
          );
          await StorageService.setRememberCredentials(true);
        } else {
          await StorageService.clearCredentials();
          await StorageService.setRememberCredentials(false);
        }

        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/sites',
            arguments: unifiService,
          );
        }
      } else {
        if (mounted) {
          // Show appropriate error message based on the response
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Login failed. Please check your credentials and try again.'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Certificate Help',
                textColor: Colors.white,
                onPressed: () {
                  final url = _buildControllerUrl();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CertificateHelperScreen(
                        controllerUrl: url,
                        onCertificateAccepted: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Try logging in now!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unifi WPA'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back arrow from appearing
        actions: [
          // Admin credentials shortcut
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Admin Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/app-login');
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 8.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 80,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unifi WPA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'WiFi Password Manager',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Username field
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username/Email',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field (always obscured)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  obscureText: true, // Always obscured
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // IP and Port fields with scan button
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'Controller IP',
                          prefixIcon: const Icon(Icons.router),
                          suffixIcon: NetworkScannerWidget(
                            onIpSelected: _updateIpField,
                            compact: true,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: '192.168.1.100',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter controller IP';
                          }
                          // Basic IP validation
                          final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                          if (!ipRegex.hasMatch(value)) {
                            return 'Invalid IP format';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(),
                          hintText: '443',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          final port = int.tryParse(value);
                          if (port == null || port < 1 || port > 65535) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // URL preview
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'URL: ${_buildControllerUrl()}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Remember credentials
                CheckboxListTile(
                  title: const Text('Remember credentials', style: TextStyle(fontSize: 14)),
                  value: _rememberCredentials,
                  onChanged: (value) {
                    setState(() {
                      _rememberCredentials = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                
                const SizedBox(height: 16),
                
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                
                const SizedBox(height: 30), // Extra space for keyboard
                
                // Company logo at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Developed by IEC',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'www.iec.vu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/ieclogo.png',
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}