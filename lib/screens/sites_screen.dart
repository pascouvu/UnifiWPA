import 'package:flutter/material.dart';
import '../models/unifi_models.dart';
import '../services/unifi_service.dart';

class SitesScreen extends StatefulWidget {
  const SitesScreen({super.key});

  @override
  State<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  late UnifiService _unifiService;
  List<UnifiSite> _sites = [];
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unifiService = ModalRoute.of(context)!.settings.arguments as UnifiService;
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final sites = await _unifiService.getSites();
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout() {
    _unifiService.logout();
    Navigator.pushReplacementNamed(context, '/login');
  }
  
  void _appLogout() {
    _unifiService.logout();
    Navigator.pushReplacementNamed(context, '/app-login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Site'),
        actions: [
          // UniFi logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout from UniFi',
            onPressed: _logout,
          ),
          // App logout
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'App Admin Logout',
            onPressed: _appLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sites.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.business,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No sites found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSites,
                  child: ListView.builder(
                    itemCount: _sites.length,
                    itemBuilder: (context, index) {
                      final site = _sites[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: site.isOwner ? Colors.green : Colors.blue,
                            child: Icon(
                              site.isOwner ? Icons.admin_panel_settings : Icons.business,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            site.description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Site ID: ${site.name}'),
                              Text(
                                site.isOwner ? 'Admin Access' : 'Limited Access',
                                style: TextStyle(
                                  color: site.isOwner ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/networks',
                              arguments: {
                                'unifiService': _unifiService,
                                'site': site,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}