# EmailJS Setup Guide for Campus Food App

This guide will help you set up EmailJS to send real OTP verification emails.

## Step 1: Create EmailJS Account

1. Go to [https://www.emailjs.com/](https://www.emailjs.com/)
2. Click "Sign Up" and create a free account
3. Verify your email address

## Step 2: Create Email Service

1. In your EmailJS dashboard, go to "Email Services"
2. Click "Add New Service"
3. Choose your email provider (Gmail, Outlook, Yahoo, etc.)
4. Follow the setup instructions for your chosen provider
5. Note down your **Service ID** (e.g., `service_abc123`)

## Step 3: Create Email Template

1. Go to "Email Templates" in your dashboard
2. Click "Create New Template"
3. Use this template content:

```
Subject: {{subject}}

Hello,

{{message}}

Best regards,
{{from_name}}
```

4. Save the template and note down your **Template ID** (e.g., `template_xyz789`)

## Step 4: Get Public Key

1. Go to "Account" in your dashboard
2. Find your **Public Key** (e.g., `user_abc123def456`)

## Step 5: Configure the App

1. Open `lib/config/email_config.dart` in your project
2. Replace the placeholder values with your actual EmailJS credentials:

```dart
class EmailConfig {
  static const String emailjsPublicKey = 'user_abc123def456'; // Your Public Key
  static const String emailjsServiceId = 'service_abc123';    // Your Service ID
  static const String emailjsTemplateId = 'template_xyz789';  // Your Template ID
  
  // ... rest of the configuration
}
```

## Step 6: Test Email Sending

1. Run the app: `flutter run`
2. Try signing up with a real email address
3. Check your email inbox for the OTP

## Troubleshooting

### Common Issues:

1. **"EmailJS not configured" error**
   - Make sure you've updated the credentials in `email_config.dart`
   - Ensure you're using the correct Service ID and Template ID

2. **Emails not received**
   - Check your spam/junk folder
   - Verify your email service is properly configured in EmailJS
   - Check EmailJS dashboard for any error logs

3. **Template parameters not working**
   - Make sure your template uses the correct parameter names:
     - `{{to_email}}`
     - `{{otp_code}}`
     - `{{app_name}}`
     - `{{from_name}}`
     - `{{subject}}`
     - `{{message}}`

### EmailJS Free Tier Limits:
- 200 emails per month
- 2 email services
- 2 email templates

For production use, consider upgrading to a paid plan.

## Alternative Email Services

If you prefer other email services:

1. **SendGrid**: More reliable, better for production
2. **AWS SES**: Scalable, cost-effective for high volume
3. **Firebase Functions**: Server-side email sending
4. **Nodemailer**: For custom email solutions

## Security Notes

- Never commit your EmailJS credentials to version control
- Consider using environment variables for production
- Monitor your email sending limits
- Implement rate limiting to prevent abuse
