/// Represents the token pair returned by login and refresh endpoints.
///
/// Maps to the backend `TokenResponse` record:
/// ```json
/// {
///   "accessToken": "...",
///   "refreshToken": "...",
///   "tokenType": "Bearer",
///   "accessExpiresIn": 9000
/// }
/// ```
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int accessExpiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.accessExpiresIn = 0,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      accessExpiresIn: (json['accessExpiresIn'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'accessExpiresIn': accessExpiresIn,
      };
}
