import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../models/unifi_models.dart';

class UnifiService {
  String baseUrl;
  String? _cookies;
  String? _csrfToken;
  late http.Client _httpClient;

  UnifiService({required this.baseUrl}) {
    _httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    if (kIsWeb) {
      // Web platform - use default client (certificate issues handled by browser)
      return http.Client();
    } else {
      // Mobile/Desktop platform - create client that accepts bad certificates
      final httpClient = HttpClient()
        ..badCertificateCallback = (X509Certificate cert, String host, int port) {
          print('🔒 Accepting certificate for $host:$port');
          print('   Subject: ${cert.subject}');
          print('   Issuer: ${cert.issuer}');
          return true; // Accept all certificates
        };
      
      return IOClient(httpClient);
    }
  }

  // Test connectivity to local controller
  Future<bool> testConnectivity() async {
    try {
      print('Testing connectivity to local controller: $baseUrl');
      
      if (kIsWeb) {
        print('⚠️  Running in browser - certificate issues may prevent access');
        print('💡 If your controller uses self-signed certificates:');
        print('   1. Visit $baseUrl in a new browser tab');
        print('   2. Accept the security warning/certificate');
        print('   3. Then return to this app and try again');
      }
      
      final response = await _httpClient.get(
        Uri.parse(baseUrl),
        headers: {
          'User-Agent': 'UnifiPasswordChanger/1.0',
        },
      ).timeout(const Duration(seconds: 10));
      
      print('Connectivity test - Status: ${response.statusCode}');
      return response.statusCode < 500; // Accept any non-server error
    } catch (e) {
      print('Connectivity test failed: $e');
      
      if (kIsWeb && e.toString().contains('Failed to fetch')) {
        print('🔒 Certificate/CORS issue detected in browser');
        print('📋 Solutions:');
        print('   • Visit $baseUrl directly and accept certificate');
        print('   • Use HTTP instead of HTTPS if available');
        print('   • Add certificate exception in browser');
      }
      
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    print('🏠 Attempting login to local UniFi Controller: $baseUrl');
    return await loginToLocalController(baseUrl, username, password);
  }

  // Alternative method for local controller authentication
  Future<bool> loginToLocalController(String controllerUrl, String username, String password) async {
    try {
      print('Attempting login to local controller: $controllerUrl');
      
      // Step 1: Get login page - try different endpoints
      final loginEndpoints = [
        '$controllerUrl/login',
        '$controllerUrl/manage/account/login',
        '$controllerUrl/',
      ];
      
      String? loginPageUrl;
      String? loginPageBody;
      String? sessionCookies;
      
      for (final endpoint in loginEndpoints) {
        try {
          print('Trying login page: $endpoint');
          final loginPageResponse = await _httpClient.get(
            Uri.parse(endpoint),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.5',
            },
          ).timeout(const Duration(seconds: 15));

          print('Login page response from $endpoint: ${loginPageResponse.statusCode}');
          
          if (loginPageResponse.statusCode == 200) {
            loginPageUrl = endpoint;
            loginPageBody = loginPageResponse.body;
            
            // Extract session cookies
            if (loginPageResponse.headers['set-cookie'] != null) {
              sessionCookies = loginPageResponse.headers['set-cookie'];
              print('Session cookies from login page: $sessionCookies');
            }
            
            print('Successfully accessed login page at: $endpoint');
            break;
          }
        } catch (e) {
          print('Failed to access $endpoint: $e');
          continue;
        }
      }

      if (loginPageUrl == null || loginPageBody == null) {
        print('Failed to access any login page');
        return false;
      }

      // Step 2: Extract CSRF token from login page
      String? csrfToken;
      final csrfPatterns = [
        RegExp(r'name="csrf_token"[^>]*value="([^"]*)"'),
        RegExp(r'name="_token"[^>]*value="([^"]*)"'),
        RegExp(r'"csrf_token":"([^"]*)"'),
        RegExp(r'csrf[_-]?token["\s]*:["\s]*([^"]*)"'),
      ];
      
      for (final pattern in csrfPatterns) {
        final match = pattern.firstMatch(loginPageBody);
        if (match != null) {
          csrfToken = match.group(1);
          print('CSRF token extracted: $csrfToken');
          break;
        }
      }

      // Step 3: Try different authentication endpoints
      final authEndpoints = [
        '$controllerUrl/api/auth/login',
        '$controllerUrl/api/login',
        '$controllerUrl/login',
      ];

      for (final authEndpoint in authEndpoints) {
        try {
          print('Trying authentication endpoint: $authEndpoint');
          
          // Try both JSON and form-encoded data
          final attempts = [
            // Form-encoded (most common for web forms)
            {
              'contentType': 'application/x-www-form-urlencoded',
              'body': [
                'username=${Uri.encodeComponent(username)}',
                'password=${Uri.encodeComponent(password)}',
                'remember=on',
                if (csrfToken != null) 'csrf_token=${Uri.encodeComponent(csrfToken)}',
                if (csrfToken != null) '_token=${Uri.encodeComponent(csrfToken)}',
              ].join('&'),
            },
            // JSON format
            {
              'contentType': 'application/json',
              'body': jsonEncode({
                'username': username,
                'password': password,
                'remember': true,
                if (csrfToken != null) 'csrf_token': csrfToken,
                if (csrfToken != null) '_token': csrfToken,
              }),
            },
          ];

          for (final attempt in attempts) {
            print('Trying ${attempt['contentType']} for $authEndpoint');
            
            final headers = {
              'Content-Type': attempt['contentType']!,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language': 'en-US,en;q=0.5',
              'Referer': loginPageUrl,
              'Origin': controllerUrl,
            };

            // Add session cookies if available
            if (sessionCookies != null) {
              headers['Cookie'] = sessionCookies;
            }

            final loginResponse = await _httpClient.post(
              Uri.parse(authEndpoint),
              headers: headers,
              body: attempt['body']!,
            ).timeout(const Duration(seconds: 30));

            print('Auth response from $authEndpoint (${attempt['contentType']}): ${loginResponse.statusCode}');
            print('Response headers: ${loginResponse.headers}');
            print('Response body: ${loginResponse.body}');
            
            if (loginResponse.statusCode == 200) {
              final cookies = loginResponse.headers['set-cookie'];
              if (cookies != null) {
                _cookies = cookies;
                print('✅ Local controller authentication successful');
                return true;
              }
              
              // Check response body for success indicators
              try {
                final responseData = jsonDecode(loginResponse.body);
                if (responseData['meta']?['rc'] == 'ok' || 
                    responseData['success'] == true ||
                    responseData['authenticated'] == true) {
                  _cookies = sessionCookies ?? 'authenticated=true';
                  print('✅ Local controller authentication successful (JSON response)');
                  return true;
                }
              } catch (e) {
                // Not JSON, check for success indicators in text
                if (loginResponse.body.contains('success') || 
                    loginResponse.body.contains('dashboard') ||
                    loginResponse.body.contains('authenticated')) {
                  _cookies = sessionCookies ?? 'authenticated=true';
                  print('✅ Local controller authentication successful (text response)');
                  return true;
                }
              }
            } else if (loginResponse.statusCode == 302 || loginResponse.statusCode == 301) {
              // Redirect might indicate successful login
              final location = loginResponse.headers['location'];
              print('Redirect to: $location');
              
              if (location != null && !location.contains('login') && !location.contains('error')) {
                final cookies = loginResponse.headers['set-cookie'];
                _cookies = cookies ?? sessionCookies ?? 'authenticated=true';
                print('✅ Local controller authentication successful (redirect)');
                return true;
              }
            }
          }
        } catch (e) {
          print('Error trying auth endpoint $authEndpoint: $e');
          continue;
        }
      }
      
      print('❌ All authentication attempts failed');
      return false;
    } catch (e) {
      print('Local controller login error: $e');
      return false;
    }
  }

