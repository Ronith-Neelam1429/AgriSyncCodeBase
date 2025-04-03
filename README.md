# AgriSync

AgriSync is a Flutter-based mobile application focused on agricultural synchronization and management.

## Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio or VS Code with Flutter plugins
- Git
- Node.js and npm (for function dependencies)
- A suitable IDE (VS Code or Android Studio recommended)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/agrisync.git
cd agrisync
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Set up function dependencies:
```bash
cd functions
npm install
cd ..
```

4. Create or update the environment variables file:
```bash
cp .env.example .env
```
Ensure you update the `.env` file with your Stripe API key and other necessary credentials.

5. Verify your installation:
```bash
flutter doctor
```

## Running the Application

To run the application in debug mode:
```bash
flutter run
```

For release mode:
```bash
flutter run --release
```

## Project Structure

```
agrisync/
├── lib/
│   ├── main.dart
│   ├── App Pages/
│   ├── Components/
│   ├── Authentication/
├── assets/
├── functions/
├── test/
├── .env.example
└── pubspec.yaml
```

## Development Setup

1. Open the project in your preferred IDE
2. Ensure all dependencies are properly installed
3. Configure your emulator or connect a physical device
4. Start debugging with your IDE's Flutter tools

## Building for Production

To build the release version:

For Android:
```bash
flutter build apk --release
```

For iOS:
```bash
flutter build ios --release
```

## Resources for Flutter Development

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter First App Codelab](https://docs.flutter.dev/get-started/codelab)
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Dart Programming Language](https://dart.dev/)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

ronithneelam1429@gmail.com  
Project Link: [https://github.com/Ronith-Neelam1429/agrisync](https://github.com/Ronith-Neelam1429/agrisync)

