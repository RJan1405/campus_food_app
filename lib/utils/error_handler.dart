import 'package:flutter/material.dart';

class ErrorHandler {
  // Display error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Log error to console and optionally to a service
  static void logError(String source, dynamic error, StackTrace? stackTrace) {
    print('ERROR in $source: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
    
    // TODO: Implement remote error logging service integration
    // e.g., Firebase Crashlytics, Sentry, etc.
  }

  // Handle common Firebase errors and return user-friendly messages
  static String getFirebaseErrorMessage(dynamic error) {
    String errorMessage = 'An unexpected error occurred';
    
    if (error.toString().contains('user-not-found')) {
      errorMessage = 'No user found with this email';
    } else if (error.toString().contains('wrong-password')) {
      errorMessage = 'Incorrect password';
    } else if (error.toString().contains('email-already-in-use')) {
      errorMessage = 'This email is already registered';
    } else if (error.toString().contains('weak-password')) {
      errorMessage = 'Password is too weak';
    } else if (error.toString().contains('network-request-failed')) {
      errorMessage = 'Network error. Please check your connection';
    } else if (error.toString().contains('too-many-requests')) {
      errorMessage = 'Too many attempts. Please try again later';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'Invalid email format';
    } else if (error.toString().contains('operation-not-allowed')) {
      errorMessage = 'Operation not allowed';
    }
    
    return errorMessage;
  }
}