  Future<List<UnifiSite>> getSites() async {
    if (_cookies == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Checking for sites or going directly to networks...');
      
      // For local controllers, try to get networks directly first
      final networks = await getWirelessNetworks('default');
      if (networks.isNotEmpty) {
        print('Found networks directly, creating default site');
        return [
          UnifiSite(
            id: 'default',
            name: 'default',
            description: 'Local Controller',
            isOwner: true,
          )
        ];
      }
      
      // If no direct networks, try the sites API
      print('Fetching sites from: $baseUrl/api/self/sites');
      
      final response = await _httpClient.get(
        Uri.parse('$baseUrl/api/self/sites'),
        headers: {
          'Cookie': _cookies!,
          'User-Agent': 'UnifiPasswordChanger/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('Sites response status: ${response.statusCode}');
      print('Sites response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle different response structures
        List<dynamic> sitesData;
        if (responseData['data'] != null) {
          sitesData = responseData['data'] as List;
        } else if (responseData is List) {
          sitesData = responseData;
        } else {
          print('No sites found, creating default site');
          return [
            UnifiSite(
              id: 'default',
              name: 'default',
              description: 'Local Controller',
              isOwner: true,
            )
          ];
        }
        
        print('Found ${sitesData.length} sites');
        
        return sitesData
            .map((site) => UnifiSite.fromJson(site))
            .toList();
      } else {
        print('Sites API failed, creating default site');
        return [
          UnifiSite(
            id: 'default',
            name: 'default',
            description: 'Local Controller',
            isOwner: true,
          )
        ];
      }
    } catch (e) {
      print('Get sites error: $e, creating default site');
      return [
        UnifiSite(
          id: 'default',
          name: 'default',
          description: 'Local Controller',
          isOwner: true,
        )
      ];
    }
  }

  Future<List<WirelessNetwork>> getWirelessNetworks(String siteId) async {
    if (_cookies == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Fetching wireless networks for site: $siteId');
      
      // Try different API endpoints for local controllers
      final networkEndpoints = [
        '$baseUrl/proxy/network/api/s/$siteId/rest/wlanconf',
        '$baseUrl/api/s/$siteId/rest/wlanconf',
        '$baseUrl/api/s/default/rest/wlanconf',
        '$baseUrl/proxy/network/api/s/default/rest/wlanconf',
        '$baseUrl/api/rest/wlanconf',
        '$baseUrl/proxy/network/api/rest/wlanconf',
      ];
      
      for (final endpoint in networkEndpoints) {
        try {
          print('Trying networks endpoint: $endpoint');
          
          final response = await _httpClient.get(
            Uri.parse(endpoint),
            headers: {
              'Cookie': _cookies!,
              'User-Agent': 'UnifiPasswordChanger/1.0',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 15));

          print('Networks response from $endpoint: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            print('Networks response body: ${response.body}');
            
            final responseData = jsonDecode(response.body);
            
            List<dynamic> networksData;
            if (responseData['data'] != null) {
              networksData = responseData['data'] as List;
            } else if (responseData is List) {
              networksData = responseData;
            } else {
              print('Unexpected networks response structure from $endpoint: $responseData');
              continue;
            }
            
            final networks = networksData
                .map((network) => WirelessNetwork.fromJson(network))
                .where((network) => network.security != 'open') // Only WPA networks
                .toList();
                
            print('✅ Found ${networks.length} secured wireless networks from $endpoint');
            return networks;
          } else {
            print('Failed to fetch from $endpoint: ${response.statusCode}');
          }
        } catch (e) {
          print('Error trying endpoint $endpoint: $e');
          continue;
        }
      }
      
      print('❌ All network endpoints failed');
      return [];
    } catch (e) {
      print('Get wireless networks error: $e');
      return [];
    }
  }

  Future<bool> updateWpaPassword(String siteId, String networkId, String newPassword) async {
    if (_cookies == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Updating WPA password for network: $networkId in site: $siteId');
      
      // First, get the current network configuration to understand the structure
      print('Step 1: Getting current network configuration...');
      Map<String, dynamic>? currentConfig;
      
      final getEndpoints = [
        '$baseUrl/api/s/default/rest/wlanconf/$networkId',
        '$baseUrl/proxy/network/api/s/default/rest/wlanconf/$networkId',
        '$baseUrl/api/s/$siteId/rest/wlanconf/$networkId',
      ];
      
      for (final getEndpoint in getEndpoints) {
        try {
          final getResponse = await _httpClient.get(
            Uri.parse(getEndpoint),
            headers: {
              'Cookie': _cookies!,
              'User-Agent': 'UnifiPasswordChanger/1.0',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 15));
          
          if (getResponse.statusCode == 200) {
            final responseData = jsonDecode(getResponse.body);
            if (responseData['data'] != null && responseData['data'].isNotEmpty) {
              currentConfig = responseData['data'][0];
              print('✅ Got current network config from $getEndpoint');
              break;
            }
          }
        } catch (e) {
          print('Failed to get config from $getEndpoint: $e');
          continue;
        }
      }
      
      // Step 2: Try different update approaches
      final updateAttempts = <Map<String, dynamic>>[
        // Method 1: Full config update with current settings
        if (currentConfig != null) {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'data': {
            ...currentConfig,
            'x_passphrase': newPassword,
          },
        },
        
        // Method 2: Minimal update with just password
        {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'data': {'x_passphrase': newPassword},
        },
        
        // Method 3: Try with different password field names
        {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'data': {
            'x_passphrase': newPassword,
            'wpa_psk': newPassword,
            'passphrase': newPassword,
          },
        },
        
        // Method 4: Try POST instead of PUT
        {
          'method': 'POST',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'data': {'x_passphrase': newPassword},
        },
        
        // Method 5: Try with proxy endpoint
        {
          'method': 'PUT',
          'endpoint': '$baseUrl/proxy/network/api/s/default/rest/wlanconf/$networkId',
          'data': {'x_passphrase': newPassword},
        },
        
        // Method 6: Try alternative API paths
        {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/upd/wlanconf/$networkId',
          'data': {'x_passphrase': newPassword},
        },
        
        // Method 7: Try with cmd parameter (some UniFi versions use this)
        {
          'method': 'POST',
          'endpoint': '$baseUrl/api/s/default/cmd/stamgr',
          'data': {
            'cmd': 'set-wlan-conf',
            '_id': networkId,
            'x_passphrase': newPassword,
          },
        },
        
        // Method 8: Try form-encoded instead of JSON
        {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'contentType': 'application/x-www-form-urlencoded',
          'data': 'x_passphrase=${Uri.encodeComponent(newPassword)}',
        },
        
        // Method 9: Try with CSRF token if we have one
        if (_csrfToken != null) {
          'method': 'PUT',
          'endpoint': '$baseUrl/api/s/default/rest/wlanconf/$networkId',
          'data': {
            'x_passphrase': newPassword,
            'csrf_token': _csrfToken,
          },
        },
      ];

      for (final attempt in updateAttempts) {
        if (attempt == null) continue;
        
        try {
          print('Trying ${attempt['method']} to ${attempt['endpoint']}');
          
          final headers = <String, String>{
            'Cookie': _cookies!,
            'Content-Type': attempt['contentType'] as String? ?? 'application/json',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'application/json, text/plain, */*',
            'X-Requested-With': 'XMLHttpRequest',
            'Referer': baseUrl,
            'Origin': baseUrl,
          };
          
          String body;
          if (attempt['contentType'] == 'application/x-www-form-urlencoded') {
            body = attempt['data'] as String;
          } else {
            body = jsonEncode(attempt['data']);
          }
          
          http.Response response;
          
          if (attempt['method'] == 'PUT') {
            response = await _httpClient.put(
              Uri.parse(attempt['endpoint'] as String),
              headers: headers,
              body: body,
            ).timeout(const Duration(seconds: 30));
          } else {
            response = await _httpClient.post(
              Uri.parse(attempt['endpoint'] as String),
              headers: headers,
              body: body,
            ).timeout(const Duration(seconds: 30));
          }

          print('Password update response from ${attempt['endpoint']}: ${response.statusCode}');
          print('Response headers: ${response.headers}');
          print('Response body: ${response.body}');

          if (response.statusCode == 200) {
            try {
              final responseData = jsonDecode(response.body);
              if (responseData['meta']?['rc'] == 'ok' || 
                  responseData['success'] == true ||
                  responseData['data'] != null) {
                print('✅ Password updated successfully via ${attempt['endpoint']}');
                return true;
              } else {
                print('❌ API returned success status but meta indicates failure: ${responseData['meta']}');
              }
            } catch (e) {
              // Response might not be JSON, check for success indicators
              if (response.body.contains('success') || 
                  response.body.contains('ok') ||
                  response.body.contains('updated')) {
                print('✅ Password updated successfully (non-JSON response)');
                return true;
              }
            }
          } else if (response.statusCode == 201 || response.statusCode == 204) {
            // Some APIs return 201 (Created) or 204 (No Content) for successful updates
            print('✅ Password updated successfully (${response.statusCode} response)');
            return true;
          } else if (response.statusCode == 403) {
            print('❌ 403 Forbidden - checking if authentication is still valid...');
            // Try to refresh authentication or check permissions
            continue;
          } else {
            print('❌ Failed with ${response.statusCode}: ${response.body}');
          }
        } catch (e) {
          print('Error trying ${attempt['endpoint']}: $e');
          continue;
        }
      }
      
      print('❌ All password update attempts failed');
      print('💡 This might be due to:');
      print('   • Insufficient permissions (need admin access)');
      print('   • Different API version on your controller');
      print('   • Network is managed by a different system');
      print('   • Controller requires additional authentication');
      
      return false;
    } catch (e) {
      print('Update password error: $e');
      return false;
    }
  }

  void logout() {
    _cookies = null;
    _csrfToken = null;
  }

  void dispose() {
    _httpClient.close();
  }
}