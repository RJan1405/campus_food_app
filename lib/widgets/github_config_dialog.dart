import 'package:flutter/material.dart';
import '../services/github_upload_service.dart';

class GitHubConfigDialog extends StatefulWidget {
  const GitHubConfigDialog({Key? key}) : super(key: key);

  @override
  State<GitHubConfigDialog> createState() => _GitHubConfigDialogState();
}

class _GitHubConfigDialogState extends State<GitHubConfigDialog> {
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownerController.text = 'your-github-username';
    _repoController.text = 'campus-food-images';
    _tokenController.text = 'your-github-token';
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _repoController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('GitHub Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure GitHub to automatically upload device images:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'GitHub Username',
                hintText: 'your-github-username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                hintText: 'campus-food-images',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Personal Access Token',
                hintText: 'ghp_xxxxxxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Setup Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Create a GitHub repository'),
                  const Text('2. Go to Settings > Developer settings'),
                  const Text('3. Generate Personal Access Token'),
                  const Text('4. Give "repo" permissions'),
                  const Text('5. Update the values above'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _showInstructions,
          child: const Text('Show Instructions'),
        ),
        ElevatedButton(
          onPressed: _saveConfiguration,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Setup Instructions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStep(
                '1',
                'Create Repository',
                'Create a new public repository on GitHub named "campus-food-images" (or any name you prefer)',
              ),
              _buildStep(
                '2',
                'Generate Token',
                'Go to GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)',
              ),
              _buildStep(
                '3',
                'Configure Token',
                'Click "Generate new token" and give it "repo" permissions',
              ),
              _buildStep(
                '4',
                'Copy Token',
                'Copy the generated token (starts with "ghp_") and paste it in the app',
              ),
              _buildStep(
                '5',
                'Update Code',
                'Update the values in lib/services/github_upload_service.dart with your details',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveConfiguration() {
    // This would typically save to a config file or shared preferences
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration saved! Update the code with these values.'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.of(context).pop();
  }
}
