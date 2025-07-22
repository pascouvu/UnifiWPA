import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/unifi_service.dart';
import '../services/storage_service.dart';
import 'debug_screen.dart';
import 'certificate_helper_screen.dart';
import '../secret.dart';

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
  bool _obscurePassword = true;
  bool _useHttps = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    // First try to load from secret.dart if available
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
          // Show detailed error message with certificate solution
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.security, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('Certificate Issue')),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your UniFi controller uses a self-signed certificate that browsers block by default.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('🔧 Solutions:'),
                    const SizedBox(height: 8),
                    const Text('• Try HTTP instead of HTTPS'),
                    const Text('• Use port 80 or 8080'),
                    const Text('• Or accept certificate in browser'),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Current URL: ${_buildControllerUrl()}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Switch to HTTP
                    setState(() {
                      _useHttps = false;
                      _portController.text = '80';
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switched to HTTP. Try logging in again.'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  child: const Text('Try HTTP'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ],
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
        title: const Text('Unifi Login'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                ),
              );
            },
            tooltip: 'Network Debug',
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
                const SizedBox(height: 10),
                const Icon(
                  Icons.wifi_lock,
                  size: 50,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unifi Password Changer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Compact info card for mobile
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Local UniFi Controller Access',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'For certificate issues:',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            TextButton.icon(
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
                              icon: const Icon(Icons.help, size: 14),
                              label: const Text('Help', style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                minimumSize: const Size(0, 30),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
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
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // IP and Port fields
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Controller IP',
                          prefixIcon: Icon(Icons.router),
                          border: OutlineInputBorder(),
                          hintText: '192.168.1.100',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                
                // Protocol selection
                Row(
                  children: [
                    const Icon(Icons.security, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    const Text('Protocol:', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('HTTPS', style: TextStyle(fontSize: 12)),
                            selected: _useHttps,
                            onSelected: (selected) {
                              setState(() {
                                _useHttps = true;
                                if (_portController.text == '80') {
                                  _portController.text = '443';
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('HTTP', style: TextStyle(fontSize: 12)),
                            selected: !_useHttps,
                            onSelected: (selected) {
                              setState(() {
                                _useHttps = false;
                                if (_portController.text == '443') {
                                  _portController.text = '80';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
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
                
                const SizedBox(height: 20), // Extra space for keyboard
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