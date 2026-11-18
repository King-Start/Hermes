# Hermes Agent - Flutter Android App

AI assistant for Android, inspired by Hermes Agent.

## Features
- Agent loop with tools: run_shell, read_file, write_file, fetch_url, memory, skills
- Terminal screen (shell Android, tanpa Termux)
- Chat with streaming LLM responses (when tools are off)
- OpenAI-compatible API (OpenAI, Ollama, vLLM, LM Studio)
- Persistent memory (user profile + agent notes)
- Session management (save/load conversations)
- Skill system (reusable capabilities)
- Dark theme (Material 3)

## Setup

```bash
# Install Flutter SDK 3.3.0+
# Connect Android device or start emulator

flutter pub get
flutter run
```

## Build lewat GitHub Actions

Push ke branch `main`, lalu buka tab **Actions** > **Build APK**. APK ada di *Artifacts* (`hermes-apk`).

## Build APK (lokal)

```bash
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

## Configuration

1. Open app → Settings
2. Enter:
   - Base URL: `https://api.openai.com/v1`
   - API Key: your key
   - Model: `gpt-4o-mini`
3. Save

## Screens

| Tab | Function |
|-----|----------|
| Chat | Main conversation |
| Sessions | Browse history |
| Skills | View skill docs |
| Memory | Edit user/agent context |
| Settings | Configure LLM |

## Tech Stack

- Flutter 3.3.0+ / Dart
- Material 3 design
- Provider (state management)
- SharedPreferences (local storage)
- http (API calls)
- flutter_markdown (rendering)

## Project Structure

```
lib/
├── main.dart
├── core/config.dart
├── models/models.dart
├── services/
│   ├── llm_service.dart
│   ├── storage.dart (memory + sessions)
│   ├── skill_manager.dart
│   └── tool_registry.dart
└── screens/
    ├── chat_screen.dart
    ├── settings_screen.dart
    ├── sessions_screen.dart
    ├── skills_screen.dart
    └── memory_screen.dart
```

## License

MIT