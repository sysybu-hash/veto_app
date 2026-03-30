/// Application configuration
class AppConfig {
  /// Default tunnel host for API communication
  /// Use 192.168.1.101:3000 for mobile devices over WiFi
  /// Use localhost:3000 for desktop/development
  static const kDefaultTunnelHost = '192.168.1.101:3000';

  /// Base URL for all API requests
  static const String baseUrl = 'http://$kDefaultTunnelHost';

  /// API version
  static const String apiVersion = 'v1';

  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// Retry attempts for API calls
  static const int maxRetryAttempts = 3;
}
