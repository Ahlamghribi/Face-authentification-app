# 👤 Face Authentication App

A Flutter mobile application that enables users to authenticate and verify their identity using facial recognition technology. Powered by Firebase Authentication, image processing, and custom face recognition services, this app provides a secure and modern user login experience.

---

## 🚀 Features

- 📸 **Face Capture**: Register and update your face image using the camera or gallery.
- 🧠 **Face Recognition**: Verify your identity by comparing captured images to your registered face.
- 🔊 **Audio Feedback**: Hear a success or failure sound after each recognition attempt.
- 🔐 **Firebase Authentication**: Seamless user management with email/password login and sign-out.
- 💡 **Clean UI**: Built using Flutter's Material Design for a smooth user experience.

---

## 🛠️ Tech Stack

| Category      | Technologies Used                         |
|---------------|-------------------------------------------|
| Frontend      | Flutter, Dart                             |
| Backend       | Firebase Authentication, Firebase Storage |
| Face Auth     | Custom face recognition service           |
| Media Handling| image_picker, just_audio                  |

---

## 📲 Screenshots

| Home Screen | Face Update | Recognition Result |
|-------------|-------------|--------------------|
| ![Home](screenshots/home.png) | ![Update Face](screenshots/update.png) | ![Result](screenshots/result.png) |

> 💡 *Replace these with actual screenshots from your app.*

---

## 🧪 How It Works

1. **Sign In / Register** with Firebase Authentication.
2. Choose to **Update Face Image** — capture your face via camera or choose from gallery.
3. The app uploads and stores your face image securely.
4. Tap **Test Face Recognition** — the app compares the current image to the registered one.
5. **Result and Sound Feedback** indicate whether the verification passed or failed.

---

## 🧰 Getting Started

### Prerequisites

- Flutter SDK: [Install Flutter](https://flutter.dev/docs/get-started/install)
- Firebase Project: Enable **Authentication** and **Storage**
- Android/iOS device or emulator

### Setup Instructions

```bash
# Clone the repository
git clone https://github.com/Ahlamghribi/Face-authentification-app.git
cd Face-authentification-app

# Install dependencies
flutter pub get

# Run the app
flutter run
