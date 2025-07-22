import 'package:flutter/material.dart';
import '../models/unifi_models.dart';
import '../services/unifi_service.dart';

class NetworksScreen extends StatefulWidget {
  const NetworksScreen({super.key});

  @override
  State<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends State<NetworksScreen> {
  late UnifiService _unifiService;
  late UnifiSite _site;
  List<WirelessNetwork> _networks = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _unifiService = args['unifiService'] as UnifiService;
    _site = args['site'] as UnifiSite;
    _loadNetworks();
  }

  Future<void> _loadNetworks() async {
    try {
      final networks = await _unifiService.getWirelessNetworks(_site.id);
      setState(() {
        _networks = networks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading networks: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getSecurityIcon(String security) {
    switch (security.toLowerCase()) {
      case 'wpa2':
      case 'wpa3':
      case 'wpa':
        return '🔒';
      case 'wep':
        return '🔓';
      default:
        return '📶';
    }
  }

  Color _getSecurityColor(String security) {
    switch (security.toLowerCase()) {
      case 'wpa2':
      case 'wpa3':
        return Colors.green;
      case 'wpa':
        return Colors.orange;
      case 'wep':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_site.description),
            Text(
              'Wireless Networks',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _networks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No WPA networks found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Only secured networks can have passwords changed',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNetworks,
                  child: ListView.builder(
                    itemCount: _networks.length,
                    itemBuilder: (context, index) {
                      final network = _networks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getSecurityColor(network.security),
                            child: Text(
                              _getSecurityIcon(network.security),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            network.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Security: ${network.security.toUpperCase()}'),
                              Text(
                                network.enabled ? 'Enabled' : 'Disabled',
                                style: TextStyle(
                                  color: network.enabled ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.edit),
                          onTap: network.enabled
                              ? () {
                                  Navigator.pushNamed(
                                    context,
                                    '/change-password',
                                    arguments: {
                                      'unifiService': _unifiService,
                                      'site': _site,
                                      'network': network,
                                    },
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}