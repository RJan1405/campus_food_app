# Campus Food App - Team Collaboration Setup

## 🎯 **Quick Start for New Team Members**

### **Prerequisites**
- Flutter SDK installed
- Android Studio / VS Code
- Git installed
- Firebase CLI installed

### **Step 1: Clone Repository**
```bash
git clone https://github.com/your-team/campus-food-app.git
cd campus-food-app
```

### **Step 2: Install Dependencies**
```bash
# Install Flutter dependencies
flutter pub get

# Install Firebase CLI (if not installed)
npm install -g firebase-tools
```

### **Step 3: Firebase Setup**
```bash
# Login to Firebase
firebase login

# Start emulators for local development
firebase emulators:start
```

### **Step 4: Run the App**
```bash
# In a new terminal
flutter run
```

---

## 🔥 **Firebase Project Access**

### **How to Get Access:**
1. **Ask project owner** to add your email to Firebase project
2. **Check your email** for Firebase invitation
3. **Accept invitation** and access Firebase Console
4. **Use Firebase Emulator Suite** for local development

### **Firebase Console Access:**
- Go to [Firebase Console](https://console.firebase.google.com)
- Select **"Campus Food App"** project
- You'll see all Firebase services (Auth, Firestore, Storage, etc.)

---

## 🛠️ **Development Workflow**

### **Daily Development:**
```bash
# 1. Pull latest changes
git pull origin main

# 2. Start emulators
firebase emulators:start

# 3. Run app
flutter run

# 4. Make changes and test

# 5. Commit changes
git add .
git commit -m "Add new feature"
git push origin main
```

### **Branch Strategy:**
- **`main`** - Production-ready code
- **`develop`** - Development branch
- **`feature/feature-name`** - Feature branches
- **`hotfix/bug-fix`** - Emergency fixes

---

## 📱 **App Features Overview**

### **Current Features:**
- ✅ **User Authentication** (Login/Signup)
- ✅ **Role-based Access** (Student/Vendor/Admin)
- ✅ **Menu Management** (Add/Edit/Delete items)
- ✅ **Image Upload** (GitHub integration)
- ✅ **Order Processing** (Place/View orders)
- ✅ **Payment Integration** (Razorpay)

### **Firebase Services Used:**
- **Authentication** - User login/signup
- **Firestore** - Database for users, menus, orders
- **Storage** - Image uploads (optional, GitHub preferred)
- **Functions** - Backend logic

---

## 🔧 **Development Environment**

### **Firebase Emulator Suite:**
- **Auth Emulator** - Port 9099
- **Firestore Emulator** - Port 8080
- **Storage Emulator** - Port 9199
- **UI Dashboard** - Port 4000

### **Local Development Benefits:**
- ✅ **Free** - No Firebase charges
- ✅ **Fast** - Local development
- ✅ **Offline** - Works without internet
- ✅ **Safe** - No production data affected

---

## 📁 **Project Structure**

```
campus-food-app/
├── 📱 lib/
│   ├── models/          # Data models
│   ├── services/        # Firebase services
│   ├── providers/       # State management
│   ├── screens/         # UI screens
│   └── widgets/         # Reusable widgets
├── 🔧 android/          # Android configuration
├── 🍎 ios/              # iOS configuration
├── 📋 pubspec.yaml      # Dependencies
├── 🔥 firebase.json     # Firebase configuration
└── 📖 README.md         # Documentation
```

---

## 🚨 **Important Notes**

### **Firebase Configuration:**
- **Don't commit** `google-services.json` to Git
- **Use environment variables** for sensitive data
- **Test with emulators** before production

### **Code Standards:**
- **Follow Flutter conventions**
- **Write clean, readable code**
- **Add comments** for complex logic
- **Test features** before committing

### **Team Communication:**
- **Use Git commit messages** to describe changes
- **Create issues** for bugs and features
- **Review code** before merging
- **Ask questions** in team chat

---

## 🆘 **Troubleshooting**

### **Common Issues:**

#### **"Firebase not initialized"**
```bash
# Solution: Check firebase_options.dart
flutter clean
flutter pub get
```

#### **"Emulator not starting"**
```bash
# Solution: Check Firebase CLI
firebase --version
firebase login
firebase emulators:start
```

#### **"Build errors"**
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### **"Git conflicts"**
```bash
# Solution: Resolve conflicts
git pull origin main
# Resolve conflicts in IDE
git add .
git commit -m "Resolve conflicts"
git push origin main
```

---

## 📞 **Getting Help**

### **Team Resources:**
- **GitHub Issues** - Bug reports and feature requests
- **Team Chat** - Quick questions and updates
- **Firebase Console** - Database and authentication management
- **Flutter Documentation** - [docs.flutter.dev](https://docs.flutter.dev)

### **Emergency Contacts:**
- **Project Owner** - [Your email]
- **Lead Developer** - [Lead email]
- **Firebase Support** - [Firebase Console Support]

---

## 🎉 **Welcome to the Team!**

You're now ready to contribute to the Campus Food App! 

**Next Steps:**
1. ✅ Set up development environment
2. ✅ Explore the codebase
3. ✅ Make your first contribution
4. ✅ Join team discussions

**Happy Coding! 🚀**
