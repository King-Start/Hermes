# Hermes Agent - Flutter/Android App

A mobile AI assistant inspired by Hermes Agent, built with Flutter for Android.

## Features

- **Chat Interface** - Clean, modern Material 3 UI
- **LLM Integration** - Works with any OpenAI-compatible API (OpenAI, Ollama, vLLM, etc.)
- **Persistent Memory** - User profile & agent notes stored locally
- **Session Management** - Save/load conversation history
- **Skill System** - Reusable capability modules
- **Tool System** - Extensible tools (file ops, terminal, web search)

## Quick Start

### Prerequisites

- Flutter SDK (3.3.0+)
- Android Studio
- Android device or emulator

### Installation

```bash
# Clone the repo
git clone <repo-url>
cd hermes-flutter

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## Configuration

1. Open the app
2. Go to **Settings** tab
3. Enter your LLM configuration:
   - **Base URL**: `https://api.openai.com/v1` (or your custom endpoint)
   - **API Key**: Your API key
   - **Model**: `gpt-4o-mini` (or any available model)
4. Save settings

### Using Local LLM (Ollama)

1. Install Ollama on your machine
2. Set Base URL to `http://<your-machine-ip>:11434/v1`
3. Use any installed model

## Project Structure

```
lib/
├── main.dart              # App entry point
├── core/
│   └── config.dart        # Configuration management
├── models/
│   └── chat.dart          # Chat message & session models
├── services/
│   ├── llm_service.dart    # LLM API client (streaming)
│   ├── memory_store.dart  # Persistent memory
│   ├── session_manager.dart # Conversation sessions
│   ├── skill_manager.dart # Skill system
│   └── tool_registry.dart # Tool system
├── screens/
│   ├── chat_screen.dart   # Main chat UI
│   ├── settings_screen.dart # Settings
│   ├── sessions_screen.dart # Session history
│   ├── skills_screen.dart  # Skills browser
│   └── memory_screen.dart  # Memory editor
└── widgets/
    └── common/            # Reusable widgets

android/
├── app/
│   ├── build.gradle      # App-level Gradle config
│   └── src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/.../MainActivity.kt
└── build.gradle          # Project-level Gradle config
```

## Screens

| Screen | Description |
|--------|-------------|
| **Chat** | Main conversation interface with streaming responses |
| **Sessions** | Browse and manage conversation history |
| **Skills** | View available skills and their documentation |
| **Memory** | Edit user profile and agent memory |
| **Settings** | Configure LLM endpoint, API key, and model |

## Building for Production

### Release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## Requirements

- Android 5.0+ (API 21+)
- Internet permission for LLM API access
- Storage permission for local data

## License

MIT