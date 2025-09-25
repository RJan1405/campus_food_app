# EmailJS Template Setup Guide

## 🚨 **Current Issue: "The recipients address is empty"**

This error occurs because the EmailJS template is not properly configured to receive the email parameter.

## ✅ **Solution: Update Your EmailJS Template**

### **Step 1: Go to EmailJS Dashboard**
1. Visit: https://dashboard.emailjs.com/
2. Login to your account
3. Go to **Email Templates** section

### **Step 2: Edit Your Template (template_qvfmfpo)**

**Current Template Variables:**
Your template should include these variables:

```html
To: {{to_email}}
From: {{from_name}} <{{reply_to}}>
Subject: {{subject}}

Hello {{to_name}},

{{message}}

Your verification code is: {{otp_code}}

This code will expire in 10 minutes.

Best regards,
{{from_name}}
```

### **Step 3: Template Configuration**

**Required Template Variables:**
- `{{to_email}}` - Recipient email address
- `{{to_name}}` - Recipient name
- `{{otp_code}}` - 6-digit OTP code
- `{{app_name}}` - App name
- `{{from_name}}` - Sender name
- `{{subject}}` - Email subject
- `{{message}}` - Email message
- `{{reply_to}}` - Reply-to email

### **Step 4: Test Template**

**Test Data:**
```json
{
  "to_email": "test@example.com",
  "to_name": "Test User",
  "otp_code": "123456",
  "app_name": "Campus Food App",
  "from_name": "Campus Food App Team",
  "subject": "Verification Code - Campus Food App",
  "message": "Your verification code is: 123456",
  "reply_to": "test@example.com"
}
```

## 🔧 **Alternative: Use a Different Email Service**

If EmailJS continues to have issues, consider these alternatives:

### **Option 1: Firebase Functions + SendGrid**
```javascript
// Firebase Function
const functions = require('firebase-functions');
const sgMail = require('@sendgrid/mail');

sgMail.setApiKey('YOUR_SENDGRID_API_KEY');

exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email, otp } = data;
  
  const msg = {
    to: email,
    from: 'noreply@yourdomain.com',
    subject: 'Verification Code - Campus Food App',
    text: `Your verification code is: ${otp}`,
    html: `<p>Your verification code is: <strong>${otp}</strong></p>`,
  };
  
  try {
    await sgMail.send(msg);
    return { success: true };
  } catch (error) {
    console.error('SendGrid error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});
```

### **Option 2: Use Gmail SMTP**
```javascript
// Node.js with Nodemailer
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password', // Use App Password, not regular password
  },
});

const sendOTP = async (email, otp) => {
  const mailOptions = {
    from: 'your-email@gmail.com',
    to: email,
    subject: 'Verification Code - Campus Food App',
    text: `Your verification code is: ${otp}`,
  };
  
  try {
    await transporter.sendMail(mailOptions);
    return true;
  } catch (error) {
    console.error('Gmail SMTP error:', error);
    return false;
  }
};
```

## 🎯 **Quick Fix for Current Issue**

**Update your EmailJS template to include:**
```html
To: {{to_email}}
Subject: {{subject}}

Hello {{to_name}},

{{message}}

Your verification code is: {{otp_code}}

Best regards,
{{from_name}}
```

**Make sure the template has:**
1. `{{to_email}}` in the "To" field
2. All required variables properly mapped
3. Template is saved and published

## 📱 **Testing**

After updating the template:
1. Save the template in EmailJS dashboard
2. Test with the app again
3. Check the console logs for success/failure messages

## 🔍 **Debugging**

If still not working:
1. Check EmailJS dashboard for error logs
2. Verify template ID matches exactly
3. Test template with EmailJS dashboard test feature
4. Consider using the proxy service approach
