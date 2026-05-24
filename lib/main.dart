import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'data/models/emergency_contact.dart';
import 'data/models/activity_log.dart';
import 'presentation/screens/sos_screen.dart';
import 'presentation/screens/compass_screen.dart';
import 'presentation/screens/contacts_screen.dart';
import 'presentation/screens/log_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait mode
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(EmergencyContactAdapter());
  Hive.registerAdapter(ActivityLogAdapter());
  await Hive.openBox<EmergencyContact>('contacts');
  await Hive.openBox<ActivityLog>('logs');

  // Seed default emergency numbers if they don't exist yet
  final contactsBox = Hive.box<EmergencyContact>('contacts');
  final defaultContacts = [
    EmergencyContact(id: 'def_112', name: 'National Emergency (all-in-one)', phone: '112', role: 'rescue', isPrimary: true),
    EmergencyContact(id: 'def_115', name: 'Search & Rescue (BASARNAS)', phone: '115', role: 'sar'),
    EmergencyContact(id: 'def_119', name: 'Ambulance', phone: '119', role: 'rescue'),
    EmergencyContact(id: 'def_113', name: 'Fire Department', phone: '113', role: 'rescue'),
    EmergencyContact(id: 'def_110', name: 'Police', phone: '110', role: 'rescue'),
  ];
  
  for (final contact in defaultContacts) {
    if (!contactsBox.values.any((c) => c.id == contact.id)) {
      await contactsBox.add(contact);
    }
  }

  // Keep screen on
  WakelockPlus.enable();

  runApp(const ProviderScope(child: SosApp()));
}

class SosApp extends StatelessWidget {
  const SosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S.O.S Panic Button',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final _tabs = const [
    (label: 'EMERGENCY',  icon: Icons.warning_amber_rounded,  screen: SosScreen()),
    (label: 'COMPASS',    icon: Icons.explore,                 screen: CompassScreen()),
    (label: 'CONTACTS',   icon: Icons.contacts,                screen: ContactsScreen()),
    (label: 'LOGS',       icon: Icons.history,                 screen: LogScreen()),
    (label: 'AI',         icon: Icons.psychology,              screen: _AiPlaceholder()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('⚠', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontFamily: 'monospace', fontSize: 18, letterSpacing: 3, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'S.'),
                  TextSpan(text: 'O', style: TextStyle(color: AppColors.red)),
                  TextSpan(text: '.S'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.green.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text('STANDBY', style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.green, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.red,
          unselectedItemColor: AppColors.textDim,
          selectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontFamily: 'monospace', fontSize: 9, letterSpacing: 1),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: _tabs.map((t) => BottomNavigationBarItem(
            icon: Icon(t.icon, size: 22),
            label: t.label,
          )).toList(),
        ),
      ),
    );
  }
}

// ── Placeholder screens ──


class _AiPlaceholder extends StatelessWidget {
  const _AiPlaceholder();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text('SIGMA AI Assistant\n(Gemini integration)', textAlign: TextAlign.center,
      style: TextStyle(fontFamily: 'monospace', color: AppColors.textDim, fontSize: 13)),
  );
}
