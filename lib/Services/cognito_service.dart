import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'jwt_service.dart';
import 'user_service.dart';

class CognitoService {
  static const String _cognitoUrl = 'https://cognito-idp.eu-west-1.amazonaws.com/';
  static const String _clientId = '2et6pcpoin606ul2evqm5lqb2g';
  
  final UserService _userService = UserService();
  
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String password,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.SignUp',
        },
        body: jsonEncode({
          'ClientId': _clientId,
          'Username': username,
          'Password': password,
          'UserAttributes': [
            {
              'Name': 'email',
              'Value': email,
            },
            {
              'Name': 'phone_number',
              'Value': phoneNumber,
            }
          ],
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Sign up failed');
      }
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.ConfirmSignUp',
        },
        body: jsonEncode({
          'ClientId': _clientId,
          'Username': username,
          'ConfirmationCode': confirmationCode,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Verification failed');
      }
    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }

  Future<Map<String, dynamic>> resendConfirmationCode({
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.ResendConfirmationCode',
        },
        body: jsonEncode({
          'ClientId': _clientId,
          'Username': username,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to resend verification code');
      }
    } catch (e) {
      throw Exception('Failed to resend verification code: $e');
    }
  }

  Future<Map<String, dynamic>> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        },
        body: jsonEncode({
          'AuthFlow': 'USER_PASSWORD_AUTH',
          'ClientId': _clientId,
          'AuthParameters': {
            'USERNAME': username,
            'PASSWORD': password,
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Store auth tokens
        final authResult = responseData['AuthenticationResult'];
        if (authResult != null) {
          // Store tokens immediately and synchronously
          await _storeTokens(
            accessToken: authResult['AccessToken'],
            idToken: authResult['IdToken'],
            refreshToken: authResult['RefreshToken'],
          );
        }
        
        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Initiate forgot password flow
  Future<Map<String, dynamic>> forgotPassword({
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.ForgotPassword',
        },
        body: jsonEncode({
          'ClientId': _clientId,
          'Username': username,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to initiate password reset');
      }
    } catch (e) {
      throw Exception('Failed to initiate password reset: $e');
    }
  }

  // Complete the forgot password flow with confirmation code and new password
  Future<Map<String, dynamic>> confirmForgotPassword({
    required String username,
    required String confirmationCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_cognitoUrl),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.ConfirmForgotPassword',
        },
        body: jsonEncode({
          'ClientId': _clientId,
          'Username': username,
          'ConfirmationCode': confirmationCode,
          'Password': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to confirm password reset');
      }
    } catch (e) {
      throw Exception('Failed to confirm password reset: $e');
    }
  }

  // Simplified authentication check - just verify token exists
  Future<bool> isAuthenticated() async {
    try {
      // Check if token exists
      final prefs = await SharedPreferences.getInstance();
      final idToken = prefs.getString('id_token');
      final refreshToken = prefs.getString('refresh_token');
      
      // No tokens stored
      if (idToken == null || refreshToken == null) {
        return false;
      }
      
      // Check if token is expired by trying to decode it
      try {
        // Simple JWT structure check - not a full validation
        final parts = idToken.split('.');
        if (parts.length != 3) return false;
        
        // Parse the payload
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> json = jsonDecode(decoded);
        
        // Check expiration
        final exp = json['exp'];
        if (exp == null) return false;
        
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        final now = DateTime.now();
        
        // If token is not expired, user is authenticated
        if (expiry.isAfter(now)) {
          return true;
        }
        
        // Token is expired, try to refresh
        final refreshed = await _refreshToken(refreshToken);
        return refreshed;
      } catch (e) {
        debugPrint('Token validation error: $e');
        
        // Try to refresh token if parsing fails
        return await _refreshToken(refreshToken);
      }
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
  }

  Future<bool> _refreshToken(String refreshToken) async {
    try {
      // Implement token refresh using Cognito API
      final response = await http.post(
        Uri.parse('https://cognito-idp.eu-west-1.amazonaws.com/'),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
        },
        body: jsonEncode({
          'AuthFlow': 'REFRESH_TOKEN_AUTH',
          'ClientId': _clientId, // Use the class constant instead of 'YOUR_CLIENT_ID'
          'AuthParameters': {
            'REFRESH_TOKEN': refreshToken
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        final authResult = result['AuthenticationResult'];
        
        if (authResult != null) {
          // Save new tokens
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('id_token', authResult['IdToken']);
          await prefs.setString('access_token', authResult['AccessToken']);
          
          // Refresh token remains the same
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }

  // Get user information from the token
  Future<Map<String, dynamic>?> getUserInfo() async {
    final token = await _getIdToken();
    if (token == null) return null;
    
    try {
      return await JwtService.verifyToken(token);
    } catch (e) {
      return null;
    }
  }

  // Method to logout
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('id_token');
    await prefs.remove('refresh_token');
    await _userService.clearUserData();
  }

  // Token storage methods
  Future<void> _storeTokens({
    required String accessToken,
    required String idToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Use synchronous set operations and ensure they complete
    await prefs.setString('access_token', accessToken);
    await prefs.setString('id_token', idToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  Future<String?> _getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('id_token');
  }
  
  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('id_token');
    await prefs.remove('refresh_token');
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Get the current access token (not ID token)
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available');
      }

      debugPrint('Changing password with token: ${accessToken.substring(0, 10)}...');

      // Prepare the request
      final response = await http.post(
        Uri.parse('https://cognito-idp.eu-west-1.amazonaws.com/'),
        headers: {
          'Content-Type': 'application/x-amz-json-1.1',
          'X-Amz-Target': 'AWSCognitoIdentityProviderService.ChangePassword',
        },
        body: jsonEncode({
          'AccessToken': accessToken,
          'PreviousPassword': currentPassword,
          'ProposedPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('Failed to change password: $e');
    }
  }
}