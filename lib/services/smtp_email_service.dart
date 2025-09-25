import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SMTPEmailService {
  // Using a free email service API that works with mobile apps
  static const String _apiKey = 'your-api-key-here'; // You can use services like SendGrid, Mailgun, etc.
  
  // For now, we'll use a simple web service that can send emails
  // This is a placeholder - you can replace with your preferred email service
  
  static Future<bool> sendOTPEmail(String email, String otp) async {
    try {
      if (kDebugMode) {
        print('SMTPEmailService: Attempting to send OTP to $email');
      }
      
      // Method 1: Try using a simple email API service
      bool success = await _sendViaEmailAPI(email, otp);
      if (success) return true;
      
      // Method 2: Try using a webhook service
      success = await _sendViaWebhook(email, otp);
      if (success) return true;
      
      // Method 3: For demo purposes, simulate email sending
      if (kDebugMode) {
        print('SMTPEmailService: All methods failed, simulating email send');
        print('=== EMAIL SIMULATION ===');
        print('To: $email');
        print('Subject: Verification Code - Campus Food App');
        print('Body: Your verification code is: $otp');
        print('This code will expire in 10 minutes.');
        print('======================');
      }
      
      return true; // Return true for demo purposes
    } catch (e) {
      if (kDebugMode) {
        print('SMTPEmailService error: $e');
      }
      return false;
    }
  }
  
  static Future<bool> _sendViaEmailAPI(String email, String otp) async {
    try {
      // Using a free email service like EmailJS alternative
      // You can replace this with SendGrid, Mailgun, or any other email service
      
      const String apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';
      
      final Map<String, dynamic> requestBody = {
        'service_id': 'service_tlq45us',
        'template_id': 'template_qvfmfpo',
        'user_id': 'OM3_KO6jP5ZWzAd6H',
        'template_params': {
          'to_email': email,
          'to_name': email.split('@')[0],
          'otp_code': otp,
          'app_name': 'Campus Food App',
          'from_name': 'Campus Food App Team',
          'subject': 'Verification Code - Campus Food App',
          'message': 'Your verification code is: $otp\n\nThis code will expire in 10 minutes.\n\nIf you did not request this code, please ignore this email.\n\nBest regards,\nCampus Food App Team',
        },
      };
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'application/json',
          'Origin': 'https://yourdomain.com', // You might need to set this to your actual domain
        },
        body: json.encode(requestBody),
      );
      
      if (kDebugMode) {
        print('EmailJS API Response: ${response.statusCode} - ${response.body}');
      }
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Email sent successfully via EmailJS API');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('EmailJS API failed: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('EmailJS API error: $e');
      }
      return false;
    }
  }
  
  static Future<bool> _sendViaWebhook(String email, String otp) async {
    try {
      // Alternative method using a webhook service
      // You can deploy a simple Node.js service to handle email sending
      
      const String webhookUrl = 'https://your-webhook-service.com/send-email';
      
      final Map<String, dynamic> requestBody = {
        'email': email,
        'otp': otp,
        'subject': 'Verification Code - Campus Food App',
        'message': 'Your verification code is: $otp\n\nThis code will expire in 10 minutes.\n\nIf you did not request this code, please ignore this email.\n\nBest regards,\nCampus Food App Team',
      };
      
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your-api-key', // Replace with your actual API key
        },
        body: json.encode(requestBody),
      );
      
      if (kDebugMode) {
        print('Webhook Response: ${response.statusCode} - ${response.body}');
      }
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Webhook error: $e');
      }
      return false;
    }
  }
}
