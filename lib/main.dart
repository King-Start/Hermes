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

  // Initialize services
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: configManager),
        ChangeNotifierProvider.value(value: memoryStore),
        ChangeNotifierProvider.value(value: sessionManager),
        ChangeNotifierProvider.value(value: skillManager),
        ChangeNotifierProvider.value(value: toolRegistry),
        ChangeNotifierProvider(
          create: (_) => LLMService(
            baseUrl: configManager.config.baseUrl,
            apiKey: configManager.config.apiKey,
            model: configManager.config.model,
            temperature: configManager.config.temperature,
            maxTokens: configManager.config.maxTokens,
          ),
        ),
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'RobotoMono',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'RobotoMono',
      ),
      themeMode: ThemeMode.dark,
      home: const MainNavigation(),
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

  final _screens = const [
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
          setState(() {
            _selectedIndex = index;
          });
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
            icon: Icon(Icons.extension),
            selectedIcon: Icon(Icons.extension),
            label: 'Skills',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory),
            selectedIcon: Icon(Icons.memory),
            label: 'Memory',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}