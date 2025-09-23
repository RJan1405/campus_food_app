# GitHub Auto-Upload Setup Guide

This guide will help you set up automatic image uploads to GitHub for your Campus Food App.

## 🚀 Quick Setup

### Step 1: Create GitHub Repository
1. Go to [GitHub.com](https://github.com)
2. Click "New repository"
3. Name it `campus-food-images` (or any name you prefer)
4. Make it **Public**
5. Click "Create repository"

### Step 2: Generate Personal Access Token
1. Go to GitHub **Settings** (click your profile picture → Settings)
2. Scroll down to **Developer settings**
3. Click **Personal access tokens** → **Tokens (classic)**
4. Click **Generate new token** → **Generate new token (classic)**
5. Give it a name like "Campus Food App"
6. Select **repo** permissions (full control of private repositories)
7. Click **Generate token**
8. **Copy the token** (starts with `ghp_`) - you won't see it again!

### Step 3: Update Code Configuration
Open `lib/services/github_upload_service.dart` and update these values:

```dart
static const String _owner = 'YOUR_GITHUB_USERNAME'; // Replace with your GitHub username
static const String _repo = 'campus-food-images'; // Replace with your repository name
static const String _token = 'ghp_YOUR_TOKEN_HERE'; // Replace with your token
```

### Step 4: Test the Feature
1. Run your app
2. Go to Menu Management
3. Click "Add Menu Item"
4. Click "Upload from Device"
5. Select an image
6. The image will automatically upload to GitHub and get a URL!

## 🎯 How It Works

1. **User selects image** from device
2. **App automatically uploads** to your GitHub repository
3. **GitHub returns direct image URL**
4. **Image displays** in your app
5. **URL is saved** with menu item

## 📁 Repository Structure

Your GitHub repository will look like:
```
campus-food-images/
├── images/
│   ├── 1758668665794_pizza.jpg
│   ├── 1758668665795_burger.png
│   └── 1758668665796_pasta.jpg
└── README.md
```

## 🔒 Security Notes

- **Keep your token private** - never commit it to public repositories
- **Use environment variables** for production apps
- **Rotate tokens regularly** for security
- **Repository is public** - anyone can see the images

## 🛠️ Troubleshooting

### "Repository not found" error
- Check your GitHub username and repository name
- Make sure the repository exists and is public

### "Bad credentials" error
- Check your personal access token
- Make sure the token has "repo" permissions

### "Upload failed" error
- Check your internet connection
- Verify the token is valid
- Check GitHub API rate limits

## 🎉 Benefits

- ✅ **Free image hosting** (GitHub provides free storage)
- ✅ **Automatic URL generation**
- ✅ **No Firebase Storage needed**
- ✅ **Images accessible from anywhere**
- ✅ **Version control** for your images
- ✅ **Easy to manage** through GitHub interface

## 📱 Usage in App

Once configured:
1. Select image from device
2. App shows "Uploading to GitHub..."
3. Success message appears
4. Image URL is automatically filled
5. Image displays in preview
6. Save menu item with image!

---

**Need help?** Check the app's help dialog or contact support.
