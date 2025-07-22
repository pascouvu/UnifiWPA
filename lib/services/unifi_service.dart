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
  String? _unifisesCookie;
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

  // Test basic connectivity first
  Future<bool> testConnectivity() async {
    // Check if running on web
    if (kIsWeb) {
      print('Running on web - CORS restrictions may apply');
      print('For full functionality, please use the Android APK on a mobile device');
      return false; // Skip connectivity test on web due to CORS
    }
    
    try {
      print('Testing connectivity to: $baseUrl');
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
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      // First test basic connectivity
      final canConnect = await testConnectivity();
      if (!canConnect && !kIsWeb) {
        print('Basic connectivity test failed');
        return false;
      }

      // Try multiple login endpoints - start with traditional UniFi controller
      final loginEndpoints = [
        '$baseUrl/api/login',           // Traditional UniFi controller
        '$baseUrl/api/auth/login',      // New UniFi Cloud/Network Application
      ];
      
      for (final endpoint in loginEndpoints) {
        try {
          print('Attempting login to: $endpoint');
          
          final loginData = {
            'username': username,
            'password': password,
            'remember': false,
            'strict': true,
          };
          
          final response = await _httpClient.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language': 'en-US,en;q=0.9',
              'Origin': baseUrl,
              'Referer': '$baseUrl/login',
            },
            body: jsonEncode(loginData),
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('Login request timed out', const Duration(seconds: 30));
            },
          );

          print('Login response status: ${response.statusCode}');
          print('Login response headers: ${response.headers}');
          print('Login response body: ${response.body}');
          
          if (response.statusCode == 200) {
            // Extract cookies
            final cookies = response.headers['set-cookie'];
            if (cookies != null) {
              _cookies = cookies;
              print('Cookies received: $cookies');
              
              // Extract unifises cookie specifically
              if (cookies.contains('unifises=')) {
                final unifisesMatch = RegExp(r'unifises=([^;]+)').firstMatch(cookies);
                if (unifisesMatch != null) {
                  _unifisesCookie = 'unifises=' + unifisesMatch.group(1)!;
                  print('✅ Extracted unifises cookie: $_unifisesCookie');
                }
              } else {
                // If no unifises cookie, extract any session cookie that might work
                final sessionMatch = RegExp(r'(SESSION|JSESSIONID|TOKEN)=([^;]+)').firstMatch(cookies);
                if (sessionMatch != null) {
                  _unifisesCookie = sessionMatch.group(0)!;
                  print('✅ Using session cookie as fallback: $_unifisesCookie');
                  
                  // If it's a TOKEN cookie, try to extract CSRF token from JWT
                  if (sessionMatch.group(1) == 'TOKEN') {
                    try {
                      final tokenValue = sessionMatch.group(2)!;
                      final parts = tokenValue.split('.');
                      if (parts.length == 3) {
                        // Decode JWT payload (base64)
                        final payload = parts[1];
                        // Add padding if needed
                        final paddedPayload = payload + '=' * (4 - payload.length % 4);
                        final decodedBytes = base64Decode(paddedPayload);
                        final decodedPayload = utf8.decode(decodedBytes);
                        final payloadJson = jsonDecode(decodedPayload);
                        
                        if (payloadJson['csrfToken'] != null) {
                          _csrfToken = payloadJson['csrfToken'];
                          print('✅ Extracted CSRF token from JWT: $_csrfToken');
                        }
                      }
                    } catch (e) {
                      print('Could not extract CSRF token from JWT: $e');
                    }
                  }
                }
              }
              
              // If we got a unifises or TOKEN cookie, consider it a successful login
              if (cookies.contains('unifises=') || cookies.contains('TOKEN=')) {
                print('✅ Found authentication cookie - login successful');
                return true;
              }
            }

            try {
              final responseData = jsonDecode(response.body);
              print('Login response data: $responseData');
              
              // Check for different success indicators
              if (responseData['meta']?['rc'] == 'ok') {
                print('✅ Login successful - meta rc ok');
                return true;
              } else if (responseData['unique_id'] != null || responseData['username'] != null) {
                // Your controller returns user info directly
                print('✅ Login successful - received user info');
                return true;
              } else if (responseData['success'] == true || responseData['authenticated'] == true) {
                print('✅ Login successful - success flag');
                return true;
              } else {
                print('Login failed from $endpoint - API response: ${responseData['meta']}');
                continue; // Try next endpoint
              }
            } catch (e) {
              print('Error parsing login response from $endpoint: $e');
              
              // If we have cookies but can't parse the response, still consider it a success
              if (cookies != null && (cookies.contains('unifises=') || cookies.contains('TOKEN='))) {
                print('✅ Login likely successful (have auth cookies but invalid JSON)');
                return true;
              }
              continue; // Try next endpoint
            }
          } else if (response.statusCode == 400) {
            print('Bad request from $endpoint - possibly invalid credentials');
            try {
              final responseData = jsonDecode(response.body);
              print('Error details: $responseData');
            } catch (e) {
              print('Could not parse error response: ${response.body}');
            }
            continue; // Try next endpoint
          } else {
            print('Login failed from $endpoint - HTTP ${response.statusCode}: ${response.body}');
            continue; // Try next endpoint
          }
        } catch (e) {
          print('Error trying login endpoint $endpoint: $e');
          continue; // Try next endpoint
        }
      }
      
      print('❌ All login endpoints failed');
      
      return false;
    } on SocketException catch (e) {
      print('Network error during login: $e');
      return false;
    } on TimeoutException catch (e) {
      print('Timeout error during login: $e');
      return false;
    } on FormatException catch (e) {
      print('JSON parsing error during login: $e');
      return false;
    } on HttpException catch (e) {
      print('HTTP error during login: $e');
      return false;
    } catch (e) {
      print('Unexpected login error: $e');
      return false;
    }
  }

  Future<List<UnifiSite>> getSites() async {
    if (_cookies == null) {
      throw Exception('Not authenticated');
    }

    // Use unifises cookie if available, otherwise fall back to all cookies
    final cookieToUse = _unifisesCookie ?? _cookies!;

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
          'Cookie': cookieToUse,
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

    // Use unifises cookie if available, otherwise fall back to all cookies
    final cookieToUse = _unifisesCookie ?? _cookies!;

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
              'Cookie': cookieToUse,
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

  // Add a method to validate authentication before password update
  Future<bool> validateAuthentication() async {
    if (_cookies == null) {
      print('❌ No cookies available');
      return false;
    }

    final cookieToUse = _unifisesCookie ?? _cookies!;
    print('🔍 Validating authentication with cookie: $cookieToUse');

    // Try multiple validation endpoints
    final validationEndpoints = [
      '$baseUrl/api/s/default/stat/health',  // Basic health check
      '$baseUrl/api/s/default/stat/sysinfo', // System info
      '$baseUrl/proxy/network/api/s/default/stat/health', // Proxy health check
      '$baseUrl/api/stat/health',            // Simple health check
    ];

    for (final endpoint in validationEndpoints) {
      try {
        print('🔍 Trying validation endpoint: $endpoint');
        final response = await _httpClient.get(
          Uri.parse(endpoint),
          headers: {
            'Cookie': cookieToUse,
            'User-Agent': 'UnifiPasswordChanger/1.0',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        print('Auth validation response from $endpoint: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('✅ Authentication is valid');
          return true;
        } else if (response.statusCode == 403) {
          print('❌ Authentication failed - 403 Forbidden');
          return false;
        }
        // Continue to next endpoint for other status codes
      } catch (e) {
        print('❌ Authentication validation error for $endpoint: $e');
        continue;
      }
    }
    
    print('❌ All validation endpoints failed');
    return false;
  }

  Future<bool> updateWpaPassword(String siteId, String networkId, String newPassword) async {
    if (_cookies == null) {
      throw Exception('Not authenticated');
    }

    // Skip validation since we have a valid session cookie
    print('🔍 Proceeding with password update using existing session...');

    try {
      print('Updating WPA password for network: $networkId in site: $siteId');
      print('Available cookies: $_cookies');
      print('Extracted unifises cookie: $_unifisesCookie');
      
      // First, get the current network configuration to understand the structure
      print('Step 1: Getting current network configuration...');
      Map<String, dynamic>? currentConfig;
      String? successfulEndpoint;
      
      final getEndpoints = [
        '$baseUrl/proxy/network/api/s/$siteId/rest/wlanconf/$networkId',
        '$baseUrl/proxy/network/api/s/default/rest/wlanconf/$networkId',
        '$baseUrl/api/s/$siteId/rest/wlanconf/$networkId',
        '$baseUrl/api/s/default/rest/wlanconf/$networkId',
      ];
      
      for (final getEndpoint in getEndpoints) {
        try {
          print('Trying to get config from: $getEndpoint');
          // Use unifises cookie if available, otherwise fall back to all cookies
          final cookieToUse = _unifisesCookie ?? _cookies!;
          
          final getResponse = await _httpClient.get(
            Uri.parse(getEndpoint),
            headers: {
              'Cookie': cookieToUse,
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 15));
          
          print('Config response from $getEndpoint: ${getResponse.statusCode}');
          
          if (getResponse.statusCode == 200) {
            print('Config response body: ${getResponse.body}');
            final responseData = jsonDecode(getResponse.body);
            if (responseData['data'] != null && responseData['data'].isNotEmpty) {
              currentConfig = responseData['data'][0];
              successfulEndpoint = getEndpoint;
              print('✅ Got current network config from $getEndpoint');
              
              // Extract unifises cookie if present
              if (_cookies!.contains('unifises=')) {
                final unifisesMatch = RegExp(r'unifises=([^;]+)').firstMatch(_cookies!);
                if (unifisesMatch != null) {
                  print('✅ Using unifises cookie: ${unifisesMatch.group(1)}');
                }
              }
              
              break;
            }
          }
        } catch (e) {
          print('Failed to get config from $getEndpoint: $e');
          continue;
        }
      }
      
      if (currentConfig == null || successfulEndpoint == null) {
        print('❌ Failed to get current network configuration');
        return false;
      }
      
      // Step 2: Use the EXACT SAME endpoint that worked for GET
      print('Step 2: Using the same endpoint that worked for GET: $successfulEndpoint');
      
      // Create a minimal update with just the password
      final updateData = {
        '_id': networkId,
        'x_passphrase': newPassword,
      };
      
      print('Sending update with data: $updateData');
      
      // Use unifises cookie if available, otherwise fall back to all cookies
      final cookieToUse = _unifisesCookie ?? _cookies!;
      print('Using cookie for PUT request: $cookieToUse');
      
      try {
        // Build headers with CSRF token if available
        final headers = <String, String>{
          'Cookie': cookieToUse,
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': baseUrl,
          'Origin': baseUrl,
        };
        
        // Add CSRF token if we have one
        if (_csrfToken != null) {
          headers['X-CSRF-Token'] = _csrfToken!;
          print('✅ Adding CSRF token to request: $_csrfToken');
        }
        
        final updateResponse = await _httpClient.put(
          Uri.parse(successfulEndpoint),
          headers: headers,
          body: jsonEncode(updateData),
        ).timeout(const Duration(seconds: 30));
        
        print('Password update response: ${updateResponse.statusCode}');
        print('Password update response body: ${updateResponse.body}');
        
        if (updateResponse.statusCode == 200) {
          try {
            final responseData = jsonDecode(updateResponse.body);
            if (responseData['meta']?['rc'] == 'ok' || 
                responseData['success'] == true ||
                responseData['data'] != null) {
              print('✅ Password updated successfully!');
              return true;
            } else {
              print('❌ API returned success status but meta indicates failure: ${responseData['meta']}');
            }
          } catch (e) {
            // Response might not be JSON, check for success indicators
            if (updateResponse.body.contains('success') || 
                updateResponse.body.contains('ok') ||
                updateResponse.body.contains('updated')) {
              print('✅ Password updated successfully (non-JSON response)');
              return true;
            }
          }
        } else if (updateResponse.statusCode == 201 || updateResponse.statusCode == 204) {
          // Some APIs return 201 (Created) or 204 (No Content) for successful updates
          print('✅ Password updated successfully (${updateResponse.statusCode} response)');
          return true;
        } else {
          print('❌ Failed with ${updateResponse.statusCode}: ${updateResponse.body}');
          
          // If we still get a 403, try with a full config update
          if (updateResponse.statusCode == 403 && currentConfig != null) {
            print('Trying with full config update as fallback...');
            
            // Create a full config update
            final fullUpdateData = {
              ...currentConfig,
              'x_passphrase': newPassword,
            };
            
            // Build headers for full update with CSRF token if available
            final fullHeaders = <String, String>{
              'Cookie': cookieToUse,
              'Content-Type': 'application/json',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
              'Accept': 'application/json',
              'X-Requested-With': 'XMLHttpRequest',
              'Referer': baseUrl,
              'Origin': baseUrl,
            };
            
            // Add CSRF token if we have one
            if (_csrfToken != null) {
              fullHeaders['X-CSRF-Token'] = _csrfToken!;
              print('✅ Adding CSRF token to full update request: $_csrfToken');
            }
            
            final fullUpdateResponse = await _httpClient.put(
              Uri.parse(successfulEndpoint),
              headers: fullHeaders,
              body: jsonEncode(fullUpdateData),
            ).timeout(const Duration(seconds: 30));
            
            print('Full update response: ${fullUpdateResponse.statusCode}');
            print('Full update response body: ${fullUpdateResponse.body}');
            
            if (fullUpdateResponse.statusCode == 200 || 
                fullUpdateResponse.statusCode == 201 || 
                fullUpdateResponse.statusCode == 204) {
              print('✅ Password updated successfully with full config update!');
              return true;
            }
          }
        }
      } catch (e) {
        print('Error updating password: $e');
      }
      
      print('❌ Password update failed');
      print('💡 This might be due to:');
      print('   • Insufficient permissions (need admin access)');
      print('   • Different API version on your controller');
      print('   • Network is managed by a different system');
      
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