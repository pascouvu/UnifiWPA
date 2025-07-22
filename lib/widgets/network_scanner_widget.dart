import 'package:flutter/material.dart';
import '../services/network_scanner_service.dart';

class NetworkScannerWidget extends StatefulWidget {
  final Function(String) onIpSelected;
  final bool compact;

  const NetworkScannerWidget({
    super.key,
    required this.onIpSelected,
    this.compact = false,
  });

  @override
  State<NetworkScannerWidget> createState() => _NetworkScannerWidgetState();
}

class _NetworkScannerWidgetState extends State<NetworkScannerWidget> {
  bool _isScanning = false;
  List<String> _discoveredDevices = [];

  Future<void> _scanNetwork() async {
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    try {
      final devices = await NetworkScannerService.scanNetwork();
      
      setState(() {
        _discoveredDevices = devices;
        _isScanning = false;
      });
      
      if (devices.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No UniFi devices found on the network'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        _showDeviceSelectionDialog();
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning network: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeviceSelectionDialog() {
    if (_discoveredDevices.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.router, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Select UniFi Device')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _discoveredDevices.length,
            itemBuilder: (context, index) {
              final ip = _discoveredDevices[index];
              return ListTile(
                leading: const Icon(Icons.devices),
                title: Text(ip),
                subtitle: const Text('HTTPS service detected'),
                onTap: () {
                  widget.onIpSelected(ip);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      // Compact version (just the scan button)
      return IconButton(
        icon: _isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.search),
        tooltip: 'Scan Network',
        onPressed: _isScanning ? null : _scanNetwork,
      );
    } else {
      // Full version with button and explanation
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Can\'t find your device?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _scanNetwork,
            icon: _isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isScanning ? 'Scanning...' : 'Scan Network'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade100,
              foregroundColor: Colors.blue.shade800,
            ),
          ),
        ],
      );
    }
  }
}