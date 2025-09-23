import 'package:flutter/material.dart';

class ImageUrlHelper extends StatelessWidget {
  const ImageUrlHelper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to Get Image URLs'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSection(
              'Google Drive',
              [
                '1. Upload your image to Google Drive',
                '2. Right-click on the image → "Get link"',
                '3. Change sharing to "Anyone with the link"',
                '4. Copy the link and paste it here',
                'Example: https://drive.google.com/file/d/1ABC123.../view'
              ],
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Imgur',
              [
                '1. Go to imgur.com',
                '2. Click "New Post" and upload your image',
                '3. Copy the direct image link',
                'Example: https://i.imgur.com/ABC123.jpg'
              ],
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Other Services',
              [
                '• Dropbox: Get shareable link',
                '• OneDrive: Get shareable link',
                '• Any image hosting service',
                '• Your own website/server'
              ],
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Working Image Platforms',
              [
                '• Imgur: imgur.com (Recommended)',
                '• PostImage: postimg.cc',
                '• ImageBB: imgbb.com',
                '• Cloudinary: cloudinary.com',
                '• Dropbox: dropbox.com',
                '• OneDrive: onedrive.live.com'
              ],
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Test Image URLs',
              [
                'Try these working URLs:',
                '• https://picsum.photos/300/200',
                '• https://via.placeholder.com/300x200',
                '• https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=300&h=200&fit=crop'
              ],
              Colors.blue,
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
    );
  }

  Widget _buildSection(String title, List<String> steps, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  step,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
        ],
      ),
    );
  }
}
