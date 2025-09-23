// Example configuration for GitHub upload service
// Copy this to github_upload_service.dart and update with your values

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GitHubUploadService {
  // 🔧 UPDATE THESE VALUES WITH YOUR GITHUB DETAILS
  static const String _owner = 'your-github-username'; // 👈 Your GitHub username
  static const String _repo = 'campus-food-images'; // 👈 Your repository name
  static const String _token = 'ghp_your_token_here'; // 👈 Your personal access token
  static const String _branch = 'main';
  
  // Base URL for GitHub API
  static const String _baseUrl = 'https://api.github.com';
  
  /// Upload image to GitHub repository
  static Future<String?> uploadImage(File imageFile, String fileName) async {
    try {
      print('Starting GitHub upload for file: $fileName');
      
      // Read image file as bytes
      final bytes = await imageFile.readAsBytes();
      final base64Content = base64Encode(bytes);
      
      // Get file extension
      final extension = path.extension(fileName);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = '${timestamp}_${fileName.replaceAll(extension, '')}$extension';
      
      // GitHub API endpoint
      final url = '$_baseUrl/repos/$_owner/$_repo/contents/images/$finalFileName';
      
      // Prepare request body
      final body = {
        'message': 'Upload food image: $finalFileName',
        'content': base64Content,
        'branch': _branch,
      };
      
      // Make API request
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $_token',
          'Content-Type': 'application/json',
          'Accept': 'application/vnd.github.v3+json',
        },
        body: jsonEncode(body),
      );
      
      print('GitHub API response status: ${response.statusCode}');
      print('GitHub API response body: ${response.body}');
      
      if (response.statusCode == 201) {
        // Success - get the download URL
        final responseData = jsonDecode(response.body);
        final downloadUrl = responseData['content']['download_url'];
        print('Image uploaded successfully: $downloadUrl');
        return downloadUrl;
      } else {
        print('GitHub upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error uploading to GitHub: $e');
      return null;
    }
  }
  
  /// Get direct image URL from GitHub
  static String getImageUrl(String fileName) {
    return 'https://raw.githubusercontent.com/$_owner/$_repo/$_branch/images/$fileName';
  }
  
  /// Check if GitHub is configured
  static bool isConfigured() {
    return _owner != 'your-github-username' && 
           _repo != 'campus-food-images' && 
           _token != 'ghp_your_token_here';
  }
}

/*
SETUP INSTRUCTIONS:

1. Create a GitHub repository:
   - Go to github.com
   - Click "New repository"
   - Name it "campus-food-images" (or any name)
   - Make it PUBLIC
   - Click "Create repository"

2. Generate Personal Access Token:
   - Go to GitHub Settings → Developer settings
   - Click "Personal access tokens" → "Tokens (classic)"
   - Click "Generate new token"
   - Give it "repo" permissions
   - Copy the token (starts with "ghp_")

3. Update the values above:
   - Replace "your-github-username" with your GitHub username
   - Replace "campus-food-images" with your repository name
   - Replace "ghp_your_token_here" with your token

4. Test the feature:
   - Run your app
   - Go to Menu Management → Add Menu Item
   - Click "Upload from Device"
   - Select an image
   - It will automatically upload to GitHub!

Example:
static const String _owner = 'john_doe';
static const String _repo = 'my-food-images';
static const String _token = 'ghp_1234567890abcdef';
*/
