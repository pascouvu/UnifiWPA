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
        title: const Text('Certificate Issue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Browser Security Limitation',
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
                    'Your UniFi controller uses a self-signed certificate. Browsers block web apps from accessing such sites for security reasons.',
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
            
            // Solution 1: Try HTTP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.http, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Solution 1: Try HTTP (Recommended)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Many UniFi controllers also accept HTTP connections, which don\'t have certificate issues.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // Show message to try HTTP
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Try changing the protocol to HTTP in the login screen'),
                            backgroundColor: Colors.blue,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Try HTTP Instead'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Solution 2: Direct access
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.open_in_browser, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Solution 2: Use UniFi Controller Directly',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Access your UniFi controller directly in the browser to change passwords.',
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
                      label: const Text('Open Controller'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Solution 3: Mobile app
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.phone_android, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Solution 3: Use Mobile App',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mobile apps don\'t have the same certificate restrictions as web browsers.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Consider using the official UniFi mobile app or install this app as an APK on Android'),
                            duration: Duration(seconds: 5),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('Learn More'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}