# AppaTube 📺

<p align="center">
  <img src="src/appa.png" width="120" height="120" alt="AppaTube Logo">
</p>

AppaTube is a high-performance, feature-rich YouTube client built with Flutter. It focuses on providing a seamless streaming experience with background playback capabilities, a modern Material 3 interface, and local data persistence.

![AppaTube Banner](https://img.shields.io/badge/Flutter-v3.0+-blue.svg?style=flat&logo=flutter)
![State Management](https://img.shields.io/badge/State-Riverpod-red.svg?style=flat)
![Storage](https://img.shields.io/badge/Storage-Hive-orange.svg?style=flat)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg?style=flat)

## ✨ Features

- 🔍 **Global Search**: Find any video or music on YouTube with ease.
- 🎧 **Background Playback**: Keep listening to your favorite content even when the app is minimized or the screen is off.
- 📱 **Miniplayer**: Continue watching while navigating through other parts of the app.
- 🕒 **History Tracking**: Automatically save your playback history locally.
- 🎨 **Material 3 Design**: A beautiful, premium dark theme optimized for OLED screens.
- ⚡ **Offline First**: Fast loading with cached thumbnails and local metadata storage.
- 🛠️ **Cross-Platform**: Designed to run smoothly on both Android and iOS.

## 📸 Screenshots

| | | | |
|:---:|:---:|:---:|:---:|
| <img src="screenshot/appa1.jpg" width="200"> | <img src="screenshot/appa2.jpg" width="200"> | <img src="screenshot/appa3.jpg" width="200"> | <img src="screenshot/appa4.jpg" width="200"> |
| <img src="screenshot/appa5.jpg" width="200"> | <img src="screenshot/appa6.jpg" width="200"> | <img src="screenshot/appa7.jpg" width="200"> | <img src="screenshot/appa8.jpg" width="200"> |

## 🚀 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/) with Code Generation
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio) & [audio_service](https://pub.dev/packages/audio_service)
- **YouTube API**: [youtube_explode_dart](https://pub.dev/packages/youtube_explode_dart)
- **Local Database**: [Hive](https://docs.hivedb.dev/)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Image Caching**: [cached_network_image](https://pub.dev/packages/cached_network_image)

## 📦 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mdkhanbahadursadi/AppaTube.git
   cd AppaTube
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate required files:**
   Since the project uses code generation for Riverpod and Hive:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🛠️ Configuration

### Android Cleartext Traffic
The app uses a local proxy for `just_audio`. Ensure the following is set in your `AndroidManifest.xml` (already configured in this repo):
- `android:networkSecurityConfig="@xml/network_security_config"`

## 📂 Project Structure

```text
lib/
├── app/                # App-wide configurations and routing
├── core/               # Constants, services, and utilities
├── data/               # Data models and repositories
├── presentation/       # UI screens, widgets, and providers
│   ├── providers/      # Riverpod state management
│   ├── screens/        # Individual app pages
│   └── widgets/        # Reusable UI components
└── main.dart           # Entry point
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Developed with ❤️ by [Your Name/Handle]
