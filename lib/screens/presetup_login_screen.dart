import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../widgets/network_scanner_widget.dart';

class PresetupLoginScreen extends StatefulWidget {
  const PresetupLoginScreen({super.key});

  @override
  State<PresetupLoginScreen> createState() => _PresetupLoginScreenState();
}

class _PresetupLoginScreenState extends State<PresetupLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _unifiUsernameController = TextEditingController();
  final _unifiPasswordController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPresetupInfo();
  }

  Future<void> _loadPresetupInfo() async {
    final presetupInfo = await StorageService.getPresetupInfo();
    setState(() {
      _unifiUsernameController.text = presetupInfo['username'] ?? '';
      _unifiPasswordController.text = presetupInfo['password'] ?? '';
      _ipController.text = presetupInfo['ip'] ?? '';
      _portController.text = presetupInfo['port'] ?? '443';
    });
  }

  Future<void> _savePresetupInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await StorageService.savePresetupInfo(
        username: _unifiUsernameController.text.trim(),
        password: _unifiPasswordController.text,
        ip: _ipController.text.trim(),
        port: _portController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login information saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
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

  void _updateIpField(String ip) {
    setState(() {
      _ipController.text = ip;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Presetup Login Information'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Always navigate to login screen instead of just popping
            Navigator.of(context).pushReplacementNamed('/login');
          },
          tooltip: 'Return to Login',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Presetup Login Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'These credentials will be auto-filled on the login screen',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Username field
                TextFormField(
                  controller: _unifiUsernameController,
                  decoration: const InputDecoration(
                    labelText: 'UniFi Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter UniFi username';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Password field (always obscured)
                TextFormField(
                  controller: _unifiPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'UniFi Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true, // Always obscured
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter UniFi password';
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
                          labelText: 'Device IP',
                          prefixIcon: const Icon(Icons.router),
                          suffixIcon: NetworkScannerWidget(
                            onIpSelected: _updateIpField,
                            compact: true,
                          ),
                          border: const OutlineInputBorder(),
                          hintText: '192.168.1.100',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter device IP';
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
                
                // Network scanner help text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Can\'t find your UniFi device?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Click the search icon next to the IP field to scan your network for UniFi devices.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Save button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePresetupInfo,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Save',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Company logo at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Developed by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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
    _unifiUsernameController.dispose();
    _unifiPasswordController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}