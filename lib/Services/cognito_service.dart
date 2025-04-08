import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'jwt_service.dart';

class CognitoService {
  static const String _cognitoUrl = 'https://cognito-idp.eu-west-1.amazonaws.com/';
  static const String _clientId = '2et6pcpoin606ul2evqm5lqb2g';
  
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

  // Method to check if user is logged in with valid token
  Future<bool> isAuthenticated() async {
    try {
      final token = await _getIdToken();
      if (token == null) return false;
      
      // Verify the token with JWKS
      await JwtService.verifyToken(token);
      return true;
    } catch (e) {
      print('Authentication verification failed: $e');
      return false;
    }
  }

  // Get user information from the token
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final token = await _getIdToken();
      if (token == null) return null;
      
      // Verify and decode the token
      return await JwtService.verifyToken(token);
    } catch (e) {
      print('Failed to get user info: $e');
      return null;
    }
  }

  // Method to logout
  Future<void> signOut() async {
    await _clearTokens();
  }

  // Token storage methods
  Future<void> _storeTokens({
    required String accessToken,
    required String idToken,
    required String refreshToken,
  }) async {
    // For now using shared_preferences, but should use secure storage in production
    final prefs = await SharedPreferences.getInstance();
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
}