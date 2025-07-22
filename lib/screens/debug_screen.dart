import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _runConnectivityTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
    });

    _addLog('Starting connectivity tests...');

    // Test 1: Basic internet connectivity
    try {
      _addLog('Test 1: Basic internet connectivity');
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 10),
      );
      _addLog('✅ Internet connectivity: ${response.statusCode}');
    } catch (e) {
      _addLog('❌ Internet connectivity failed: $e');
    }

    // Test 2: Account.ui.com reachability
    try {
      _addLog('Test 2: Account.ui.com reachability');
      final response = await http.get(Uri.parse('https://account.ui.com')).timeout(
        const Duration(seconds: 15),
      );
      _addLog('✅ Account.ui.com reachable: ${response.statusCode}');
    } catch (e) {
      _addLog('❌ Account.ui.com unreachable: $e');
    }

    // Test 3: Auth API endpoint test
    try {
      _addLog('Test 3: Auth API endpoint test');
      final response = await http.post(
        Uri.parse('https://account.ui.com/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          'Origin': 'https://account.ui.com',
          'Referer': 'https://account.ui.com/login',
        },
        body: jsonEncode({
          'username': 'test@example.com',
          'password': 'testpassword',
        }),
      ).timeout(const Duration(seconds: 15));
      
      _addLog('✅ Auth API endpoint responds: ${response.statusCode}');
      _addLog('Response headers: ${response.headers}');
      _addLog('Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
    } catch (e) {
      _addLog('❌ Auth API endpoint test failed: $e');
    }

    // Test 4: Unifi.ui.com reachability (for API calls after auth)
    try {
      _addLog('Test 4: Unifi.ui.com reachability');
      final response = await http.get(Uri.parse('https://unifi.ui.com')).timeout(
        const Duration(seconds: 15),
      );
      _addLog('✅ Unifi.ui.com reachable: ${response.statusCode}');
    } catch (e) {
      _addLog('❌ Unifi.ui.com unreachable: $e');
    }

    // Test 5: Alternative endpoints
    final alternativeEndpoints = [
      'https://api.ui.com',
      'https://sso.ui.com',
    ];

    for (final endpoint in alternativeEndpoints) {
      try {
        _addLog('Test: Alternative endpoint $endpoint');
        final response = await http.get(Uri.parse(endpoint)).timeout(
          const Duration(seconds: 10),
        );
        _addLog('✅ $endpoint reachable: ${response.statusCode}');
      } catch (e) {
        _addLog('❌ $endpoint unreachable: $e');
      }
    }

    _addLog('All tests completed!');
    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRunning ? null : _runConnectivityTests,
                child: _isRunning
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Running Tests...'),
                        ],
                      )
                    : const Text('Run Connectivity Tests'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}