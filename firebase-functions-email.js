// Firebase Functions for Email Sending
// Deploy this to Firebase Functions as an alternative to EmailJS

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
admin.initializeApp();

// Gmail SMTP Configuration
const transporter = nodemailer.createTransporter({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com', // Replace with your Gmail
    pass: 'your-app-password', // Replace with Gmail App Password
  },
});

// Send OTP Email Function
exports.sendOTPEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp } = data;
    
    // Validate input
    if (!email || !otp) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and OTP are required'
      );
    }
    
    // Email content
    const mailOptions = {
      from: 'Campus Food App <your-email@gmail.com>',
      to: email,
      subject: 'Verification Code - Campus Food App',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Verification Code</h2>
          <p>Hello,</p>
          <p>Your verification code for Campus Food App is:</p>
          <div style="background-color: #f4f4f4; padding: 20px; text-align: center; margin: 20px 0;">
            <h1 style="color: #007bff; font-size: 32px; margin: 0;">${otp}</h1>
          </div>
          <p>This code will expire in 10 minutes.</p>
          <p>If you did not request this code, please ignore this email.</p>
          <hr style="margin: 20px 0;">
          <p style="color: #666; font-size: 12px;">
            Best regards,<br>
            Campus Food App Team
          </p>
        </div>
      `,
      text: `
        Verification Code - Campus Food App
        
        Hello,
        
        Your verification code is: ${otp}
        
        This code will expire in 10 minutes.
        
        If you did not request this code, please ignore this email.
        
        Best regards,
        Campus Food App Team
      `,
    };
    
    // Send email
    const result = await transporter.sendMail(mailOptions);
    
    console.log('Email sent successfully:', result.messageId);
    
    return {
      success: true,
      messageId: result.messageId,
    };
    
  } catch (error) {
    console.error('Error sending email:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send email: ' + error.message
    );
  }
});

// Alternative: SendGrid Integration
// Uncomment and configure if you prefer SendGrid over Gmail SMTP

/*
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey('YOUR_SENDGRID_API_KEY');

exports.sendOTPEmailSendGrid = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp } = data;
    
    const msg = {
      to: email,
      from: 'noreply@yourdomain.com', // Verified sender in SendGrid
      subject: 'Verification Code - Campus Food App',
      text: `Your verification code is: ${otp}`,
      html: `
        <div style="font-family: Arial, sans-serif;">
          <h2>Verification Code</h2>
          <p>Your verification code is: <strong>${otp}</strong></p>
          <p>This code will expire in 10 minutes.</p>
        </div>
      `,
    };
    
    await sgMail.send(msg);
    
    return { success: true };
    
  } catch (error) {
    console.error('SendGrid error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send email');
  }
});
*/
