class ApiConfig {
  // Base URL for the FastAPI backend
  // Change this based on your platform:
  // - Android Emulator: 'http://10.0.2.2:9000'
  // - iOS Simulator: 'http://localhost:9000'
  // - Physical Device: 'http://YOUR_COMPUTER_IP:9000'
  // - Production: 'https://your-domain.com'

  static const String baseUrl = 'http://localhost:9000';

  // Alternative: Use environment variables or build flavors
  // static const String baseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'http://localhost:9000',
  // );
}
