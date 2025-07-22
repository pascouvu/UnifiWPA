import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // For debugPrint

class NetworkScannerService {
  static const int UDP_PORT = 10001;
  static const int HTTPS_PORT = 443;
  static const int SCAN_TIMEOUT_MS = 2000; // Increased timeout for discovery
  static const int CONNECTION_TIMEOUT_MS = 3000; // Timeout for HTTPS connection test
  
  // Scan for UniFi devices on the network
  static Future<List<String>> scanNetwork() async {
    debugPrint('🔍 Starting network scan for UniFi devices...');
    
    if (kIsWeb) {
      debugPrint('❌ Web platform doesn\'t support UDP scanning');
      return [];
    }
    
    final List<String> discoveredDevices = [];
    
    try {
      // Get the local IP address to determine network range
      debugPrint('📡 Getting network interfaces...');
      final interfaces = await NetworkInterface.list();
      debugPrint('📡 Found ${interfaces.length} network interfaces');
      
      if (interfaces.isEmpty) {
        debugPrint('❌ No network interfaces found');
        return [];
      }
      
      // Find a suitable interface (usually the first non-loopback IPv4 interface)
      NetworkInterface? targetInterface;
      for (var interface in interfaces) {
        debugPrint('📡 Checking interface: ${interface.name}');
        
        final addresses = interface.addresses.where((addr) => 
          addr.type == InternetAddressType.IPv4 && 
          !addr.address.startsWith('127.')
        ).toList();
        
        if (addresses.isNotEmpty) {
          targetInterface = interface;
          debugPrint('✅ Selected interface: ${interface.name} with addresses: ${addresses.map((a) => a.address).join(', ')}');
          break;
        }
      }
      
      if (targetInterface == null) {
        debugPrint('❌ No suitable network interface found');
        return [];
      }
      
      // Get the network prefix (e.g., 192.168.1)
      final address = targetInterface.addresses.firstWhere(
        (addr) => addr.type == InternetAddressType.IPv4 && !addr.address.startsWith('127.'),
        orElse: () => InternetAddress('0.0.0.0'),
      );
      
      if (address.address == '0.0.0.0') {
        debugPrint('❌ Could not determine local IP address');
        return [];
      }
      
      final parts = address.address.split('.');
      if (parts.length != 4) {
        debugPrint('❌ Invalid IP address format: ${address.address}');
        return [];
      }
      
      final networkPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
      final localIpLastOctet = int.parse(parts[3]);
      
      debugPrint('📡 Local IP: ${address.address}');
      debugPrint('�  Network prefix: $networkPrefix.* (/24 subnet)');
      
      // Create a UDP socket for discovery
      debugPrint('🔍 Creating UDP socket for discovery...');
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 
        0, // Use any available port
      );
      
      // Set up a listener for responses
      final discoveredIps = <String>{};
      
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final senderIp = datagram.address.address;
            debugPrint('✅ Received discovery response from: $senderIp');
            
            try {
              // Try to parse the response as JSON
              final responseData = utf8.decode(datagram.data);
              debugPrint('📦 Response data: $responseData');
              
              // Add the IP to the discovered devices
              discoveredIps.add(senderIp);
            } catch (e) {
              debugPrint('⚠️ Could not parse response from $senderIp: $e');
              // Still add the IP since it responded to our discovery packet
              discoveredIps.add(senderIp);
            }
          }
        }
      });
      
      // Send discovery packets to each IP in the /24 subnet
      debugPrint('📡 Sending discovery packets to the /24 subnet...');
      
      // UniFi discovery packet (specific format that UniFi devices recognize)
      final discoveryPacket = utf8.encode('{"cmd":"ubntDiscovery"}');
      
      // Send to broadcast address first
      final broadcastAddress = '$networkPrefix.255';
      debugPrint('📡 Sending discovery packet to broadcast address: $broadcastAddress');
      socket.send(
        discoveryPacket,
        InternetAddress(broadcastAddress),
        UDP_PORT,
      );
      
      // Then send to each IP in the subnet
      debugPrint('📡 Scanning all IPs in subnet $networkPrefix.1-254');
      for (int i = 1; i <= 254; i++) {
        final ip = '$networkPrefix.$i';
        
        // Skip our own IP to avoid confusion
        if (i == localIpLastOctet) {
          debugPrint('📡 Skipping local IP: $ip');
          continue;
        }
        
        socket.send(
          discoveryPacket,
          InternetAddress(ip),
          UDP_PORT,
        );
        
        // Add a small delay every few IPs to avoid flooding the network
        if (i % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      
      // Wait for responses
      debugPrint('⏳ Waiting for discovery responses (${SCAN_TIMEOUT_MS}ms)...');
      await Future.delayed(Duration(milliseconds: SCAN_TIMEOUT_MS));
      
      // Close the socket after the timeout
      socket.close();
      
      debugPrint('✅ Discovery complete. Found ${discoveredIps.length} devices responding to UniFi discovery');
      
      if (discoveredIps.isEmpty) {
        debugPrint('❌ No devices responded to UniFi discovery');
        return [];
      }
      
      // Check which devices have HTTPS service
      debugPrint('🔍 Checking which devices have HTTPS service on port $HTTPS_PORT...');
      final validControllers = <String>[];
      final client = http.Client();
      
      for (final ip in discoveredIps) {
        try {
          debugPrint('🔍 Checking HTTPS on $ip:$HTTPS_PORT');
          
          final response = await client.get(
            Uri.parse('https://$ip:$HTTPS_PORT'),
          ).timeout(Duration(milliseconds: CONNECTION_TIMEOUT_MS));
          
          debugPrint('✅ HTTPS connection successful to $ip:$HTTPS_PORT (Status: ${response.statusCode})');
          validControllers.add(ip);
        } catch (e) {
          debugPrint('❌ HTTPS connection failed to $ip:$HTTPS_PORT: $e');
          // Still add the device to the list since it responded to UniFi discovery
          validControllers.add(ip);
        }
      }
      
      client.close();
      
      if (validControllers.isEmpty) {
        debugPrint('❌ No UniFi devices found');
      } else {
        debugPrint('✅ Found UniFi devices: ${validControllers.join(', ')}');
      }
      
      return validControllers;
    } catch (e) {
      debugPrint('❌ Error scanning network: $e');
      return [];
    }
  }
}