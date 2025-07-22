import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class CertificateHelperScreen extends StatefulWidget {
  final String controllerUrl;
  final VoidCallback onCertificateAccepted;

  const CertificateHelperScreen({
    super.key,
    required this.controllerUrl,
    required this.onCertificateAccepted,
  });

  @override
  State<CertificateHelperScreen> createState() => _CertificateHelperScreenState();
}

class _CertificateHelperScreenState extends State<CertificateHelperScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Troubleshooting'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '403 Forbidden Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'You can view networks but cannot change passwords due to permission restrictions.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Controller URL: ${widget.controllerUrl}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🔧 Solutions:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Solution 1: Admin account
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Solution 1: Use Admin Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your current account may have read-only access. Try logging in with a full administrator account.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Log in to your UniFi controller web interface',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '2. Go to Settings → Admins',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '3. Check if your account has "Super Administrator" role',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '4. Create a new admin account if needed',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Solution 2: Enable API access
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.api, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Solution 2: Enable API Access',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your UniFi controller may have API restrictions enabled.',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '1. Log in to your UniFi controller web interface',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '2. Go to Settings → Advanced → Advanced Features',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '3. Enable "Override inform host with controller hostname/IP"',
                        style: TextStyle(fontSize: 13),
                      ),
                      const Text(
                        '4. Save changes and restart the controller',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Solution 3: Use web interface
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.web, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Solution 3: Use Web Interface',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'As a workaround, you can use the UniFi web interface to change passwords.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // This would open the controller URL in the same tab
                          if (kIsWeb) {
                            // For web, we can redirect to the controller
                            // window.location.href = widget.controllerUrl;
                          }
                        },
                        icon: const Icon(Icons.launch),
                        label: const Text('Open Controller Web Interface'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Technical details
              ExpansionTile(
                title: const Text('Technical Details'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error: 403 Forbidden',
                          style: TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This error occurs when your account has permission to view networks but not to modify them. The UniFi API requires specific permissions for write operations.',
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Common causes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Read-only account permissions'),
                        const Text('• API access restrictions'),
                        const Text('• CSRF protection'),
                        const Text('• Session timeout'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}