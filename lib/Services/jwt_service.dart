import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jose/jose.dart';

class JwtService {
  static const String _jwksUrl = 'https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_1B9gRaY6l/.well-known/jwks.json';
  static JsonWebKeyStore? _keyStore;
  static DateTime? _lastKeysRefresh;

  // Cache the JWKS for 24 hours
  static const Duration _keyCacheDuration = Duration(hours: 24);

  // Fetch JWKS from Cognito
  static Future<void> _fetchJwks() async {
    final now = DateTime.now();

    // Use cached keys if still valid
    // Use Duration for clearer comparison
    if (_keyStore != null && _lastKeysRefresh != null &&
        now.difference(_lastKeysRefresh!) < _keyCacheDuration) {
      // print("Using cached JWKS"); // Optional: for debugging
      return;
    }

    // print("Fetching fresh JWKS"); // Optional: for debugging
    try {
      final response = await http.get(Uri.parse(_jwksUrl));

      if (response.statusCode == 200) {
        final jwksJson = jsonDecode(response.body);
        // Ensure 'keys' field exists and is a list
        if (jwksJson is Map<String, dynamic> && jwksJson['keys'] is List) {
           _keyStore = JsonWebKeyStore()..addKeySet(JsonWebKeySet.fromJson(jwksJson));
           _lastKeysRefresh = now;
        } else {
           throw Exception('Invalid JWKS format received');
        }
      } else {
        throw Exception('Failed to fetch JWKS: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      // Clear potentially stale keystore on failure
      _keyStore = null;
      _lastKeysRefresh = null;
      throw Exception('Failed to fetch or process JWKS: $e');
    }
  }

  // Verify JWT token
  static Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      // Ensure we have fresh JWKS
      await _fetchJwks();

      if (_keyStore == null) {
        // This might happen if the initial fetch failed and wasn't retried
        throw Exception('JWKS not available. Fetching failed previously.');
      }

      // Parse the JWT
      final jwt = JsonWebToken.unverified(token);

      // The jose library's verify method automatically uses the 'kid'
      // from the token header to find the appropriate key in the keyStore.
      // No need to manually extract 'kid'.
      final verified = await jwt.verify(_keyStore!);

      if (!verified) {
        // This handles signature verification failure OR if a matching key ('kid') wasn't found in the keyStore
        throw Exception('Invalid token signature or key not found');
      }

      // Check token expiration
      final claims = jwt.claims.toJson();
      final exp = claims['exp']; // 'exp' is typically number (seconds since epoch)

      if (exp != null) {
        if (exp is! num) {
           throw Exception('Invalid "exp" claim type: ${exp.runtimeType}');
        }
        // Ensure exp is treated as an integer for milliseconds calculation
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
        final nowUtc = DateTime.now().toUtc();

        // It's generally safer to compare UTC times
        if (nowUtc.isAfter(expiry)) {
          throw Exception('Token expired');
        }
      } else {
         // Depending on requirements, you might want to reject tokens without an expiration
         // throw Exception('Token does not have an "exp" claim');
      }

      // --- Optional: Add other standard validations ---
      // Check 'nbf' (Not Before)
      final nbf = claims['nbf'];
      if (nbf != null) {
         if (nbf is! num) {
           throw Exception('Invalid "nbf" claim type: ${nbf.runtimeType}');
         }
         final notBefore = DateTime.fromMillisecondsSinceEpoch(nbf.toInt() * 1000, isUtc: true);
         final nowUtc = DateTime.now().toUtc();
         // Add a small tolerance (e.g., 5 seconds) for clock skew
         if (nowUtc.isBefore(notBefore.subtract(const Duration(seconds: 5)))) {
            throw Exception('Token not yet valid (nbf)');
         }
      }

      // Check 'iat' (Issued At) - less common to validate strictly, but can check if it's in the future
      final iat = claims['iat'];
      if (iat != null) {
         if (iat is! num) {
           throw Exception('Invalid "iat" claim type: ${iat.runtimeType}');
         }
         final issuedAt = DateTime.fromMillisecondsSinceEpoch(iat.toInt() * 1000, isUtc: true);
         final nowUtc = DateTime.now().toUtc();
         // Add tolerance, e.g., 5 minutes into the future
         if (issuedAt.isAfter(nowUtc.add(const Duration(minutes: 5)))) {
            throw Exception('Token issued in the future (iat)');
         }
      }

      // Check 'aud' (Audience) - IMPORTANT if you expect a specific audience
      // final expectedAudience = 'your-client-id'; // Or your API identifier
      // final aud = claims['aud'];
      // if (aud == null) {
      //    throw Exception('Missing "aud" claim');
      // }
      // bool audienceMatch = false;
      // if (aud is String && aud == expectedAudience) {
      //    audienceMatch = true;
      // } else if (aud is List) {
      //    audienceMatch = aud.contains(expectedAudience);
      // }
      // if (!audienceMatch) {
      //    throw Exception('Invalid "aud" claim: $aud');
      // }

      // Check 'iss' (Issuer) - IMPORTANT to ensure the token came from the expected source
      // final expectedIssuer = 'https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_1B9gRaY6l'; // Must match your Cognito pool
      // final iss = claims['iss'];
      // if (iss == null || iss != expectedIssuer) {
      //    throw Exception('Invalid "iss" claim: $iss');
      // }

      // --- End Optional Validations ---


      return claims;
    } on JoseException catch (e) { // Catch specific jose errors if needed
      throw Exception('Token verification failed (JOSE): ${e.message}');
    } catch (e) { // Catch general exceptions
      throw Exception('Token verification failed: $e');
    }
  }
}