class EmailConfig {
  // EmailJS Configuration
  // To set up EmailJS:
  // 1. Go to https://www.emailjs.com/
  // 2. Create a free account
  // 3. Create an email service (Gmail, Outlook, etc.)
  // 4. Create an email template
  // 5. Get your Public Key, Service ID, and Template ID
  // 6. Replace the values below with your actual EmailJS credentials
  
  // EMAILJS CONFIGURATION - Your actual credentials
  static const String emailjsPublicKey = 'OM3_KO6jP5ZWzAd6H';
  static const String emailjsServiceId = 'service_tlq45us';
  static const String emailjsTemplateId = 'template_qvfmfpo';
  
  // Email template parameters
  static const String appName = 'Campus Food App';
  static const String fromName = 'Campus Food App Team';
  
  // Email subject and content
  static String getEmailSubject() => 'Verification Code - $appName';
  static String getEmailMessage(String otp) => 
    'Your verification code is: $otp\n\nThis code will expire in 10 minutes.\n\nIf you did not request this code, please ignore this email.\n\nBest regards,\n$fromName';
}
