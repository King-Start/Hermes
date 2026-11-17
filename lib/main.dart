import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config.dart';
import 'services/llm_service.dart';
import 'services/memory_store.dart';
import 'services/session_manager.dart';
import 'services/skill_manager.dart';
import 'services/tool_registry.dart';
import 'screens/chat_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sessions_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/memory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load config first (sync via SharedPreferences)
  final configManager = ConfigManager();
  await configManager.load();

  final memoryStore = MemoryStore();
  await memoryStore.load();

  final sessionManager = SessionManager();
  await sessionManager.init();

  final skillManager = SkillManager();
  await skillManager.init();

  final toolRegistry = ToolRegistry();
  toolRegistry.registerAll(BuiltInTools.getAll());

  final llmService = LLMService(
    baseUrl: configManager.config.baseUrl,
    apiKey: configManager.config.apiKey,
    model: configManager.config.model,
    temperature: configManager.config.temperature,
    maxTokens: configManager.config.maxTokens,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configManager),
        ChangeNotifierProvider.value(value: memoryStore),
        ChangeNotifierProvider.value(value: sessionManager),
        ChangeNotifierProvider.value(value: skillManager),
        ChangeNotifierProvider.value(value: toolRegistry),
        ChangeNotifierProvider.value(value: llmService),
      ],
      child: const HermesApp(),
    ),
  );
}

class HermesApp extends StatelessWidget {
  const HermesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigManager>().config;

    return MaterialApp(
      title: 'Hermes',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light, config),
      darkTheme: _buildTheme(Brightness.dark, config),
      themeMode: ThemeMode.dark,
      home: const MainNavigation(),
    );
  }

  ThemeData _buildTheme(Brightness brightness, HermesConfig config) {
    final scheme = ColorScheme.fromSeed(
      seedColor: config.accentColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF1a1b26)
          : const Color(0xFFf7f7ff),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF16161e)
            : scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: brightness == Brightness.dark
            ? const Color(0xFF1f2335)
            : scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: scheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? const Color(0xFF282838)
            : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF16161e)
            : scheme.surface,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const _screens = [
    ChatScreen(),
    SessionsScreen(),
    SkillsScreen(),
    MemoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'Sessions',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'Memory',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}