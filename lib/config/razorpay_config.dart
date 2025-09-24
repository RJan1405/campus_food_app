class RazorpayConfig {
  // Test keys - Replace with your actual Razorpay keys
  static const String testKeyId = 'rzp_test_1DP5mmOlF5G5ag';
  static const String liveKeyId = 'rzp_live_YOUR_LIVE_KEY_ID';
  
  // Use test key for development
  static const String keyId = testKeyId;
  
  // App configuration
  static const String appName = 'Campus Food App';
  static const String appDescription = 'Food Order Payment';
  static const String themeColor = '#673AB7'; // Deep purple
  
  // Default user info for prefill
  static const String defaultContact = '9876543210';
  static const String defaultEmail = 'student@campus.edu';
  
  // Payment options
  static const Map<String, dynamic> paymentOptions = {
    'key': keyId,
    'name': appName,
    'description': appDescription,
    'theme': {
      'color': themeColor,
    },
    'prefill': {
      'contact': defaultContact,
      'email': defaultEmail,
    },
    'retry': {
      'enabled': true,
      'max_count': 3,
    },
    'modal': {
      'ondismiss': true,
    },
  };
}
