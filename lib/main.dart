import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:si2_p1_mobile/config/env.dart';
import 'package:si2_p1_mobile/firebase_options.dart';
import 'package:si2_p1_mobile/config/router/app_router.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';
import 'package:si2_p1_mobile/config/theme/theme_provider.dart';
import 'package:si2_p1_mobile/core/services/local_incident_repository.dart';
import 'package:si2_p1_mobile/core/services/notification_service.dart';
import 'package:si2_p1_mobile/core/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Env.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().init();

  // Inicializar Hive para almacenamiento offline
  await Hive.initFlutter();
  await LocalIncidentRepository.init();

  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerStatefulWidget {
  const MainApp({super.key});

  @override
  ConsumerState<MainApp> createState() => _MainAppState();
}

class _MainAppState extends ConsumerState<MainApp> {
  @override
  void initState() {
    super.initState();
    // Iniciar sincronización en background al arrancar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncServiceProvider).startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);
    return MaterialApp.router(
      title: 'Auxilio Mecanico',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
