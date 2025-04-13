// user_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static const String _baseUrl = 'https://uyoddnypml.execute-api.eu-west-1.amazonaws.com/dev/api/v1';
  
  // In-memory cache for current session
  static Map<String, dynamic>? _cachedUserData;
  
  // Get user data - first tries cache, then local storage, then API
  Future<Map<String, dynamic>?> getUserData(String username) async {
    // Return cached data if available
    if (_cachedUserData != null) {
      return _cachedUserData;
    }
    
    // Try to get from local storage
    final storedData = await _loadUserDataFromStorage();
    if (storedData != null) {
      _cachedUserData = storedData;
      return storedData;
    }
    
    // Fetch from API if not in cache or storage
    try {
      final userData = await fetchUserDetails(username);
      // Cache the data
      await _saveUserDataToStorage(userData);
      _cachedUserData = userData;
      return userData;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Fetch fresh user details from API with detailed logging
  Future<Map<String, dynamic>> fetchUserDetails(String username) async {
    try {
      final token = await _getIDToken();
      if (token == null) throw Exception('No access token available');
      
      final url = '$_baseUrl/users/$username';
      debugPrint("Fetching user details from: $url");
      
      if (kIsWeb) {
        var client = http.Client();
        try {
          // Create request for web
          final request = http.Request('GET', Uri.parse(url));
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Accept'] = '*/*';
          
          // Send through stream for better control
          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);
          
          if (response.statusCode == 200) {
            final userData = jsonDecode(response.body);
            debugPrint("User data fetched: ${jsonDecode(response.body)}");
            _cachedUserData = userData;
            await _saveUserDataToStorage(userData);
            return userData;
          } else {
            throw Exception('Failed to fetch user details: ${response.statusCode}');
          }
        } finally {
          client.close();
        }
      } else {
        // Standard approach for mobile
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final userData = jsonDecode(response.body);
          debugPrint("User data fetched: ${jsonDecode(response.body)}");
          _cachedUserData = userData;
          await _saveUserDataToStorage(userData);
          return userData;
        } else {
          throw Exception('Failed to fetch user details: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
      throw Exception('Error fetching user details: $e');
    }
  }
  
  // Clear cached user data on logout
  Future<void> clearUserData() async {
    _cachedUserData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
  
  // Function to check if profile is incomplete
  bool isProfileIncomplete(Map<String, dynamic>? userData) {
    if (userData == null) return true;
    
    // Consider profile incomplete if any of these essential fields are missing or empty
    final essentialFields = [
      'first_name',
      'last_name',
      'phone_number',
      'street',
      'city',
      'province_state',
      'building',
    ];
    
    for (final field in essentialFields) {
      final value = userData[field];
      if (value == null || (value is String && value.isEmpty)) {
        return true;
      }
    }
    
    return false;
  }

  // Update user profile using the PUT endpoint with detailed logging
  Future<Map<String, dynamic>> updateUserProfile(
    String username,
    Map<String, dynamic> profileData
  ) async {
    try {
      if (username.isEmpty) {
        throw Exception('Username cannot be empty for profile update');
      }
      
      final token = await _getIDToken();
      if (token == null) throw Exception('No access token available');
      
      final url = '$_baseUrl/users/$username';
      debugPrint("Making PUT request to: $url");
      
      // Create a client that can handle CORS
      var client = http.Client();
      
      if (kIsWeb) {
        // For web, we need special handling for CORS
        debugPrint("Running in web environment, using enhanced CORS handling");
        
        try {
          // First create the request objects
          final request = http.Request('PUT', Uri.parse(url));
          
          // Add headers
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Content-Type'] = 'application/json';
          request.headers['Accept'] = '*/*';  // Be more permissive about response format
          
          // Add body
          request.body = jsonEncode(profileData);
          
          // Send the request through a stream to get more control
          final streamedResponse = await client.send(request);
          
          // Get the response
          final response = await http.Response.fromStream(streamedResponse);
          
          debugPrint("Response status: ${response.statusCode}");
          
          if (response.statusCode == 200) {
            final updatedData = jsonDecode(response.body);
            _cachedUserData = updatedData;
            await _saveUserDataToStorage(updatedData);
            return updatedData;
          } else {
            debugPrint("Error response: ${response.body}");
            throw Exception('Failed to update profile: ${response.statusCode} - ${response.reasonPhrase}');
          }
        } finally {
          client.close();
        }
      } else {
        // For mobile, use standard approach
        final response = await http.put(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(profileData),
        );
        
        if (response.statusCode == 200) {
          final updatedData = jsonDecode(response.body);
          _cachedUserData = updatedData;
          await _saveUserDataToStorage(updatedData);
          return updatedData;
        } else {
          throw Exception('Failed to update profile: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint("Error updating profile: $e");
      throw Exception('Error updating profile: $e');
    }
  }
  
  // Persistence methods
  Future<void> _saveUserDataToStorage(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(userData));
  }
  
  Future<Map<String, dynamic>?> _loadUserDataFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');
    if (userDataString == null) return null;
    
    try {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing stored user data: $e');
      return null;
    }
  }
  
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getIDToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }

  // Add this method to UserService
  Future<void> checkTokenValidity() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint("🔒 Token check: No token found in storage");
        return;
      }
      
      // Check token format
      debugPrint("🔒 Token check: Token length=${token.length}");
      
      if (token.contains('.')) {
        // Looks like a JWT, let's check its parts
        final parts = token.split('.');
        debugPrint("🔒 Token check: Has ${parts.length} parts (JWT should have 3)");
        
        // Try to decode the payload (middle part) to check expiration
        try {
          String normalizedPayload = base64Url.normalize(parts[1]);
          String decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
          final payloadJson = jsonDecode(decodedPayload);
          
          // Check for expiration
          if (payloadJson.containsKey('exp')) {
            final expTimestamp = payloadJson['exp'] as int;
            final expDate = DateTime.fromMillisecondsSinceEpoch(expTimestamp * 1000);
            final now = DateTime.now();
            
            debugPrint("🔒 Token check: Expires at $expDate");
            if (now.isAfter(expDate)) {
              debugPrint("⚠️ Token check: TOKEN IS EXPIRED!");
            } else {
              final remaining = expDate.difference(now);
              debugPrint("🔒 Token check: Token valid for ${remaining.inMinutes} more minutes");
            }
          }
        } catch (e) {
          debugPrint("🔒 Token check: Error decoding JWT: $e");
        }
      }
    } catch (e) {
      debugPrint("🔒 Token check error: $e");
    }
  }

  // Add this method to your UserService class
  Future<bool> deleteUserAccount(String username) async {
    try {
      // Get the access token for authorization
      final token = await _getIDToken();
      if (token == null) throw Exception('No access token available');
      
      final url = '$_baseUrl/users/$username';
      debugPrint('Deleting user account: $url');
      
      if (kIsWeb) {
        var client = http.Client();
        try {
          // Create request for web
          final request = http.Request('DELETE', Uri.parse(url));
          request.headers['Authorization'] = 'Bearer $token';
          request.headers['Content-Type'] = 'application/json';
          
          // Send the request
          final streamedResponse = await client.send(request);
          final response = await http.Response.fromStream(streamedResponse);
          
          debugPrint('Delete account response status: ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 204) {
            // Clear cached data
            await clearUserData();
            return true;
          } else {
            debugPrint('Error response: ${response.body}');
            throw Exception('Failed to delete account: ${response.statusCode}');
          }
        } finally {
          client.close();
        }
      } else {
        // Mobile implementation
        final response = await http.delete(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200 || response.statusCode == 204) {
          // Clear cached data
          await clearUserData();
          return true;
        } else {
          throw Exception('Failed to delete account: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('Error deleting account: $e');
    }
  }
}